import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'chat_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  List<dynamic> conversations = [];
  bool isLoading = true;
  int currentUserId = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadConversations();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      loadConversations();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadConversations() async {
    final user = await ApiService.getCurrentUser();
    currentUserId = user?['id'] ?? 0;
    conversations = await ApiService.getConversations();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final user = conv['user1']['id'] == currentUserId ? conv['user2'] : conv['user1'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['avatarUrl'] != null
                        ? NetworkImage(user['avatarUrl'])
                        : null,
                    child: user['avatarUrl'] == null
                        ? const Icon(Icons.person, color: Colors.deepOrange)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(user['username'] ?? '')),
                      const Icon(Icons.circle, color: Colors.green, size: 12),
                    ],
                  ),
                  subtitle: Text(conv['lastMessageContent'] ?? ''),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_formatTime(conv['lastMessageTime'])),
                      if ((conv['unreadCount'] ?? 0) > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text('${conv['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(player: user),
                      ),
                    );
                    loadConversations();
                  },
                );
              },
            ),
    );
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
} 