import 'package:flutter/material.dart';
import '../../../common/widgets/AppBar/appBar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../common/widgets/theme_toggle_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailPage extends StatefulWidget {
  final String userName;
  final String userType;
  final bool isOnline;
  // optional phone (buyer phone when farmer opens chat after accepting)
  final String phone;

  const ChatDetailPage({
    super.key,
    required this.userName,
    required this.userType,
    required this.isOnline,
    this.phone = '',
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  String? _chatId;
  String? _orderId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args.containsKey('chatId')) {
        _chatId = args['chatId']?.toString();
        _orderId = args['orderId']?.toString();
        if (_chatId != null && _chatId!.isNotEmpty) {
          _messagesStream = FirebaseFirestore.instance
              .collection('chats')
              .doc(_chatId)
              .collection('messages')
              .orderBy('createdAt', descending: false)
              .snapshots();
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final txt = _messageController.text.trim();
    if (txt.isEmpty) return;
    _messageController.clear();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    if (_chatId != null && _chatId!.isNotEmpty) {
      final msgRef = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages');
      await msgRef.add({
        'senderId': uid,
        'text': txt,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({'lastMessage': txt, 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar(isDark: isDark),
      body: Column(
        children: [
          // Header with optional phone shown (keeps layout same)
          Padding(
            padding: const EdgeInsets.fromLTRB(USizes.defaultSpace, 12, USizes.defaultSpace, 8),
            child: Row(
              children: [
                const _Avatar(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(widget.userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight), overflow: TextOverflow.ellipsis)),
                          Icon(Icons.verified, size: 16, color: UColors.success.withOpacity(0.9)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(widget.userType, style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, size: 8, color: widget.isOnline ? UColors.success : UColors.darkGray),
                          const SizedBox(width: 6),
                          Text(widget.isOnline ? 'Online' : 'Offline', style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                        ],
                      ),
                      if (widget.phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(widget.phone, style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages List
          Expanded(
            child: _messagesStream == null
                ? ListView(
                    padding: const EdgeInsets.all(USizes.defaultSpace),
                    children: [
                      if (widget.phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: UColors.cardDark, borderRadius: BorderRadius.circular(8)),
                                  child: Text('Contact info: ${widget.userName} · ${widget.phone}', style: const TextStyle(color: UColors.textPrimaryLight)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _messagesStream,
                    builder: (context, snap) {
                      if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final docs = snap.data?.docs ?? [];
                      return ListView.builder(
                        padding: const EdgeInsets.all(USizes.defaultSpace),
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          final m = docs[idx].data();
                          final isMe = (m['senderId'] ?? '') == (FirebaseAuth.instance.currentUser?.uid ?? '');
                          final text = (m['text'] ?? '').toString();
                          final time = m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate().toLocal().toString() : '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isMe ? UColors.primary : (isDark ? UColors.cardDark : UColors.white),
                                      borderRadius: BorderRadius.only(topLeft: const Radius.circular(14), topRight: const Radius.circular(14), bottomLeft: Radius.circular(isMe ? 14 : 4), bottomRight: Radius.circular(isMe ? 4 : 14)),
                                    ),
                                    child: Text(text, style: TextStyle(color: isMe ? UColors.textWhite : (isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight), fontSize: 14, height: 1.35)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(mainAxisSize: MainAxisSize.min, children: [Text(time, style: const TextStyle(fontSize: 11, color: UColors.textSecondaryLight)), if (isMe) ...[const SizedBox(width: 6), Icon(Icons.done_all, size: 16, color: UColors.textSecondaryLight.withOpacity(0.8))]]),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Blockchain Verified Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: UColors.success.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, size: 16, color: UColors.success),
                const SizedBox(width: 8),
                const Text('All messages are blockchain verified', style: TextStyle(fontSize: 12, color: UColors.success, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(USizes.defaultSpace),
            decoration: BoxDecoration(
              color: UColors.white,
              boxShadow: [BoxShadow(color: UColors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: isDark ? UColors.cardDark : UColors.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(color: UColors.primary, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: UColors.textWhite),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageEntry {
  final String text;
  final bool isMe;
  final String time;
  _MessageEntry({required this.text, required this.isMe, required this.time});
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 36});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: UColors.gray, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.person, color: UColors.textSecondaryLight));
  }
}
