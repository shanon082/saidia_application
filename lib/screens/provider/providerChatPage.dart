import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class ProviderChatPage extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final String chatId;

  const ProviderChatPage({
    super.key,
    required this.otherUserId,
    this.otherUserName,
    required this.chatId,
  });

  @override
  State<ProviderChatPage> createState() => _ProviderChatPageState();
}

class _ProviderChatPageState extends State<ProviderChatPage> {
  final FirestoreService _service = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  String? _fetchedName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    if (widget.otherUserName != null && widget.otherUserName!.isNotEmpty) {
      _fetchedName = widget.otherUserName;
      setState((){});
      return;
    }
    try {
      final res = await Supabase.instance.client.from('users').select('name').eq('id', widget.otherUserId).maybeSingle();
      if (res != null) {
        setState(() => _fetchedName = res['name']);
      }
    } catch (_) {}
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    return DateFormat('HH:mm').format(ts.toDate());
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _service.sendMessageToUser(
      recipientId: widget.otherUserId,
      message: text,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _service.currentUid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_fetchedName ?? widget.otherUserName ?? widget.otherUserId),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getChatStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load messages: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final mine = data['senderId'] == uid;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? Colors.blue.shade700
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: mine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['message']?.toString() ?? '',
                              style: TextStyle(
                                color: mine ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatTime(data['timestamp'] as Timestamp?),
                              style: TextStyle(
                                fontSize: 11,
                                color: mine
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
