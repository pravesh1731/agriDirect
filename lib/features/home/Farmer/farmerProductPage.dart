import 'package:agri_direct/common/widgets/AppBar/appBar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // for Clipboard
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../../utils/cloudinary.dart';
import 'dart:io';
import '../../../utils/constants/colors.dart';

class FarmerProductPage extends StatefulWidget {
  const FarmerProductPage({super.key});

  @override
  State<FarmerProductPage> createState() => _FarmerProductPageState();
}

class _FarmerProductPageState extends State<FarmerProductPage> {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  final _dio = Dio();

  // in-memory list will be populated from Firestore
  List<_Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      // Load products from top-level `products` collection for this farmer
      // NOTE: `where` + `orderBy` requires a composite index in Firestore. To avoid
      // forcing the developer to create an index during development, we fetch
      // the matching docs and sort client-side by createdAt (descending).
      final snap = await _fire.collection('products').where('farmerId', isEqualTo: _auth.currentUser!.uid).get();
      final docs = snap.docs;
      // Sort docs client-side by createdAt (desc). createdAt may be a Timestamp or DateTime.
      docs.sort((a, b) {
        final aa = a.data()['createdAt'];
        final bb = b.data()['createdAt'];
        int aval = 0;
        int bval = 0;
        if (aa is Timestamp) aval = aa.toDate().millisecondsSinceEpoch;
        else if (aa is DateTime) aval = aa.millisecondsSinceEpoch;
        if (bb is Timestamp) bval = bb.toDate().millisecondsSinceEpoch;
        else if (bb is DateTime) bval = bb.millisecondsSinceEpoch;
        return bval.compareTo(aval); // descending
      });

