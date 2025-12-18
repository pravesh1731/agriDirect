import 'package:flutter/material.dart';
import 'package:agri_direct/common/widgets/AppBar/appBar.dart';
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:agri_direct/features/home/Buyer/buyerChatDetailsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerChatPage extends StatelessWidget {
	const BuyerChatPage({super.key});

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			appBar: appBar(isDark: isDark),
			body: Padding(
				padding: const EdgeInsets.all(USizes.defaultSpace),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						// Header
						Text(
							'Messages',
							style: TextStyle(
								fontSize: 22,
								fontWeight: FontWeight.w700,
								color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
							),
						),
						const SizedBox(height: 4),
						Text(
							'Chat with farmers',
							style: TextStyle(fontSize: 12, color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight),
						),
						SizedBox(height: USizes.spaceBtwItems),
						// Secure banner
						Container(
							padding: const EdgeInsets.all(16),
							decoration: BoxDecoration(color: UColors.primary, borderRadius: BorderRadius.circular(12)),
							child: Row(children: const [Icon(Icons.forum_outlined, color: UColors.textWhite), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Secure Messaging', style: TextStyle(color: UColors.textWhite, fontWeight: FontWeight.w700)), SizedBox(height: 2), Text('All conversations are blockchain verified', style: TextStyle(color: UColors.textWhite70, fontSize: 12))]))]),
						),
						SizedBox(height: USizes.spaceBteSections),
						// Chat list (expanded)
						Expanded(
							child: Builder(builder: (ctx) {
								final uid = FirebaseAuth.instance.currentUser?.uid;
								if (uid == null) return const Center(child: Text('Please sign in to view messages.'));
								final stream = FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: uid).snapshots();
								return StreamBuilder<QuerySnapshot>(
									stream: stream,
									builder: (context, snap) {
										if (snap.hasError) {
											// fall back to loading chats from orders if the direct query fails
											return FutureBuilder<List<DocumentSnapshot>>(
												future: () async {
													try {
														final orders = await FirebaseFirestore.instance.collection('orders').where('buyerId', isEqualTo: uid).get();
														final chatIds = <String>{};
														for (final o in orders.docs) {
															final od = o.data() as Map<String, dynamic>;
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
														// return empty list on error
														return <DocumentSnapshot>[];
													}
												}(),
												builder: (context, fb) {
													if (fb.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
													final docs = fb.data ?? [];
													if (docs.isEmpty) return Center(child: Text('No conversations yet.'));
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
														itemBuilder: (context, i) {
															final d = docs[i].data() as Map<String, dynamic>;
															final chatId = docs[i].id;
															final farmerName = (d['farmerName'] ?? d['buyerName'] ?? '(unknown)').toString();
															final farmerPhone = (d['farmerPhone'] ?? '').toString();
															final lastMessage = (d['lastMessage'] ?? '').toString();
															final updatedAt = d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null;
															final timeStr = updatedAt != null ? updatedAt.toLocal().toString() : '';
															return _ChatItem(
																name: farmerName,
																preview: lastMessage,
																time: timeStr,
																unread: (d['unread'] ?? 0) is int ? (d['unread'] ?? 0) : 0,
																onTap: () {
																	Navigator.push(
																		context,
																		MaterialPageRoute(
																			builder: (_) => BuyerChatDetailsPage(farmerName: farmerName, online: true, farmerPhone: farmerPhone),
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
											// No real-time chats found — attempt fallback (same as above)
											return FutureBuilder<List<DocumentSnapshot>>(
												future: () async {
													try {
														final orders = await FirebaseFirestore.instance.collection('orders').where('buyerId', isEqualTo: uid).get();
														final chatIds = <String>{};
														for (final o in orders.docs) {
															final od = o.data() as Map<String, dynamic>;
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
													if (docs.isEmpty) return Center(child: Text('No conversations yet.'));
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
														itemBuilder: (context, i) {
															final d = docs[i].data() as Map<String, dynamic>;
															final chatId = docs[i].id;
															final farmerName = (d['farmerName'] ?? d['buyerName'] ?? '(unknown)').toString();
															final farmerPhone = (d['farmerPhone'] ?? '').toString();
															final lastMessage = (d['lastMessage'] ?? '').toString();
															final updatedAt = d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null;
															final timeStr = updatedAt != null ? updatedAt.toLocal().toString() : '';
															return _ChatItem(
																name: farmerName,
																preview: lastMessage,
																time: timeStr,
																unread: (d['unread'] ?? 0) is int ? (d['unread'] ?? 0) : 0,
																onTap: () {
																	Navigator.push(
																		context,
																		MaterialPageRoute(
																			builder: (_) => BuyerChatDetailsPage(farmerName: farmerName, online: true, farmerPhone: farmerPhone),
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
											itemBuilder: (context, i) {
												final d = docs[i].data() as Map<String, dynamic>;
												final chatId = docs[i].id;
												final farmerName = (d['farmerName'] ?? d['buyerName'] ?? '(unknown)').toString();
												final farmerPhone = (d['farmerPhone'] ?? '').toString();
												final lastMessage = (d['lastMessage'] ?? '').toString();
												final updatedAt = d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null;
												final timeStr = updatedAt != null ? updatedAt.toLocal().toString() : '';
												return _ChatItem(
													name: farmerName,
													preview: lastMessage,
													time: timeStr,
													unread: (d['unread'] ?? 0) is int ? (d['unread'] ?? 0) : 0,
													onTap: () {
														Navigator.push(
															context,
															MaterialPageRoute(
																builder: (_) => BuyerChatDetailsPage(farmerName: farmerName, online: true, farmerPhone: farmerPhone),
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
					],
				),
			),
		);
	}
}

class _ChatItem extends StatelessWidget {
  const _ChatItem({
    required this.name,
    required this.preview,
    required this.time,
    this.unread,
    this.onTap,
  });

  final String name;
  final String preview;
  final String time;
  final int? unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
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
            const _Avatar(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.circle, size: 10, color: UColors.success),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: const TextStyle(fontSize: 11, color: UColors.textSecondaryLight)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(preview, style: const TextStyle(fontSize: 13, color: UColors.textSecondaryLight), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  const Text('Farmer', style: TextStyle(fontSize: 11, color: UColors.textSecondaryLight)),
                ],
              ),
            ),
            if (unread != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: UColors.success, borderRadius: BorderRadius.circular(999)),
                child: Text('$unread', style: const TextStyle(color: UColors.textWhite, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
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

