import 'package:flutter/material.dart';
import 'package:good_news/core/services/social_api_service.dart';
import 'package:good_news/core/constants/theme_tokens.dart';
import 'package:good_news/features/social/presentation/screens/friends_modal.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with RouteAware {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  // Auto-reload when screen becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload conversations when returning to this screen
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final response = await SocialApiService.getConversations();

      if (response['status'] == 'success') {
        final conversationsData = response['conversations'];
        if (conversationsData is List) {
          final formatted = await Future.wait(conversationsData.map((conv) async {
            final lastMessage = await SocialApiService.getLastMessage(int.parse(conv['id'].toString()));
            return _formatConversation(conv as Map<String, dynamic>, lastMessage);
          }).toList());

          setState(() {
            _conversations = formatted;
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid conversations data format');
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to load conversations');
      }
    } catch (e) {
      print('❌ MESSAGES: Failed to load conversations: $e');
      setState(() {
        _conversations = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _formatConversation(Map<String, dynamic> conv, String lastMessage) {
    return {
      'id': conv['id'].toString(),
      'friendName': conv['friend_name'] ?? 'Unknown',
      'avatar': (conv['friend_name'] ?? 'U')[0].toUpperCase(),
      'lastMessage': lastMessage,
      'timestamp': _formatTimestamp(conv['last_activity']),
      'unreadCount': 0,
      'friendId': conv['friend_id'],
    };
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now().toLocal();
      final diff = now.difference(dateTime.toLocal());

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return DateFormat('MMM dd').format(dateTime.toLocal());
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeTokens.darkBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Messages (${_conversations.length})'),
        backgroundColor: ThemeTokens.darkBackground,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Refresh conversations',
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const  FriendsModal(),
                ),
              );
            },
            tooltip: 'Add a new friend',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ThemeTokens.primaryGreen),
            SizedBox(height: 16),
            Text('Loading conversations...', style: TextStyle(color: Colors.white)),
          ],
        ),
      )
          : _conversations.isEmpty
          ? _buildEmptyState()
          : _buildConversationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: ThemeTokens.primaryGreen.withOpacity(0.6)),
          const SizedBox(height: 24),
          const Text(
            'Start a chat to spread positivity 💬',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
          onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const  FriendsModal()),
              );
              if (result == true) {
                _loadConversations();
              }
            },
            icon: const Icon(Icons.people, size: 20),
            label: const Text('Find Friends'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeTokens.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadConversations,
            child: const Text('Retry Loading', style: TextStyle(color: ThemeTokens.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: ThemeTokens.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: ThemeTokens.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: ThemeTokens.primaryGreen.withOpacity(0.2),
            child: Text(
              conversation['avatar'],
              style: const TextStyle(
                color: ThemeTokens.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            conversation['friendName'],
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            conversation['lastMessage'],
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                conversation['timestamp'],
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFFB3B3B3), size: 14),
            ],
          ),
          onTap: () async {
            // Navigate to chat and reload on return
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  friendName: conversation['friendName'],
                  friendAvatar: conversation['avatar'],
                  conversationId: conversation['id'],
                ),
              ),
            );
            // Reload conversations when returning
            _loadConversations();
          },
        ),
      ),
    );
  }
}

// ===== CHAT SCREEN =====
class ChatScreen extends StatefulWidget {
  final String friendName;
  final String friendAvatar;
  final String conversationId;

  const ChatScreen({
    Key? key,
    required this.friendName,
    required this.friendAvatar,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  Timer? _pollingTimer;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadMessagesQuietly();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _fetchMessages();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessagesQuietly() async {
    if (!mounted) return;
    await _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await SocialApiService.getMessages(int.parse(widget.conversationId));

      if (response['status'] == 'success') {
        final newMessages = List<Map<String, dynamic>>.from(response['messages']);

        if (newMessages.length != _lastMessageCount || _messagesChanged(newMessages)) {
          if (mounted) {
            setState(() {
              _messages = newMessages;
              _lastMessageCount = newMessages.length;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && mounted) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ CHAT: Failed to load messages: $e');
    }
  }

  bool _messagesChanged(List<Map<String, dynamic>> newMessages) {
    if (newMessages.length != _messages.length) return true;

    for (int i = 0; i < newMessages.length; i++) {
      if (newMessages[i]['id'] != _messages[i]['id']) return true;
    }

    return false;
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMessage = {
      'id': tempId,
      'text': content,
      'isMe': true,
      'timestamp': 'Sending...',
    };

    setState(() {
      _messages.add(newMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final response = await SocialApiService.sendMessage(
        int.parse(widget.conversationId),
        content,
      );

      if (response['status'] == 'success') {
        await _fetchMessages();
      } else {
        throw Exception(response['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg['id'] == tempId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeTokens.darkBackground,
      appBar: AppBar(
        backgroundColor: ThemeTokens.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: ThemeTokens.primaryGreen.withOpacity(0.2),
              child: Text(
                widget.friendAvatar,
                style: const TextStyle(
                  color: ThemeTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.friendName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadMessages,
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(
              child: CircularProgressIndicator(color: ThemeTokens.primaryGreen),
            )
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: ThemeTokens.primaryGreen.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a message to start the conversation',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool? ?? false;
    final timestamp = message['timestamp'] as String? ?? 'Now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: ThemeTokens.primaryGreen.withOpacity(0.2),
              child: Text(
                widget.friendAvatar,
                style: const TextStyle(
                  color: ThemeTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? ThemeTokens.primaryGreen : ThemeTokens.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'] as String? ?? 'No message',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timestamp,
                    style: TextStyle(
                      color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFFB3B3B3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeTokens.cardBackground,
        border: Border(top: BorderSide(color: ThemeTokens.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Color(0xFFB3B3B3)),
                filled: true,
                fillColor: ThemeTokens.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: ThemeTokens.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}