import 'package:flutter/material.dart';
import 'package:agri_direct/common/widgets/AppBar/appBar.dart';
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:agri_direct/features/home/Buyer/buyerChatDetailsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BuyerOrdersPage extends StatefulWidget {
  const BuyerOrdersPage({super.key});

  @override
  State<BuyerOrdersPage> createState() => _BuyerOrdersPageState();
}

class _BuyerOrdersPageState extends State<BuyerOrdersPage> {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  // Keep track of orderIds we've already notified the user about being accepted
  final Set<String> _acceptedNotified = {};
  late SharedPreferences _prefs;
  bool _notifiedLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNotifiedSet();
  }

  Future<void> _loadNotifiedSet() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getStringList('accepted_notified') ?? <String>[];
    _acceptedNotified.addAll(saved);
    _notifiedLoaded = true;
    if (mounted) setState(() {});
  }

  Future<void> _saveNotifiedSet() async {
    await _prefs.setStringList('accepted_notified', _acceptedNotified.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: appBar(isDark: isDark),
        body: const Center(child: Text('Please sign in to view orders.')),
      );
    }

    // Avoid server-side composite index requirement by fetching buyer orders
    // and sorting client-side by createdAt (descending). For production it's
    // better to create the composite index in Firestore console.
    final stream = _fire.collection('orders').where('buyerId', isEqualTo: user.uid).snapshots();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar(isDark: isDark),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          // Sort documents client-side by createdAt (desc) to show latest first
          final List<QueryDocumentSnapshot> sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData['createdAt'];
            final bTs = bData['createdAt'];
            DateTime aDate = (aTs is Timestamp) ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            DateTime bDate = (bTs is Timestamp) ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          // Compute status counts for the summary row
          final deliveredCount = sortedDocs.where((d) {
            final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString();
            return s == 'delivered';
          }).length.toString();

          final inTransitCount = sortedDocs.where((d) {
            final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString();
            return s == 'inTransit';
          }).length.toString();

          final processingCount = sortedDocs.where((d) {
            final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString();
            return s == 'processing' || s == 'accepted';
          }).length.toString();

          // notify for newly accepted orders
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!_notifiedLoaded) return; // Skip notification logic until prefs are loaded
            for (final d in sortedDocs) {
              final data = d.data() as Map<String, dynamic>;
              final status = (data['status'] ?? '').toString();
              if (status == 'accepted' && !_acceptedNotified.contains(d.id)) {
                // create/ensure chat exists for this order so Open Chat opens correct thread
                try {
                  final farmerName = (data['farmerName'] ?? '').toString();
                  final farmerPhone = (data['farmerPhone'] ?? '').toString();
                  // Instead of creating/querying chats (which may be blocked by rules),
                  // read the chatId written on the order by the farmer when they accepted.
                  String? chatId;
                  try {
                    final orderSnap = await _fire.collection('orders').doc(d.id).get();
                    if (orderSnap.exists) {
                      final od = orderSnap.data();
                      chatId = od?['chatId']?.toString();
                    }
                  } catch (e) {
                    // ignore - we'll show a simple snackbar below
                  }

                  _acceptedNotified.add(d.id);
                  _saveNotifiedSet();

                  if (!mounted) return;
                  if (chatId != null && chatId.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order ${d.id} has been accepted by the farmer'),
                        action: SnackBarAction(
                          label: 'Open Chat',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BuyerChatDetailsPage(farmerName: farmerName, online: true, farmerPhone: farmerPhone),
                                settings: RouteSettings(arguments: {'chatId': chatId, 'orderId': d.id}),
                              ),
                            );
                          },
                        ),
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${d.id} accepted — chat not ready yet')));
                  }
                } catch (e) {
                  // if chat creation failed, still mark notified and show basic snack
                  _acceptedNotified.add(d.id);
                  _saveNotifiedSet();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${d.id} accepted — open chat failed: $e')));
                }
              }
            }
          });

          return ListView(
            padding: const EdgeInsets.all(USizes.defaultSpace),
            children: [
              Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your purchases',
                style: TextStyle(fontSize: 12, color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight),
              ),
              SizedBox(height: USizes.spaceBtwItems),

              // Status summary (computed)
              Row(
                children: [
                  Expanded(child: _StatusSummary(count: deliveredCount, label: 'Delivered', color: UColors.success)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatusSummary(count: inTransitCount, label: 'In Transit', color: UColors.info)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatusSummary(count: processingCount, label: 'Processing', color: UColors.warning)),
                ],
              ),
              SizedBox(height: USizes.spaceBteSections),

              // Orders list
              for (final d in sortedDocs) ...[
                Builder(builder: (ctx) {
                  final data = d.data() as Map<String, dynamic>;
                  final product = data['product'] as Map<String, dynamic>? ?? {};
                  final title = (product['title'] ?? data['productTitle'] ?? product['name'] ?? '').toString();
                  final farmerName = (data['farmerName'] ?? '').toString();
                  final qty = data['quantity']?.toString() ?? '-';
                  final unit = (data['unit'] ?? product['priceUnit'] ?? '/').toString();
                  final created = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null;
                  final meta = '$qty $unit${created != null ? ' · ${DateFormat.yMMMd().format(created)}' : ''}';
                  final statusStr = (data['status'] ?? 'pending').toString();
                  final price = product['price'] != null ? '₹${product['price']}' : '-';

                  OrderStatus mapStatus(OrderStatus defaultStatus) {
                    switch (statusStr) {
                      case 'delivered':
                        return OrderStatus.delivered;
                      case 'inTransit':
                        return OrderStatus.inTransit;
                      case 'processing':
                      case 'accepted':
                        return OrderStatus.processing;
                      default:
                        return defaultStatus;
                    }
                  }

                  // determine image url from common keys
                  String? imgUrl;
                  if (product['image'] != null) imgUrl = product['image'].toString();
                  else if (product['imageUrl'] != null) imgUrl = product['imageUrl'].toString();
                  else if (product['images'] != null && product['images'] is List && (product['images'] as List).isNotEmpty) imgUrl = (product['images'] as List).first.toString();
                  else if (data['image'] != null) imgUrl = data['image'].toString();

                  return _OrderCard(
                    orderId: d.id,
                    imageUrl: imgUrl,
                    name: title.isNotEmpty ? title : '(no title)',
                    seller: 'from ${farmerName.isNotEmpty ? farmerName : '-'}',
                    meta: meta,
                    status: mapStatus(OrderStatus.processing),
                    price: price,
                    // pass the farmer contact so Contact Farmer can open chat
                    onContact: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => BuyerChatDetailsPage(
                            farmerName: farmerName,
                            farmerPhone: (data['farmerPhone'] ?? '').toString(),
                            online: true,
                          ),
                        ),
                      );
                    },
                    // disable contact button unless accepted/processing/inTransit/delivered or exchangeCompleted
                    contactEnabled: ['accepted', 'processing', 'inTransit', 'delivered', 'exchangeCompleted'].contains(statusStr),
                    // Track is enabled when order is in transit or delivered or exchangeCompleted
                    trackEnabled: ['inTransit', 'delivered', 'exchangeCompleted'].contains(statusStr),
                    onTrack: () async {
                      // Behavior depends on current status
                      if (statusStr == 'inTransit') {
                        // Show simple tracking dialog (placeholder for map/tracking UI)
                        final inTransitAt = data['inTransitAt'];
                        String when = 'unknown';
                        if (inTransitAt is Timestamp) when = DateFormat.yMMMd().add_jm().format(inTransitAt.toDate());
                        await showDialog<void>(
                          context: ctx,
                          builder: (ctx2) => AlertDialog(
                            title: const Text('Tracking'),
                            content: Text('This order is currently in transit (since $when). You can contact the farmer for more details.'),
                            actions: [TextButton(onPressed: () => Navigator.of(ctx2).pop(), child: const Text('Close'))],
                          ),
                        );
                      } else if (statusStr == 'delivered') {
                        // Allow buyer to confirm completion
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (ctx2) => AlertDialog(
                            title: const Text('Confirm Delivery'),
                            content: const Text('The farmer has marked this order as delivered. Do you want to mark the order as completed?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx2).pop(false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.of(ctx2).pop(true), child: const Text('Complete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await _fire.collection('orders').doc(d.id).update({'status': 'completed', 'completedAt': FieldValue.serverTimestamp()});
                            if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Order marked completed.')));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to mark completed: $e')));
                          }
                        }
                      } else if (statusStr == 'exchangeCompleted') {
                        // Existing flow: buyer finalizes the order
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (ctx2) => AlertDialog(
                            title: const Text('Complete Order'),
                            content: const Text('Mark this order as completed?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx2).pop(false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.of(ctx2).pop(true), child: const Text('Confirm')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await _fire.collection('orders').doc(d.id).update({'status': 'completed', 'completedAt': FieldValue.serverTimestamp()});
                            if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Order marked completed.')));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to mark completed: $e')));
                          }
                        }
                      } else {
                        // fallback: show info
                        if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Cannot track order in status: $statusStr')));
                      }
                    },
                  );
                }),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

