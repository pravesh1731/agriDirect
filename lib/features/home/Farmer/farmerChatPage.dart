import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common/widgets/AppBar/appBar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import 'farmerChatDetailPage.dart';

class FarmerChatPage extends StatelessWidget {
  const FarmerChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar(isDark: isDark),
      body: Column(
        children: [
          // Page Header
          Container(
            color: isDark ? UColors.cardDark : UColors.white,
            padding: const EdgeInsets.fromLTRB(USizes.defaultSpace, 0, USizes.defaultSpace, USizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chat with buyers',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                // Secure Messaging Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: UColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UColors.textWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: UColors.textWhite,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Messaging',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: UColors.textWhite,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'All conversations are blockchain verified',
                              style: TextStyle(
                                fontSize: 11,
                                color: UColors.textWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chat List (Firestore)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(USizes.defaultSpace),
              child: Builder(builder: (ctx) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return const Center(child: Text('Please sign in to view messages.'));
                final stream = FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: uid).snapshots();
                return StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      // fallback: load chats referenced from this farmer's orders
                      return FutureBuilder<List<DocumentSnapshot>>(
                        future: () async {
                          try {
                            final orders = await FirebaseFirestore.instance.collection('orders').where('farmerId', isEqualTo: uid).get();
                            final chatIds = <String>{};
                            for (final o in orders.docs) {
                              final od = o.data();
                              final cid = od['chatId']?.toString();
                              if (cid != null && cid.isNotEmpty) chatIds.add(cid);
                            }
                            final results = <DocumentSnapshot>[];
                            for (final cid in chatIds) {
                              try {
                                final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(cid).get();
                                if (chatDoc.exists) results.add(chatDoc);
                              } catch (_) {}
                            }
                            return results;
                          } catch (e) {
                            return <DocumentSnapshot>[];
                          }
                        }(),
                        builder: (context, fb) {
                          if (fb.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          final docs = fb.data ?? [];
                          if (docs.isEmpty) return const Center(child: Text('No conversations yet.'));
                          docs.sort((a, b) {
                            final aMap = a.data() as Map<String, dynamic>;
                            final bMap = b.data() as Map<String, dynamic>;
                            final aTs = aMap['updatedAt'];
                            final bTs = bMap['updatedAt'];
                            final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                            final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                            return bDate.compareTo(aDate);
                          });
                          return ListView.separated(
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemCount: docs.length,
                            itemBuilder: (context, idx) {
                              final d = docs[idx].data() as Map<String, dynamic>;
                              final chatId = docs[idx].id;
                              final buyerName = (d['buyerName'] ?? '(unknown)').toString();
                              final buyerPhone = (d['buyerPhone'] ?? '').toString();
                              final lastMessage = (d['lastMessage'] ?? '').toString();
                              final updatedAt = d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null;
                              final timeStr = updatedAt != null ? updatedAt.toLocal().toString() : '';
                              return _buildChatTile(
                                context: context,
                                name: buyerName,
                                message: lastMessage,
                                time: timeStr,
                                unreadCount: 0,
                                isOnline: true,
                                userType: 'Buyer',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailPage(userName: buyerName, userType: 'Buyer', isOnline: true, phone: buyerPhone),
                                      settings: RouteSettings(arguments: {'chatId': chatId, 'orderId': d['orderId'] ?? ''}),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    }
                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      // attempt same fallback if no realtime chats
                      return FutureBuilder<List<DocumentSnapshot>>(
                        future: () async {
                          try {
                            final orders = await FirebaseFirestore.instance.collection('orders').where('farmerId', isEqualTo: uid).get();
                            final chatIds = <String>{};
                            for (final o in orders.docs) {
                              final od = o.data();
                              final cid = od['chatId']?.toString();
                              if (cid != null && cid.isNotEmpty) chatIds.add(cid);
                            }
                            final results = <DocumentSnapshot>[];
                            for (final cid in chatIds) {
                              try {
                                final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(cid).get();
                                if (chatDoc.exists) results.add(chatDoc);
                              } catch (_) {}
                            }
                            return results;
                          } catch (e) {
                            return <DocumentSnapshot>[];
                          }
                        }(),
                        builder: (context, fb) {
                          if (fb.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          final docs = fb.data ?? [];
                          if (docs.isEmpty) return const Center(child: Text('No conversations yet.'));
                          docs.sort((a, b) {
                            final aMap = a.data() as Map<String, dynamic>;
                            final bMap = b.data() as Map<String, dynamic>;
                            final aTs = aMap['updatedAt'];
                            final bTs = bMap['updatedAt'];
                            final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                            final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                            return bDate.compareTo(aDate);
                          });
                          return ListView.separated(
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemCount: docs.length,
                            itemBuilder: (context, idx) {
                              final d = docs[idx].data() as Map<String, dynamic>;
                              final chatId = docs[idx].id;
                              final buyerName = (d['buyerName'] ?? '(unknown)').toString();
                              final buyerPhone = (d['buyerPhone'] ?? '').toString();
                              final lastMessage = (d['lastMessage'] ?? '').toString();
                              final updatedAt = d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null;
                              final timeStr = updatedAt != null ? updatedAt.toLocal().toString() : '';
                              return _buildChatTile(
                                context: context,
                                name: buyerName,
                                message: lastMessage,
                                time: timeStr,
                                unreadCount: 0,
                                isOnline: true,
                                userType: 'Buyer',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailPage(userName: buyerName, userType: 'Buyer', isOnline: true, phone: buyerPhone),
                                      settings: RouteSettings(arguments: {'chatId': chatId, 'orderId': d['orderId'] ?? ''}),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    }
                    // sort client-side by updatedAt
                    docs.sort((a, b) {
                      final aMap = a.data() as Map<String, dynamic>;
                      final bMap = b.data() as Map<String, dynamic>;
                      final aTs = aMap['updatedAt'];
                      final bTs = bMap['updatedAt'];
                      final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                      final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                      return bDate.compareTo(aDate);
                    });
                    return ListView.separated(
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final d = docs[idx].data() as Map<String, dynamic>;
                        final chatId = docs[idx].id;
                        final buyerName = (d['buyerName'] ?? '(unknown)').toString();
                        final buyerPhone = (d['buyerPhone'] ?? '').toString();
                        final lastMessage = (d['lastMessage'] ?? '').toString();
                        final updatedAt = d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null;
                        final timeStr = updatedAt != null ? updatedAt.toLocal().toString() : '';
                        return _buildChatTile(
                          context: context,
                          name: buyerName,
                          message: lastMessage,
                          time: timeStr,
                          unreadCount: 0,
                          isOnline: true,
                          userType: 'Buyer',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailPage(userName: buyerName, userType: 'Buyer', isOnline: true, phone: buyerPhone),
                                settings: RouteSettings(arguments: {'chatId': chatId, 'orderId': d['orderId'] ?? ''}),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ),
     ],
      ),
   );

 }

  Widget _buildChatTile({
    required BuildContext context,
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required bool isOnline,
    required String userType,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isDark ? UColors.cardDark : UColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: UColors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          // Avatar with online indicator
          Stack(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: UColors.gray, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person, color: UColors.textSecondaryLight, size: 28)),
            if (isOnline)
              Positioned(bottom: 2, right: 2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: UColors.success, shape: BoxShape.circle, border: Border.all(color: UColors.white, width: 2))))
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight))),
                if (isOnline) const Icon(Icons.circle, size: 8, color: UColors.success),
                const SizedBox(width: 8),
                Text(time, style: TextStyle(fontSize: 12, color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight)),
              ]),
              const SizedBox(height: 6),
              Text(message, style: TextStyle(fontSize: 14, color: unreadCount > 0 ? (isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight) : (isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight), fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(userType, style: TextStyle(fontSize: 12, color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight)),
            ]),
          ),
          if (unreadCount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: const BoxDecoration(color: UColors.primary, shape: BoxShape.circle), child: Text(unreadCount.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: UColors.textWhite))),
        ]),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 36});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: UColors.gray),
      child: const Icon(Icons.person, color: UColors.textSecondaryLight),
    );
  }
}
