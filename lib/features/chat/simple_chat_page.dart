import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';

class SimpleChatPage extends StatefulWidget {
  final String chatId;
  final String title;
  final String phone;
  const SimpleChatPage({super.key, required this.chatId, this.title = '', this.phone = ''});

  @override
  State<SimpleChatPage> createState() => _SimpleChatPageState();
}

class _SimpleChatPageState extends State<SimpleChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final CollectionReference<Map<String, dynamic>> _msgsRef;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _msgsRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages') as CollectionReference<Map<String, dynamic>>;
    _stream = _msgsRef.orderBy('createdAt', descending: false).snapshots();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await _msgsRef.add({'senderId': uid, 'text': text, 'createdAt': FieldValue.serverTimestamp()});
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'lastMessage': text, 'updatedAt': FieldValue.serverTimestamp()});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title.isNotEmpty ? widget.title : 'Chat'), backgroundColor: UColors.primary),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snap.data?.docs ?? [];
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(USizes.defaultSpace),
                itemCount: docs.length,
                itemBuilder: (context, idx) {
                  final m = docs[idx].data();
                  final isMe = (m['senderId'] ?? '') == (FirebaseAuth.instance.currentUser?.uid ?? '');
                  final text = (m['text'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: isMe ? UColors.primary : (isDark ? UColors.cardDark : UColors.white), borderRadius: BorderRadius.circular(12)),
                        child: Text(text, style: TextStyle(color: isMe ? UColors.textWhite : (isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight))),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(USizes.defaultSpace, 8, USizes.defaultSpace, 12),
            child: Row(children: [
              Expanded(
                child: TextField(controller: _controller, decoration: InputDecoration(hintText: 'Type a message...', filled: true, fillColor: isDark ? UColors.cardDark : UColors.backgroundLight, border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)))),
              ),
              const SizedBox(width: 8),
              InkWell(onTap: _send, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: UColors.primary, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.send, color: UColors.textWhite))),
            ]),
          ),
        )
      ]),
    );
  }
}