enum OrderStatus { delivered, inTransit, processing }

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({
    required this.count,
    required this.label,
    required this.color,
  });

  final String count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    this.imageUrl,
    required this.name,
    required this.seller,
    required this.meta,
    required this.status,
    required this.price,
    this.onContact,
    this.contactEnabled = true,
    this.trackEnabled = false,
    this.onTrack,
  });

  final String orderId;
  final String? imageUrl;
  final String name;
  final String seller;
  final String meta; // weight + date
  final OrderStatus status;
  final String price;
  final VoidCallback? onContact;
  final bool contactEnabled;
  final bool trackEnabled;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusMeta = _statusMeta(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? UColors.cardDark : UColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: UColors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image (remote URL preview) or placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: UColors.backgroundLight),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: UColors.textSecondaryLight), loadingBuilder: (c, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)));
                    })
                  : const Icon(Icons.image, color: UColors.textSecondaryLight),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: id + name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _StatusPill(color: statusMeta.color, text: statusMeta.label),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            seller,
                            style: const TextStyle(fontSize: 11, color: UColors.textSecondaryLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta,
                            style: const TextStyle(fontSize: 11, color: UColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),

                    // Right: price + indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusMeta.color.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: trackEnabled ? onTrack : null,
                      icon: const Icon(Icons.location_searching, size: 16),
                      label: const Text('Track'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                        side: BorderSide(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: contactEnabled
                            ? () {
                                // Open the chat with the specific farmer for this order
                                onContact?.call();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Contact Farmer', style: TextStyle(color: UColors.textWhite, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusMeta _statusMeta(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return const _StatusMeta(label: 'Delivered', color: UColors.success);
      case OrderStatus.inTransit:
        return const _StatusMeta(label: 'In Transit', color: UColors.info);
      case OrderStatus.processing:
        return const _StatusMeta(label: 'Processing', color: UColors.warning);
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.text});
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta({required this.label, required this.color});
}
