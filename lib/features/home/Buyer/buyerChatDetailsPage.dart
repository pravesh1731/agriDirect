import 'package:flutter/material.dart';
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:agri_direct/common/widgets/AppBar/appBar.dart' as shared;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerChatDetailsPage extends StatefulWidget {
  const BuyerChatDetailsPage({super.key, required this.farmerName, this.online = true, this.farmerPhone = '', this.chatId});

  final String farmerName;
  final bool online;
  final String farmerPhone;
  final String? chatId; // optional pre-supplied chatId

  @override
  State<BuyerChatDetailsPage> createState() => _BuyerChatDetailsPageState();
}

class _BuyerChatDetailsPageState extends State<BuyerChatDetailsPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String? _chatId;
  String? _orderId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    // read chatId from route arguments if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prefer chatId supplied via constructor
      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        _chatId = widget.chatId;
        if (_chatId != null) {
          _messagesStream = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').orderBy('createdAt', descending: false).snapshots();
          setState(() {});
        }
        return;
      }
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args.containsKey('chatId')) {
        _chatId = args['chatId']?.toString();
        _orderId = args['orderId']?.toString();
        if (_chatId != null && _chatId!.isNotEmpty) {
          _messagesStream = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').orderBy('createdAt', descending: false).snapshots();
          setState(() {});
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;
    _controller.clear();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    if (_chatId != null && _chatId!.isNotEmpty) {
      final msgRef = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages');
      await msgRef.add({
        'senderId': uid,
        'text': txt,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // update chat lastMessage
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({'lastMessage': txt, 'updatedAt': FieldValue.serverTimestamp()});
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // also show contact as system message if phone provided (keeps previous UX)
    // (we don't persist it to Firestore here)
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: shared.appBar(isDark: isDark),
      body: Column(
        children: [
          // Conversation header
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
                          Expanded(
                            child: Text(
                              widget.farmerName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.verified, size: 16, color: UColors.success.withOpacity(0.9)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('Farmer  ·  ', style: TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                          Icon(Icons.circle, size: 8, color: widget.online ? UColors.success : UColors.darkGray),
                          const SizedBox(width: 4),
                          Text(widget.online ? 'Online' : 'Offline', style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                        ],
                      ),
                      if (widget.farmerPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(widget.farmerPhone, style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages
          expandedMessagesWidget(),

          // Composer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(USizes.defaultSpace, 8, USizes.defaultSpace, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? UColors.cardDark : UColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, color: UColors.textSecondaryLight, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: UColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send_rounded, color: UColors.textWhite),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.verified_user, size: 14, color: UColors.success),
                      SizedBox(width: 6),
                      Text('All messages are blockchain verified', style: TextStyle(fontSize: 11, color: UColors.textSecondaryLight)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget expandedMessagesWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_messagesStream == null) {
      // show placeholder using local contact message if provided
      return Expanded(
        child: ListView(
          padding: const EdgeInsets.all(USizes.defaultSpace),
          children: [
            if (widget.farmerPhone.isNotEmpty) ...[
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
                        child: Text('Contact info: ${widget.farmerName} · ${widget.farmerPhone}', style: const TextStyle(color: UColors.textPrimaryLight)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Expanded(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _messagesStream,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(USizes.defaultSpace),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final m = docs[index].data();
              final isMe = (m['senderId'] ?? '') == (FirebaseAuth.instance.currentUser?.uid ?? '');
              final text = (m['text'] ?? '').toString();
              final time = m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate().toLocal().toString() : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
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
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final String time;
  _Message({required this.text, required this.isMe, required this.time});
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 36});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: UColors.gray,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.person, color: UColors.textSecondaryLight),
    );
  }
}
