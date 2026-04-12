import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import 'package:saidia_app/services/firestore_services.dart';

import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String providerId;
  final String? providerName;

  const ChatPage({super.key, required this.providerId, this.providerName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _service = FirestoreService();
  final _messageController = TextEditingController();
  final _currentUser = FirestoreService.instance.currentUser;
  final ScrollController _scrollController = ScrollController();
  String? _fetchedName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    // Auto-scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _fetchUserName() async {
    if (widget.providerName != null && widget.providerName!.isNotEmpty) {
      _fetchedName = widget.providerName;
      setState((){});
      return;
    }
    try {
      final res = await Supabase.instance.client.from('users').select('name').eq('id', widget.providerId).maybeSingle();
      if (res != null) {
        setState(() => _fetchedName = res['name']);
      }
    } catch (_) {}
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _service.sendMessage(
        providerId: widget.providerId,
        message: message,
      );
      _messageController.clear();
      // Scroll to bottom after sending
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    
    if (now.difference(messageTime).inDays == 0) {
      return DateFormat('HH:mm').format(messageTime);
    } else if (now.difference(messageTime).inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(messageTime)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(messageTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fetchedName ?? widget.providerName ?? 'Service Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Online',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              // Call functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getChatStream(widget.providerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue.shade700,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation with your provider',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: messages.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final msgData = messages[index].data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == _currentUser?.id;
                    final timestamp = msgData['timestamp'] as Timestamp?;
                    final messageText = msgData['message'] ?? '';

                    return Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Date separator for new days
                        if (index == 0 || _isNewDay(messages, index))
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getDaySeparator(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),

                        // Message bubble
                        Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.person, size: 18, color: Colors.blue.shade700),
                              ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue.shade700 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                                    bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      messageText,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.grey.shade900,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      timestamp != null ? _formatTimestamp(timestamp) : '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe)
                              SizedBox(width: 8),
                            if (isMe)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.person, size: 18, color: Colors.blue.shade700),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.blue.shade700),
                  onPressed: () {
                    // Attachment functionality
                  },
                ),
                
                // Message input field
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                
                // Send button
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isNewDay(List<QueryDocumentSnapshot> messages, int index) {
    if (index == 0) return false;
    
    final currentMsg = messages[index].data() as Map<String, dynamic>;
    final previousMsg = messages[index - 1].data() as Map<String, dynamic>;
    
    final currentTimestamp = currentMsg['timestamp'] as Timestamp?;
    final previousTimestamp = previousMsg['timestamp'] as Timestamp?;
    
    if (currentTimestamp == null || previousTimestamp == null) return false;
    
    final currentDate = currentTimestamp.toDate();
    final previousDate = previousTimestamp.toDate();
    
    return currentDate.day != previousDate.day ||
           currentDate.month != previousDate.month ||
           currentDate.year != previousDate.year;
  }

  String _getDaySeparator(Timestamp? timestamp) {
    if (timestamp == null) return 'Today';
    
    final now = DateTime.now();
    final messageDate = timestamp.toDate();
    
    if (now.year == messageDate.year &&
        now.month == messageDate.month &&
        now.day == messageDate.day) {
      return 'Today';
    } else if (now.year == messageDate.year &&
               now.month == messageDate.month &&
               now.day - 1 == messageDate.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(messageDate);
    }
  }
}