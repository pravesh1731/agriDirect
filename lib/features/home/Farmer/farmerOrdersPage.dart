import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../common/widgets/AppBar/appBar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/simple_chat_page.dart';

class FarmerOrdersPage extends StatefulWidget {
  const FarmerOrdersPage({super.key});

  @override
  State<FarmerOrdersPage> createState() => _FarmerOrdersPageState();
}

class _FarmerOrdersPageState extends State<FarmerOrdersPage> {
  final _fire = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  // Fallback storage when primary query returns empty; prevents repeated fetch
  List<QueryDocumentSnapshot>? _fallbackOrders;
  bool _ranFallback = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(appBar: appBar(isDark: isDark), body: const Center(child: Text('Please sign in to view orders.')));
    }

    // Query orders that explicitly set farmerId to the current farmer UID.
    // We avoid server-side orderBy to prevent composite-index errors; results
    // will be sorted client-side by createdAt to show latest first.
    final stream = _fire.collection('orders').where('farmerId', isEqualTo: user.uid).snapshots();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar(isDark: isDark),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];

          // Debug: log snapshot size and farmer uid to help diagnose empty-result issues
          try {
            // ignore: avoid_print
            print('DEBUG: farmerOrders snapshot uid=${user.uid} docs=${docs.length}');
            if (docs.isNotEmpty) {
              // print first doc id and data keys for quick inspection
              // ignore: avoid_print
              print('DEBUG: first doc id=${docs.first.id} keys=${(docs.first.data() as Map<String,dynamic>).keys.toList()}');
            }
          } catch (_) {}

          // If primary query returned nothing, try a one-time fallback where the farmer id
          // may be stored under product.farmerId (older data/schema variance).
          if (docs.isEmpty && !_ranFallback) {
            _ranFallback = true;
            _fire.collection('orders').where('product.farmerId', isEqualTo: user.uid).get().then((qs) {
              if (qs.docs.isNotEmpty) {
                setState(() {
                  _fallbackOrders = qs.docs;
                });
              }
            }).catchError((e) {
              // ignore errors here; permissions/index issues will show in logs
              // ignore: avoid_print
              print('DEBUG: fallback query error: $e');
            });
          }

          // If fallback results exist, merge them with the realtime docs (dedupe by id)
          final combined = <String, QueryDocumentSnapshot>{};
          for (final d in docs) combined[d.id] = d;
          if (_fallbackOrders != null) {
            for (final d in _fallbackOrders!) combined[d.id] = d;
          }
          final mergedList = combined.values.toList();

          // Sort documents client-side by createdAt (desc) to show latest first
          final List<QueryDocumentSnapshot> sortedDocs = List<QueryDocumentSnapshot>.from(mergedList);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData['createdAt'];
            final bTs = bData['createdAt'];
            DateTime aDate = (aTs is Timestamp) ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            DateTime bDate = (bTs is Timestamp) ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(USizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Text(
                    'Orders',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 4),
                  Text('Track your sales and deliveries', style: TextStyle(fontSize: 14, color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight)),
                  const SizedBox(height: 8),


                  // simple stats (kept lightweight)
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(count: '${sortedDocs.where((d) => (d.data() as Map<String,dynamic>)['status'] == 'delivered').length}', label: 'Delivered', color: UColors.success)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(count: '${sortedDocs.where((d) => (d.data() as Map<String,dynamic>)['status'] == 'inTransit' || (d.data() as Map<String,dynamic>)['status'] == 'accepted').length}', label: 'In Progress', color: UColors.info)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(count: '${sortedDocs.where((d) => (d.data() as Map<String,dynamic>)['status'] == 'pending').length}', label: 'Pending', color: UColors.warning)),
                    ],
                  ),
                  SizedBox(height: USizes.spaceBteSections),

                  // dynamic order cards (or empty message)
                  if (sortedDocs.isEmpty) ...[
                    const SizedBox(height: 20),
                    Center(child: Text('No orders found for this farmer (uid: ${"${user.uid}"}).', style: TextStyle(color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight))),
                  ] else ...[
                    for (final d in sortedDocs) ...[
                      const SizedBox(height: 4),
                      _buildDynamicOrderCard(context, d.id, (d.data() as Map<String, dynamic>)),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicOrderCard(BuildContext context, String orderId, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = data['product'] as Map<String, dynamic>? ?? <String,dynamic>{};
    final productName = (product['title'] ?? product['name'] ?? data['productTitle'] ?? '(no title)').toString();
    final buyerName = (data['buyerName'] ?? '').toString();
    final buyerPhone = (data['buyerPhone'] ?? '').toString();
    final qty = (data['quantity']?.toString() ?? '-');
    final unit = (data['unit'] ?? product['priceUnit'] ?? '/').toString();
    final date = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null;
    final dateStr = date != null ? DateFormat.yMMMd().format(date) : '-';
    final price = product['price'] != null ? '₹${product['price']}' : '-';
    final status = (data['status'] ?? 'pending').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? UColors.cardDark : UColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: UColors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image: show remote image if available, otherwise a placeholder icon
              // Determine candidate image URLs from common keys
              Builder(builder: (ctx) {
                final prod = product;
                String? imgUrl;
                if (prod['image'] != null) imgUrl = prod['image'].toString();
                else if (prod['imageUrl'] != null) imgUrl = prod['imageUrl'].toString();
                else if (prod['images'] != null && prod['images'] is List && (prod['images'] as List).isNotEmpty) imgUrl = (prod['images'] as List).first.toString();
                else if (data['image'] != null) imgUrl = data['image'].toString();

                if (imgUrl != null && imgUrl.isNotEmpty) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: UColors.backgroundLight),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 28, color: UColors.textSecondaryLight),
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)));
                        },
                      ),
                    ),
                  );
                }

                return Container(width: 60, height: 60, decoration: BoxDecoration(color: UColors.gray, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_outlined, size: 28, color: UColors.textSecondaryLight));
              }),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // orderId intentionally hidden from UI; keep spacing using Expanded
                        const Expanded(child: SizedBox()),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: (status == 'accepted' ? UColors.info : (status == 'delivered' ? UColors.success : UColors.warning)).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status == 'accepted' ? UColors.info : (status == 'delivered' ? UColors.success : UColors.warning))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: UColors.textPrimaryLight)),
                    const SizedBox(height: 4),
                    Text(buyerName, style: const TextStyle(fontSize: 13, color: UColors.textSecondaryLight)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: UColors.backgroundLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.chat_bubble_outline, size: 20, color: UColors.textSecondaryLight)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [Text('$qty $unit', style: const TextStyle(fontSize: 13, color: UColors.textSecondaryLight)), const Text(' • ', style: TextStyle(fontSize: 13, color: UColors.textSecondaryLight)), Text(dateStr, style: const TextStyle(fontSize: 13, color: UColors.textSecondaryLight))]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // View details - keep placeholder
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('View Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: UColors.textPrimaryLight)),
                ),
              ),
              const SizedBox(width: 12),
              // Primary action: Accept (if pending) or Contact (if accepted/processing/etc.)
              Expanded(
                child: ElevatedButton(
                  onPressed: status == 'pending' || status == 'processing'
                      ? () async {
                          // Confirm before accepting
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Accept'),
                              content: const Text('Are you sure you want to accept this order? This will notify the buyer and open a chat.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Accept')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _acceptOrder(orderId, data);
                          }
                        }
                      : () {
                          // Open chat with buyer if already accepted/processing
                          final chatIdSafe = (data['chatId'] ?? '').toString();
                          final phoneSafe = (data['farmerPhone'] ?? data['buyerPhone'] ?? '').toString();
                          final nameSafe = (data['farmerName'] ?? data['buyerName'] ?? '').toString();
                          if (chatIdSafe.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SimpleChatPage(chatId: chatIdSafe, title: nameSafe, phone: phoneSafe),
                              ),
                            );
                          } else {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat not ready yet')));
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: UColors.primary, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(status == 'pending' || status == 'processing' ? 'Accept Order' : 'Contact Buyer', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: UColors.textWhite)),
                ),
              ),
              // Farmer actions based on status: Start Transit (accepted -> inTransit), Mark Delivered (inTransit -> delivered)
              if (status == 'accepted') ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Start Transit'),
                          content: const Text('Mark this order as in transit? This will notify the buyer and enable tracking.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Start')),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      try {
                        await _fire.collection('orders').doc(orderId).update({
                          'status': 'inTransit',
                          'inTransitAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked in transit.')));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark in transit: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: UColors.info, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Start Transit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: UColors.textWhite)),
                  ),
                ),
              ] else if (status == 'inTransit') ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Mark Delivered'),
                          content: const Text('Confirm marking this order as delivered?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      try {
                        await _fire.collection('orders').doc(orderId).update({
                          'status': 'delivered',
                          'deliveredAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked delivered.')));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark delivered: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: UColors.success, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Mark Delivered', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: UColors.textWhite)),
                  ),
                ),
              ] else if (status == 'delivered') ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Delivered', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: UColors.textSecondaryLight)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(String orderId, Map<String, dynamic> data) async {
    final farmerId = _auth.currentUser?.uid;
    if (farmerId == null) return;
    final buyerId = (data['buyerId'] ?? '').toString();
    if (buyerId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buyer id missing')));
      return;
    }

    try {

      final buyerName = (data['buyerName'] ?? '').toString();
      final buyerPhone = (data['buyerPhone'] ?? '').toString();
      final farmerName = (data['farmerName'] ?? '').toString();
      final farmerPhone = (data['farmerPhone'] ?? '').toString();

      // Create chat document first, then add the initial system message and update the order.
      final chatDoc = _fire.collection('chats').doc();
      final orderRef = _fire.collection('orders').doc(orderId);

      final participants = [buyerId, farmerId].where((s) => s.isNotEmpty).toList();
      await chatDoc.set({
        'orderId': orderId,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'participants': participants,
        'lastMessage': 'Order accepted — chat started',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // add initial message after chat doc exists (use farmerId as sender so security rules allow the write)
      final msgRef = chatDoc.collection('messages').doc();
      await msgRef.set({
        'senderId': farmerId,
        'text': 'Order accepted. You can now chat here regarding order $orderId.',
        'createdAt': FieldValue.serverTimestamp(),
        'system': true,
      });

      // then update order with chatId and accepted status
      await orderRef.update({'status': 'accepted', 'acceptedAt': FieldValue.serverTimestamp(), 'chatId': chatDoc.id});

      // debug logs
      // ignore: avoid_print
      print('DEBUG: chat created for orderId=$orderId chatId=${chatDoc.id}');

      final chatId = chatDoc.id;
      if (!mounted) return;
      // Show snackbar with Open Chat action so farmer can open chat even if immediate nav fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order accepted — chat created'),
          action: SnackBarAction(
            label: 'Open Chat',
            onPressed: () {
              // navigate to chat page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SimpleChatPage(chatId: chatId, title: buyerName, phone: buyerPhone)),
              );
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      // attempt immediate navigation as convenience; user can use the snackbar action if this fails
      try {
        // ignore: avoid_print
        print('DEBUG: attempting immediate navigation to chatId=$chatId');
        Navigator.push(context, MaterialPageRoute(builder: (_) => SimpleChatPage(chatId: chatId, title: buyerName, phone: buyerPhone)));
      } catch (navErr) {
        // ignore: avoid_print
        print('DEBUG: immediate navigation failed: $navErr');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept order: $e')));
    }
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ...existing _buildOrderCard kept for compatibility but not used for dynamic list...
  Widget _buildOrderCard({
    required String orderId,
    required String status,
    required Color statusColor,
    required String productName,
    required String customerName,
    required String quantity,
    required String date,
    required String price,
    required String image,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: UColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...existing UI kept unchanged ...
        ],
      ),
    );
  }
}
