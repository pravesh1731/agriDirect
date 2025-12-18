import 'package:cloud_firestore/cloud_firestore.dart';

/// Ensure a chat exists for a given order.
/// Behavior:
/// - First, read `orders/{orderId}` and return `chatId` if present.
/// - If no chatId exists and the caller (currentUid) equals the provided farmerId,
///   create a new chat document (with `participants`) and write `chatId` back to the order.
/// - Otherwise return null. This avoids performing `chats` collection queries with
///   `arrayContains` which can be blocked by security rules in some client contexts.
Future<String?> ensureChatForOrder({
  required FirebaseFirestore fire,
  required String currentUid,
  required String orderId,
  required String buyerId,
  required String buyerName,
  required String buyerPhone,
  required String farmerId,
  required String farmerName,
  required String farmerPhone,
}) async {
  // Read order doc for chatId
  final orderRef = fire.collection('orders').doc(orderId);
  final orderSnap = await orderRef.get();
  if (orderSnap.exists) {
    final ord = orderSnap.data() as Map<String, dynamic>?;
    final existing = ord?['chatId']?.toString();
    if (existing != null && existing.isNotEmpty) return existing;
  }

  // If no chat exists yet, only the farmer should create it here (to avoid buyer-side arrayContains queries)
  if (currentUid != farmerId) {
    return null;
  }

  // Create chat and initial system message and update order.chatId atomically
  final chatDoc = fire.collection('chats').doc();
  final participants = [buyerId, farmerId].where((s) => s.isNotEmpty).toList();

  final batch = fire.batch();
  batch.set(chatDoc, {
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

  final msgRef = chatDoc.collection('messages').doc();
  batch.set(msgRef, {
    'senderId': 'system',
    'text': 'Order accepted. You can now chat here regarding order $orderId.',
    'createdAt': FieldValue.serverTimestamp(),
    'system': true,
  });

  batch.update(orderRef, {'chatId': chatDoc.id});
  await batch.commit();
  return chatDoc.id;
}

Future<String?> getChatIdForOrder({required FirebaseFirestore fire, required String orderId}) async {
  final orderSnap = await fire.collection('orders').doc(orderId).get();
  if (!orderSnap.exists) return null;
  final ord = orderSnap.data() as Map<String, dynamic>?;
  final chatId = ord?['chatId']?.toString();
  if (chatId != null && chatId.isNotEmpty) return chatId;
  return null;
}

/// Return a Stream of the chat document for an order, if available.
/// This is safer than querying the `chats` collection by orderId because it
/// reads orders/{orderId}.chatId first and then listens to chats/{chatId}.
Future<Stream<DocumentSnapshot<Map<String, dynamic>>>?> watchChatDocStreamByOrder({
  required FirebaseFirestore fire,
  required String orderId,
}) async {
  try {
    final orderSnap = await fire.collection('orders').doc(orderId).get();
    if (!orderSnap.exists) return null;
    final ord = orderSnap.data() as Map<String, dynamic>?;
    final chatId = ord?['chatId']?.toString();
    if (chatId == null || chatId.isEmpty) return null;
    return fire.collection('chats').doc(chatId).snapshots().cast<DocumentSnapshot<Map<String, dynamic>>>();
  } catch (e) {
    return null;
  }
}
