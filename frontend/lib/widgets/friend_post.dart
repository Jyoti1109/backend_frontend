import 'package:flutter/material.dart';
import 'package:good_news/core/services/social_api_service.dart';
import 'package:good_news/core/services/preferences_service.dart';

class FriendPost extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  const FriendPost({
    Key? key,
    required this.post,
    this.onLike,
    this.onShare,
  }) : super(key: key);

  @override
  State<FriendPost> createState() => _FriendPostState();
}

class _FriendPostState extends State<FriendPost> {
  late Map<String, dynamic> _post;
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    // Make a mutable copy so we can update comments & visibility
    _post = Map<String, dynamic>.from(widget.post);
    if (!_post.containsKey('comments')) {
      _post['comments'] = <Map<String, dynamic>>[];
    }
    if (!_post.containsKey('showComments')) {
      _post['showComments'] = false;
    }
  }

  Future<void> _loadComments() async {
    if (_post['comments'] != null && (_post['comments'] as List).isNotEmpty) {
      // Already loaded – just toggle
      _toggleComments();
      return;
    }

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final postId = int.parse(_post['id'].toString());
      final response = await SocialApiService.getComments(postId);

      if (response['status'] == 'success') {
        final rawComments = response['comments'] as List;
        final formattedComments = rawComments.map((comment) {
          final authorEmail = comment['author_email'] ?? comment['user_email'] ?? 'Anonymous';
          return {
            'id': comment['id'],
            'author': authorEmail,
            'avatar': authorEmail.isNotEmpty ? authorEmail[0].toUpperCase() : 'A',
            'content': comment['content'] ?? '',
            'timestamp': _formatTimestamp(comment['created_at']),
          };
        }).toList();

        setState(() {
          _post['comments'] = formattedComments;
          _post['showComments'] = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: ${response['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading comments: $e')),
      );
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  void _toggleComments() {
    setState(() {
      _post['showComments'] = !_post['showComments'];
    });
  }

  Future<void> _postComment() async {
    final postId = int.parse(_post['id'].toString());
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Write a comment...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context);

                final response = await SocialApiService.createComment(postId, content);
                if (response['status'] == 'success') {
                  // Get current user email for optimistic update
                  final userEmail = await PreferencesService.getUserEmail() ?? 'Me';
                  final newComment = {
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'author': userEmail,
                    'avatar': userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'M',
                    'content': content,
                    'timestamp': 'Just now',
                  };

                  setState(() {
                    final currentComments = List<Map<String, dynamic>>.from(_post['comments']);
                    currentComments.add(newComment);
                    _post['comments'] = currentComments;
                    _post['showComments'] = true;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment posted!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: ${response['error']}')),
                  );
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _post['isLiked'] ?? false;
    final comments = _post['comments'] as List;
    final showComments = _post['showComments'] as bool;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _post['avatar'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post['author'] ?? '',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _post['timestamp'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Post content
            Text(
              _post['content'] ?? '',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                // Like button
                TextButton.icon(
                  onPressed: widget.onLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isLiked ? Colors.red : Colors.grey[500],
                  ),
                  label: Text(
                    '${_post['likes'] ?? 0}',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),

                // Comment button
                TextButton.icon(
                  onPressed: _loadComments,
                  icon: Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                  label: Text(
                    '${comments.length}',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),

                const Spacer(),

                // Share button
                TextButton.icon(
                  onPressed: widget.onShare,
                  icon: Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'Share',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            // Comments Section (conditionally shown)
            if (showComments)
              Column(
                children: [
                  const Divider(height: 20),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _postComment,
                      child: const Text(
                        'Add Comment',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    comments.length,
                        (i) {
                      final comment = comments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: Text(
                                comment['avatar'] ?? 'A',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${comment['author']}: ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextSpan(
                                          text: comment['content'],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comment['timestamp'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),

            // Loading indicator (optional)
            if (_isLoadingComments)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}