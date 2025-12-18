import 'package:flutter/material.dart';
import 'package:agri_direct/common/widgets/AppBar/appBar.dart';
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:agri_direct/features/home/Buyer/buyerOrdersPage.dart';

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final TextEditingController _searchCtrl = TextEditingController();

  // Products loaded from Firestore. Each item is a map with additional metadata:
  // { 'docId': ..., 'ownerUid': ..., 'distanceKm': double?, ...originalFields }
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _loading = true;

  // cache to avoid fetching the same user doc multiple times
  final Map<String, String> _ownerNamesCache = {};
  // cache owner locations
  final Map<String, String> _ownerLocationsCache = {};

  // Buyer's coordinates
  double? _buyerLat;
  double? _buyerLng;

  final _fire = FirebaseFirestore.instance;

  // Pagination state
  final int _pageSize = 10;
  DocumentSnapshot? _lastProductDoc;
  bool _hasMore = true;
  bool _loadingMore = false;
  late final ScrollController _scrollController;

  // dialog controller used when adding to cart
  final TextEditingController _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadProductsFromFirestore(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // Show quantity dialog & place order
  Future<void> _onAddToCartPressed(Map<String, dynamic> product) async {
    // default quantity 1
    _qtyCtrl.text = '1';
    final rawUnit = (product['priceUnit'] ?? product['price_unit'] ?? product['unit'] ?? '/').toString();
    final unit = rawUnit.isEmpty ? '/' : rawUnit;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Place Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product['title']?.toString() ?? '(no title)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^[0-9]*\.?[0-9]*$"))],
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(unit, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final qText = _qtyCtrl.text.trim();
                if (qText.isEmpty) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a quantity')));
                  return;
                }
                final qty = double.tryParse(qText);
                if (qty == null || qty <= 0) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
                  return;
                }
                Navigator.of(ctx).pop();
                await _placeOrder(product, qty, unit);
              },
              child: const Text('Order'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeOrder(Map<String, dynamic> product, double quantity, String unit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be signed in to place an order')));
      return;
    }

    final buyerUid = user.uid;
    final farmerUid = (product['ownerUid'] ?? product['farmerId'])?.toString();
    if (farmerUid == null || farmerUid.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product owner information missing')));
      return;
    }

    try {
      // fetch minimal buyer profile
      String buyerName = user.displayName ?? '';
      String buyerPhone = '';
      try {
        final bu = await _fire.collection('users').doc(buyerUid).get();
        if (bu.exists) {
          final Map<String, dynamic>? bdata = bu.data() as Map<String, dynamic>?;
          if (bdata != null) {
            buyerName = (bdata['displayName'] ?? bdata['name'] ?? buyerName).toString();
            buyerPhone = (bdata['phone'] ?? '').toString();
          }
        }
      } catch (_) {}

      // fetch farmer minimal
      String farmerName = '';
      String farmerPhone = '';
      try {
        final fu = await _fire.collection('users').doc(farmerUid).get();
        if (fu.exists) {
          final Map<String, dynamic>? fdata = fu.data() as Map<String, dynamic>?;
          if (fdata != null) {
            farmerName = (fdata['displayName'] ?? fdata['name'] ?? '').toString();
            farmerPhone = (fdata['phone'] ?? '').toString();
          }
        }
      } catch (_) {}

      // Build a lightweight product snapshot to store inside the order
      final productSnapshot = <String, dynamic>{
        'productId': product['docId'] ?? product['id'] ?? '',
        'title': product['title'] ?? product['name'] ?? '',
        'price': product['price'] ?? 0,
        'priceUnit': product['priceUnit'] ?? product['price_unit'] ?? product['unit'] ?? '/',
        'imageUrl': product['imageUrl'] ?? product['image'] ?? '',
      };

      final orderMap = <String, dynamic>{
        'buyerId': buyerUid,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'productId': productSnapshot['productId'],
        'product': productSnapshot,
        'quantity': quantity,
        'unit': unit,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // DEBUG: log order payload and current auth uid to help diagnose permission issues
      try {
        // non-sensitive debug: prints buyerId/farmerId + keys
        // ignore: avoid_print
        print('DEBUG: placing order - currentUid=${user.uid} buyerId=${orderMap['buyerId']} farmerId=${orderMap['farmerId']} productId=${orderMap['productId']} payloadKeys=${orderMap.keys.toList()}');
      } catch (_) {}

      // Create top-level order
      final orderRef = await _fire.collection('orders').add(orderMap);
      final orderId = orderRef.id;
      // add orderId into the document so downstream UIs can read it
      await _fire.collection('orders').doc(orderId).update({'orderId': orderId}).catchError((_) {});
      // DEBUG: saved top-level order
      // ignore: avoid_print
      print('DEBUG: order created at orders/$orderId (top-level only)');

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully')));
      // navigate buyer to their orders page so they can track & get notified on acceptance
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuyerOrdersPage()),
        );
      }
    } on FirebaseException catch (e) {
      // permission denied etc
      if (e.code == 'permission-denied') {
        if (mounted) {
          await _showPermissionDeniedDialog('orders and buyer/farmer orders');
        }
        return;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: ${e.message}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
    }
  }

  Future<void> _loadProductsFromFirestore({bool loadMore = false, bool refresh = false}) async {
    // If refresh: reset pagination
    if (refresh) {
      _hasMore = true;
      _lastProductDoc = null;
      _allProducts = [];
      _filteredProducts = [];
    }

    if (loadMore) {
      if (!_hasMore || _loadingMore) return; // nothing to do
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }

    try {
      // Get buyer location (ask permission) only on initial load/refresh
      if (!loadMore) await _determinePosition();

      // Build query for a single page
      Query q = _fire.collection('products').orderBy('createdAt', descending: true).limit(_pageSize);
      if (_lastProductDoc != null) {
        q = q.startAfterDocument(_lastProductDoc!);
      }

      final prodSnap = await q.get();
      final docs = prodSnap.docs;

      // update pagination markers
      if (docs.isNotEmpty) {
        _lastProductDoc = docs.last;
      }
      if (docs.length < _pageSize) {
        _hasMore = false;
      }

      // Process this page: gather farmerIds and raw maps for this page
      final Set<String> farmerIds = {};
      final List<Map<String, dynamic>> pageRaw = [];
      for (final pd in docs) {
        final raw = pd.data();
        Map<String, dynamic> map;
        if (raw is Map<String, dynamic>) map = Map<String, dynamic>.from(raw);
        else if (raw is Map) map = Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)));
        else map = <String, dynamic>{};
        pageRaw.add({'doc': pd, 'data': map});
        final fid = (map['farmerId'] is String) ? map['farmerId'] as String : null;
        if (fid != null) farmerIds.add(fid);
      }

      // Prefetch user docs for farmerIds on this page
      final fetchFutures = <Future<void>>[];
      for (final fid in farmerIds) {
        if (_ownerNamesCache.containsKey(fid) && _ownerLocationsCache.containsKey(fid)) continue;
        fetchFutures.add(() async {
          try {
            final ud = await _fire.collection('users').doc(fid).get();
            if (ud.exists) {
              final dynamic udata = ud.data();
              if (udata is Map) {
                final display = (udata['displayName'] ?? udata['name'] ?? '').toString();
                final ownerLoc = (udata['location'] ?? '').toString();
                if (display.isNotEmpty) _ownerNamesCache[fid] = display;
                if (ownerLoc.isNotEmpty) _ownerLocationsCache[fid] = ownerLoc;
              }
            }
          } catch (err) {
            // ignore per-user fetch failures
            // ignore: avoid_print
            print('DEBUG: failed to prefetch user doc for fid=$fid error=$err');
          }
        }());
      }
      await Future.wait(fetchFutures);

      // Map page docs into product maps and attach owner info
      final pageProducts = <Map<String, dynamic>>[];
      for (final entry in pageRaw) {
        final pd = entry['doc'] as QueryDocumentSnapshot;
        final data = Map<String, dynamic>.from(entry['data'] as Map<String, dynamic>);
        data['docId'] = pd.id;
        final ownerUid = (data['farmerId'] is String) ? data['farmerId'] as String : null;
        if (ownerUid != null) data['ownerUid'] = ownerUid;

        double? lat;
        double? lng;
        if (data.containsKey('lat') && data.containsKey('lng')) {
          final maybeLat = data['lat'];
          final maybeLng = data['lng'];
          if (maybeLat is num && maybeLng is num) {
            lat = maybeLat.toDouble();
            lng = maybeLng.toDouble();
          }
        }
        if (lat == null && data.containsKey('location') && data['location'] is String && (data['location'] as String).isNotEmpty) {
          try {
            final places = await locationFromAddress(data['location'] as String);
            if (places.isNotEmpty) {
              lat = places.first.latitude;
              lng = places.first.longitude;
            }
          } catch (_) {}
        }
        data['lat'] = lat;
        data['lng'] = lng;
        double? distanceKm;
        if (_buyerLat != null && _buyerLng != null && lat != null && lng != null) {
          try {
            distanceKm = _distanceBetween(_buyerLat!, _buyerLng!, lat, lng);
          } catch (_) {
            distanceKm = null;
          }
        }
        data['distanceKm'] = distanceKm;

        if (ownerUid != null) {
          if (_ownerNamesCache.containsKey(ownerUid)) data['ownerName'] = _ownerNamesCache[ownerUid];
          if (_ownerLocationsCache.containsKey(ownerUid)) data['ownerLocation'] = _ownerLocationsCache[ownerUid];
        }
        if (data['ownerName'] == null || (data['ownerName'] as String).toString().trim().isEmpty) {
          final fallback = data['seller'] ?? data['displayName'] ?? data['name'] ?? data['farmerName'];
          if (fallback != null) data['ownerName'] = fallback.toString();
        }
        if (data['ownerLocation'] == null || (data['ownerLocation'] as String).toString().trim().isEmpty) {
          final locFallback = data['location'] ?? data['farmLocation'];
          if (locFallback != null) data['ownerLocation'] = locFallback.toString();
        }

        // try direct users read if still missing and allowed
        if ((data['ownerName'] == null || (data['ownerName'] as String).trim().isEmpty) && ownerUid != null) {
          try {
            final ud = await _fire.collection('users').doc(ownerUid).get();
            if (ud.exists) {
              final dynamic udata = ud.data();
              if (udata is Map) {
                final display = (udata['displayName'] ?? udata['name'] ?? '').toString();
                final ownerLoc = (udata['location'] ?? '').toString();
                if (display.isNotEmpty) data['ownerName'] = display;
                if (ownerLoc.isNotEmpty && (data['ownerLocation'] == null || (data['ownerLocation'] as String).trim().isEmpty)) data['ownerLocation'] = ownerLoc;
              }
            }
          } catch (_) {}
        }
        if (data['ownerName'] == null || (data['ownerName'] as String).toString().trim().isEmpty) data['ownerName'] = null;

        pageProducts.add(data);
      }

      // Append pageProducts to main list
      setState(() {
        _allProducts.addAll(pageProducts);
        _filteredProducts = List.from(_allProducts);
      });
    } catch (e) {
      // handle Firebase exceptions specifically and show more debug info
      if (e is FirebaseException) {
        // ignore: avoid_print
        print('DEBUG: FirebaseException during product load: code=${e.code} message=${e.message}');
        if (e.code == 'permission-denied') {
          await _showPermissionDeniedDialog('collectionGroup:products');
          return;
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase error: ${e.code} - ${e.message}')));
      } else {
        // show generic error
        // ignore: avoid_print
        print('DEBUG: failed to load products: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
      }
    } finally {
      if (mounted) {
        if (loadMore) _loadingMore = false;
        else _loading = false;
        setState(() {});
      }
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied')));
      return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    _buyerLat = pos.latitude;
    _buyerLng = pos.longitude;
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula in kilometers
    const p = 0.017453292519943295; // pi/180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }

  void _applyFilter(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredProducts = List.from(_allProducts));
      return;
    }

    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final category = (p['category'] ?? '').toString().toLowerCase();
        final seller = (p['seller'] ?? p['ownerName'] ?? '').toString().toLowerCase();
        final location = (p['location'] ?? '').toString().toLowerCase();
        return title.contains(query) || category.contains(query) || seller.contains(query) || location.contains(query);
      }).toList();
    });
  }

  void _onSearchPressed() {
    _applyFilter(_searchCtrl.text);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && !_loadingMore) {
      // Reached the bottom of the list
      _loadProductsFromFirestore(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar(isDark: isDark),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadProductsFromFirestore(refresh: true),
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: title on the left, All Products button on the right (flush)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Marketplace',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _filteredProducts = List.from(_allProducts));
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: UColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('All Products', style: TextStyle(color: UColors.textWhite)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fresh produce directly from farmers',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search products or farmers...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _onSearchPressed(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _onSearchPressed,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: UColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.search, size: 16, color: UColors.textWhite),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Product list as a builder for performance; includes optional bottom loader
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? Center(
                              child: Text(
                                'No products found.',
                                style: TextStyle(color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _filteredProducts.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (ctx, idx) {
                                if (idx < _filteredProducts.length) {
                                  final p = _filteredProducts[idx];
                                  return _buildProductCardFromMap(ctx, p);
                                }
                                // bottom loading indicator
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductCardFromMap(BuildContext context, Map<String, dynamic> p) {
    // If ownerName is missing but we have an ownerUid, try fetching that user's doc on-demand.
    // This is a best-effort, permission-guarded fetch that updates the product map and UI when complete.
    if ((p['ownerName'] == null || (p['ownerName'] as String).toString().trim().isEmpty) && p['ownerUid'] != null) {
      // Fire-and-forget; helper will call setState when it updates the map
      _fetchOwnerIfMissing(p['ownerUid'].toString(), p);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distance = p['distanceKm'] as double?;

    // Helper formatters
    String _normalizeUnit(String? raw) {
      final r = (raw ?? '').toString().trim();
      if (r.isEmpty) return '/';
      if (r.startsWith('/')) return r; // already includes '/'
      if (r.toLowerCase().startsWith('per ')) return '/' + r.substring(4).trim();
      return '/' + r;
    }

    String formatPrice(Map<String, dynamic> doc) {
      final priceVal = doc['price'];
      final rawUnit = (doc['priceUnit'] ?? doc['price_unit'] ?? '/').toString();
      final unit = _normalizeUnit(rawUnit);
      if (priceVal == null || priceVal.toString().trim().isEmpty) return '₹ - $unit';
      return '₹ ${priceVal.toString()} $unit';
    }

    String farmerName(Map<String, dynamic> doc) {
      // Prefer seller -> ownerName -> displayName -> name -> farmerName
      final candidate = doc['seller'] ?? doc['ownerName'] ?? doc['displayName'] ?? doc['name'] ?? doc['farmerName'];
      if (candidate == null) return '-';
      final s = candidate.toString().trim();
      return s.isNotEmpty ? s : '-';
    }

    String farmerLocation(Map<String, dynamic> doc) {
      // prefer ownerLocation (from user doc) then product location fields
      return (doc['ownerLocation'] ?? doc['location'] ?? doc['farmLocation'] ?? '-').toString();
    }

    final imageUrl = (p['imageUrl'] ?? p['image'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? UColors.cardDark : UColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: UColors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: UColors.gray.withAlpha(30),
              width: 72,
              height: 72,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported))
                  : const Icon(Icons.image, size: 36, color: UColors.textSecondaryLight),
            ),
          ),
          const SizedBox(width: 12),

          // Middle column: title, farmer name + location, stock
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['title']?.toString() ?? '(no title)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: UColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        farmerName(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: UColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        farmerLocation(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Stock display removed as requested.
                const SizedBox(height: 2),
              ],
            ),
          ),

          // Right column: price + buy button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPrice(p),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: UColors.success),
              ),
              if (distance != null) ...[
                const SizedBox(height: 6),
                Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11, color: UColors.textSecondaryLight)),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _onAddToCartPressed(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 18, color: UColors.textWhite),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fetch a single user's doc if ownerName is missing for a product. Results are cached.
  Future<void> _fetchOwnerIfMissing(String ownerUid, Map<String, dynamic> product) async {
    try {
      if (_ownerNamesCache.containsKey(ownerUid)) {
        product['ownerName'] = _ownerNamesCache[ownerUid];
        if (mounted) setState(() {});
        return;
      }

      final ud = await _fire.collection('users').doc(ownerUid).get();
      if (!ud.exists) return;
      final dynamic udata = ud.data();
      if (udata is Map<String, dynamic>) {
        final display = (udata['displayName'] ?? udata['name'] ?? '').toString();
        final ownerLoc = (udata['location'] ?? '').toString();
        if (display.isNotEmpty) {
          _ownerNamesCache[ownerUid] = display;
          product['ownerName'] = display;
        }
        if (ownerLoc.isNotEmpty) {
          _ownerLocationsCache[ownerUid] = ownerLoc;
          product['ownerLocation'] = ownerLoc;
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      // permission/network errors are expected in some setups; log for debugging
      // ignore: avoid_print
      print('DEBUG: _fetchOwnerIfMissing failed for $ownerUid: $e');
    }
  }

  Future<void> _showPermissionDeniedDialog(String attemptedPath) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'unknown';

    const rules = '''rules_version = '2';
 service cloud.firestore {
   match /databases/{database}/documents {
     // Allow the authenticated user to manage their own user doc and products
     match /users/{userId} {
       allow read, update: if request.auth != null && request.auth.uid == userId;
       match /products/{productId} {
         allow read, create, update, delete: if request.auth != null && request.auth.uid == userId;
       }
     }
+    // Allow authenticated users to create orders and read their own orders
+    match /orders/{orderId} {
+      allow create: if request.auth != null;
+      allow read: if request.auth != null && (request.auth.uid == resource.data.buyerId || request.auth.uid == resource.data.farmerId);
+    }
+    match /buyers/{buyerId}/orders/{orderId} {
+      allow read, write: if request.auth != null && request.auth.uid == buyerId;
+    }
+    match /farmers/{farmerId}/orders/{orderId} {
+      allow read, write: if request.auth != null && request.auth.uid == farmerId;
+    }
   }
 }
 ''';

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firestore permission denied'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your app attempted to read Firestore but was blocked by security rules. Update your Firestore rules to allow the authenticated user to read products or allow public read as needed.'),
              const SizedBox(height: 12),
              SelectableText('Attempted path: $attemptedPath', style: const TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 8),
              SelectableText('Current UID: $uid', style: const TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 12),
              const Text('Suggested rules to allow owner-only access (paste into Firebase Console → Firestore → Rules):'),
              const SizedBox(height: 8),
              SelectableText(rules, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showIndexRequiredDialog(String url, String query) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firestore Index Required'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This query requires a Firestore composite index, which is not yet created.'),
              const SizedBox(height: 12),
              Text('Query: $query', style: const TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 8),
              Text('To create the index, visit the following URL:', style: TextStyle(color: UColors.textSecondaryLight)),
              const SizedBox(height: 4),
              SelectableText(
                ' $url ',
                style: const TextStyle(fontFamily: 'monospace', color: UColors.primary),
              ),
              const SizedBox(height: 8),
              const Text('After creating the index, re-run the query.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}