      _products = docs.map((d) {
        final data = d.data();
        return _Product(
          id: d.id,
          title: (data['title'] ?? '') as String,
          category: (data['category'] ?? 'General') as String,
          categoryColor: (data['categoryColor'] != null) ? _colorFromHex((data['categoryColor'] as String)) : UColors.success,
          price: (data['price'] ?? '') as String,
          priceUnit: (data['priceUnit'] ?? '') as String,
          stock: (data['stock'] ?? '') as String,
          imageUrl: (data['imageUrl'] ?? '') as String,
          publicId: (data['publicId'] ?? '') as String,
        );
      }).toList();
      // Debug: print loaded product ids to help verify doc paths and IDs
      // ignore: avoid_print
      print('DEBUG: loaded ${_products.length} products for uid=${_auth.currentUser!.uid} ids=${_products.map((p) => p.id).join(', ')}');
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        // Show a helpful dialog with the exact rules to paste into Firestore
        await _showPermissionDeniedDialog();
      } else if (e is FirebaseException && e.message != null && e.message!.contains('requires an index')) {
        // Special case: Firestore index not found
        _showSnack('Failed to load products: $e');
        _showIndexHelpDialog(e.message!);
      } else {
        _showSnack('Failed to load products: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? 'unknown';
    final attemptedPath = 'users/$uid/products';



    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firestore permission denied'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your app is not allowed to read/write the products collection. Update your Firestore security rules to allow the authenticated user access to their own documents. Copy-paste the rules below into the Firebase Console > Firestore > Rules.'),
              const SizedBox(height: 12),

              Text('Attempted path: $attemptedPath', style: const TextStyle(fontSize: 12)),
              Text('User UID: $uid', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showIndexHelpDialog(String message) async {
    final consoleLink = 'https://console.firebase.google.com/project/${FirebaseAuth.instance.app.options.projectId}/firestore/rules';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firestore Index Required'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This operation requires a Firestore index that is not yet created. You can create the index by following these steps:'),
              const SizedBox(height: 12),
              Text('1. Go to the Firebase Console:'),
              GestureDetector(
                onTap: () async {
                  // Open the console link using url_launcher (Uri)
                  final url = Uri.parse('https://console.firebase.google.com/');
                  try {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      _showSnack('Could not launch ${url.toString()}');
                    }
                  } catch (_) {
                    _showSnack('Could not launch ${url.toString()}');
                  }
                },
                child: Text(
                  'https://console.firebase.google.com/',
                  style: TextStyle(color: UColors.primary, decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 4),
              Text('2. Navigate to Firestore > Indexes.'),
              const SizedBox(height: 4),
              Text('3. Create the missing index as suggested by the error message.'),
              const SizedBox(height: 4),
              Text('4. Save and try again.'),
              const SizedBox(height: 12),
              Text('Error message: $message', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copy the console link to clipboard
              Clipboard.setData(ClipboardData(text: consoleLink));
              _showSnack('Copied console link to clipboard');
            },
            child: const Text('Copy Console Link'),
          ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  String _hexFromColor(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0')}';
  Color _colorFromHex(String hex) {
    try {
      final v = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(v);
    } catch (_) {
      return UColors.success;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openAddEditSheet({_Product? product, int? index}) async {
    final titleCtrl = TextEditingController(text: product?.title ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    final priceCtrl = TextEditingController(text: product?.price ?? '');
    final priceUnitCtrl = TextEditingController(text: product?.priceUnit ?? '/');
    final stockCtrl = TextEditingController(text: product?.stock ?? '');
    String? imageUrl = product?.imageUrl;
    XFile? pickedImage;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product == null ? 'Add Product' : 'Edit Product', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(onPressed: () => Navigator.of(ctx).pop(false), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  TextField(controller: categoryCtrl, decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'e.g. 100',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: priceUnitCtrl, decoration: InputDecoration(labelText: 'Unit (e.g. kg)', hintText: 'kg', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  TextField(controller: stockCtrl, decoration: InputDecoration(labelText: 'Stock (e.g. 300 kg left)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  // Image picker preview + buttons
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: UColors.gray),
                        child: Builder(
                          builder: (_) {
                            final img = imageUrl;
                            if (img != null && img.isNotEmpty) {
                              // if it's a remote URL
                              if (img.startsWith('http')) {
                                return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, fit: BoxFit.cover));
                              }
                              // local file path (picked image)
                              return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(img), fit: BoxFit.cover));
                            }
                            return const Icon(Icons.image_outlined, color: UColors.textSecondaryLight);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
                              if (p != null) {
                                pickedImage = p;
                                // temporary preview: use file path
                                imageUrl = p.path;
                                if (mounted) setState(() {});
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final p = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1200);
                              if (p != null) {
                                pickedImage = p;
                                imageUrl = p.path;
                                if (mounted) setState(() {});
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final category = categoryCtrl.text.trim();
                        final price = priceCtrl.text.trim();
                        final priceUnit = priceUnitCtrl.text.trim();
                        final stock = stockCtrl.text.trim();
                        if (title.isEmpty) {
                          _showSnack('Please enter product title');
                          return;
                        }
                        if (price.isEmpty) {
                          _showSnack('Please enter product price');
                          return;
                        }

                        // upload image if picked -> Cloudinary unsigned upload
                        String? finalImageUrl = imageUrl;
                        String? uploadedPublicId;
                        if (pickedImage != null) {
                          try {
                            final formData = FormData.fromMap({
                              'file': await MultipartFile.fromFile(pickedImage!.path, filename: pickedImage!.name),
                              'upload_preset': kCloudinaryUploadPreset,
                            });
                            final url = 'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/image/upload';
                            final res = await _dio.post(url, data: formData);
                            finalImageUrl = res.data['secure_url'] as String?;
                            uploadedPublicId = res.data['public_id'] as String?;
                          } catch (e) {
                            _showSnack('Image upload failed: $e');
                          }
                        }

                        // sanitize price: remove any non-digit or non-dot characters
                        final sanitizedPrice = price.replaceAll(RegExp(r"[^0-9.]"), '');
                        final Map<String, dynamic> data = {
                          'title': title,
                          'category': category.isNotEmpty ? category : 'General',
                          'categoryColor': _hexFromColor((category.toLowerCase().contains('fruit')) ? UColors.warning : UColors.success),
                          'price': sanitizedPrice,
                          'priceUnit': priceUnit.isNotEmpty ? priceUnit : '/',
                          'stock': stock.isNotEmpty ? stock : 'In stock',
                          'imageUrl': finalImageUrl ?? '',
                          'publicId': uploadedPublicId ?? (product?.publicId ?? ''),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };
                        // Only set createdAt for new documents. For updates, don't touch createdAt so ordering is stable.
                        if (product == null) {
                          data['createdAt'] = FieldValue.serverTimestamp();
                        }

                        final user = _auth.currentUser;
                        // Debug: show UID we're about to use for writing
                        final debugUid = user?.uid ?? 'null';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attempting to save product as UID: $debugUid')));
                        // Also log to console
                        // ignore: avoid_print
                        print('DEBUG: attempting product save as uid=$debugUid');
                        try {
                          if (user != null) {
                            final productsCol = _fire.collection('products');
                            if (product == null) {
                              // create top-level product doc and include farmerId
                              final topData = Map<String, dynamic>.from(data);
                              topData['farmerId'] = user.uid;
                              topData['createdAt'] = FieldValue.serverTimestamp();

                              // Denormalize farmer info into the product doc so buyers don't need to read users/{uid}
                              try {
                                final userDoc = await _fire.collection('users').doc(user.uid).get();
                                if (userDoc.exists) {
                                  final dynamic udata = userDoc.data();
                                  if (udata is Map) {
                                    topData['ownerName'] = (udata['displayName'] ?? udata['name'] ?? '').toString();
                                    topData['ownerLocation'] = (udata['location'] ?? '').toString();
                                  }
                                }
                              } catch (_) {
                                // ignore failures; denormalization is best-effort
                              }

                              // create new doc with generated id under products
                              await productsCol.add(topData);

                              // reload and notify
                              await _loadProducts();
                              _showSnack('Product added');
                            } else {
                              // update top-level products/{product.id}
                              final topUpdate = Map<String, dynamic>.from(data);
                              topUpdate['farmerId'] = user.uid;
                              topUpdate['updatedAt'] = FieldValue.serverTimestamp();
                              // Update denormalized owner fields as well (best-effort)
                              try {
                                final userDoc = await _fire.collection('users').doc(user.uid).get();
                                if (userDoc.exists) {
                                  final dynamic udata = userDoc.data();
                                  if (udata is Map) {
                                    topUpdate['ownerName'] = (udata['displayName'] ?? udata['name'] ?? '').toString();
                                    topUpdate['ownerLocation'] = (udata['location'] ?? '').toString();
                                  }
                                }
                              } catch (_) {}

                              await productsCol.doc(product.id).set(topUpdate, SetOptions(merge: true));

                              // refresh list and notify
                              await _loadProducts();
                              _showSnack('Product updated');
                            }
                          }
                        } catch (e) {
                          _showSnack('Failed to save product: $e');
                        }

                        Navigator.of(ctx).pop(true);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: UColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Save Product', style: TextStyle(color: UColors.textWhite, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      // already handled in sheet; state updated
    }
  }

  Future<void> _confirmDelete(int index) async {
    // Simple confirmation: Delete acts as the 'force' delete (skip remote image step)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return; // cancelled
    // Treat Delete as force-delete (bypass Cloudinary)
    final doForce = true;

    final prod = _products[index];
    final user = _auth.currentUser;
    if (user == null) {
      _showSnack('You must be signed in to delete products');
      return;
    }

    final docRef = _fire.collection('products').doc(prod.id);

    // show progress
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      // If force delete: skip remote image deletion
      if (doForce) {
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          _showSnack('Product not found on server');
          setState(() => _products.removeAt(index));
          return;
        }
        await docRef.delete();
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        setState(() => _products.removeAt(index));
        _showSnack('Product deleted');
        return;
      }


    } catch (err) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      // handle FirebaseException specifically
      if (err is FirebaseException) {
        if (err.code == 'permission-denied') {
          await _showPermissionDeniedDialog();
          return;
        }
        // ignore: avoid_print
        print('DEBUG: firestore error during delete: ${err.message}');
        _showSnack('Failed to delete product: ${err.message}');
        return;
      }
      // generic
      // ignore: avoid_print
      print('DEBUG: unexpected error during delete: $err');
      _showSnack('Failed to delete product: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: UColors.backgroundLight,
      appBar: appBar(isDark: isDark),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, left: 24, right: 24, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              const Text(
                'My Products',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: UColors.textPrimaryLight,
                ),
              ),

              const Text(
                'Manage your listings',
                style: TextStyle(
                  fontSize: 14,
                  color: UColors.textSecondaryLight,
                ),
              ),
              SizedBox(height: 16),

              // Add Product Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openAddEditSheet(),
                  icon: const Icon(Icons.add, color: UColors.textWhite),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: UColors.textWhite,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Product List
              if (_loading)
                Center(child: CircularProgressIndicator())
              else if (_products.isEmpty)
                Center(child: Text('No products found. Tap "Add Product" to create your first listing.', textAlign: TextAlign.center, style: TextStyle(color: UColors.textSecondaryLight)))
              else
                for (var i = 0; i < _products.length; i++) ...[
                  _buildProductCardFromIndex(i),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCardFromIndex(int i) {
    final p = _products[i];
    // normalize unit (remove leading '/' or 'per ')
    final unitRaw = p.priceUnit.trim();
    String unitNormalized = '';
    if (unitRaw.startsWith('/')) {
      unitNormalized = unitRaw.substring(1).trim();
    } else if (unitRaw.toLowerCase().startsWith('per ')) {
      unitNormalized = unitRaw.substring(4).trim();
    } else {
      unitNormalized = unitRaw;
    }
    // build stock display: prefer extracting numeric value and append unit without space
    final rawStock = p.stock.trim();
    String displayStock;
    // try to extract first numeric token from stock (e.g., '300 kg left' -> '300')
    final numMatch = RegExp(r'[-+]?\d*\.?\d+').firstMatch(rawStock);
    if (numMatch != null) {
      final numberPart = numMatch.group(0)!.trim();
      if (unitNormalized.isNotEmpty) {
        displayStock = 'Stock:$numberPart$unitNormalized';
      } else {
        displayStock = 'Stock:$numberPart';
      }
    } else {
      // if no numeric part, fallback to showing raw stock (no extra space) and append unit if meaningful
      if (rawStock.isEmpty) {
        displayStock = 'Stock: -';
      } else if (unitNormalized.isNotEmpty && !rawStock.toLowerCase().contains(unitNormalized.toLowerCase())) {
        displayStock = 'Stock:${rawStock}$unitNormalized';
      } else {
        displayStock = 'Stock:${rawStock.replaceAll(' ', '')}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: UColors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: UColors.gray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.imageUrl != null && p.imageUrl!.isNotEmpty ? Image.network(p.imageUrl!, fit: BoxFit.cover) : const Icon(
                Icons.image_outlined,
                size: 32,
                color: UColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: UColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.categoryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.categoryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹ ${p.price}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      // display unit with leading '/' by default; handle old 'per ...' values
                      (() {
                        final u = p.priceUnit.trim();
                        if (u.isEmpty) return '';
                        if (u.startsWith('/')) return u;
                        if (u.toLowerCase().startsWith('per ')) return '/ ' + u.substring(4).trim();
                        return '/ ' + u;
                      })(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: UColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  displayStock,
                  style: const TextStyle(
                    fontSize: 12,
                    color: UColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Buttons
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: UColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: UColors.textSecondaryLight,
                  onPressed: () => _openAddEditSheet(product: p, index: i),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: UColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: UColors.textSecondaryLight,
                  onPressed: () => _confirmDelete(i),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Product {
  String? id;
  String title;
  String category;
  Color categoryColor;
  String price;
  String priceUnit;
  String stock;
  String? imageUrl;
  String? publicId;
  _Product({this.id, required this.title, required this.category, required this.categoryColor, required this.price, required this.priceUnit, required this.stock, this.imageUrl, this.publicId});
}
