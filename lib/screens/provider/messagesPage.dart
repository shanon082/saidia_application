import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/screens/provider/providerChatPage.dart';
import 'package:saidia_app/services/firestore_services.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _ConversationSummary {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final Timestamp? lastMessageTime;

  const _ConversationSummary({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}

class _MessagesPageState extends State<MessagesPage> {
  final FirestoreService _service = FirestoreService();
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  String _chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // String _formatTime(Timestamp? ts) {
  //   if (ts == null) return '';
  //   final dt = ts.toDate();
  //   final now = DateTime.now();
  //   if (now.difference(dt).inDays == 0) return DateFormat('HH:mm').format(dt);
  //   return DateFormat('dd MMM').format(dt);
  // }

    String _formatTime(dynamic ts) {
    if (ts == null) return '';

    DateTime? dateTime;

    if (ts is Timestamp) {
      dateTime = ts.toDate();
    } else if (ts is String) {
      try {
        dateTime = DateTime.parse(ts);
      } catch (_) {}
    } else if (ts is DateTime) {
      dateTime = ts;
    }

    if (dateTime == null) return '';

    return DateFormat('HH:mm').format(dateTime);
  }

  Future<List<_ConversationSummary>> _loadConversationSummaries({
    required String uid,
    required Set<String> chatIds,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> chatDocs,
  }) async {
    final chatDocMap = {for (final d in chatDocs) d.id: d.data()};

    final futures = chatIds.map((chatId) async {
      final ids = chatId.split('_');
      final fallbackOther = ids.firstWhere(
        (id) => id != uid,
        orElse: () => chatId,
      );

      final messageSnap = await _supabase
          .from('messages')
          .select()
          .eq('chatId', chatId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (messageSnap.isEmpty) return null;

      final msg = messageSnap.first;
      final chatMeta = chatDocMap[chatId];
      final participants =
          (chatMeta?['participants'] as List?)?.cast<String>() ?? [];
      final other = participants.firstWhere(
        (id) => id != uid,
        orElse: () => fallbackOther,
      );
      final userSnap = await _supabase.from('users').select().eq('id', other).maybeSingle();
      final userNameRaw = userSnap?['name']?.toString().trim();
      final otherName = (userNameRaw != null && userNameRaw.isNotEmpty)
          ? userNameRaw
          : other;

      return _ConversationSummary(
        chatId: chatId,
        otherUserId: other,
        otherUserName: otherName,
        lastMessage: (msg['message']?.toString() ?? '').trim(),
        lastMessageTime: msg['timestamp'] as Timestamp?,
      );
    }).toList();

    final items = (await Future.wait(
      futures,
    )).whereType<_ConversationSummary>().toList();
    items.sort((a, b) {
      final aMs = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      final bMs = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      return bMs.compareTo(aMs);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _service.currentUid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in again.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversation by user id...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getProviderBookingsStream(),
              builder: (context, bookingsSnapshot) {
                if (bookingsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (bookingsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load bookings: ${bookingsSnapshot.error}',
                    ),
                  );
                }

                final bookingDocs = bookingsSnapshot.data?.docs ?? [];
                final bookingChatIds = <String>{};
                for (final doc in bookingDocs) {
                  final customerId = doc.data()['customerId']?.toString();
                  if (customerId != null && customerId.isNotEmpty) {
                    bookingChatIds.add(_chatIdFor(uid, customerId));
                  }
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.getProviderChatsStream(),
                  builder: (context, chatSnapshot) {
                    final chatDocs =
                        chatSnapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    final chatIds = {
                      ...bookingChatIds,
                      ...chatDocs.map((d) => d.id),
                    };

                    if (chatIds.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return FutureBuilder<List<_ConversationSummary>>(
                      future: _loadConversationSummaries(
                        uid: uid,
                        chatIds: chatIds,
                        chatDocs: chatDocs,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load messages: ${snapshot.error}',
                            ),
                          );
                        }

                        final all = snapshot.data ?? [];
                        final query = _searchController.text
                            .trim()
                            .toLowerCase();
                        final filtered = all.where((c) {
                          if (query.isEmpty) return true;
                          return c.otherUserId.toLowerCase().contains(query) ||
                              c.otherUserName.toLowerCase().contains(query);
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Center(child: Text('No messages yet'));
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final convo = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              title: Text(
                                convo.otherUserName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${convo.lastMessage.isEmpty ? 'No messages yet' : convo.lastMessage}\n${convo.otherUserId}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                _formatTime(convo.lastMessageTime),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProviderChatPage(
                                      otherUserId: convo.otherUserId,
                                      otherUserName: convo.otherUserName,
                                      chatId: convo.chatId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
