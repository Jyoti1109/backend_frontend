import 'package:flutter/material.dart';
import 'package:good_news/core/services/social_api_service.dart';
import 'package:good_news/core/services/preferences_service.dart';
import 'dart:io';

class FriendsPostsScreen extends StatefulWidget {
  const FriendsPostsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsPostsScreen> createState() => _FriendsPostsScreenState();
}

class _FriendsPostsScreenState extends State<FriendsPostsScreen> {
  List<Map<String, dynamic>> _friendsPosts = [];
  List<Map<String, dynamic>> _myFriends = [];

  bool _isLoadingFriends = true;
  bool _isLoadingFriendsPosts = true;

  Map<String, List<Map<String, dynamic>>> _postComments = {};
  Map<String, bool> _showCommentsMap = {};
  Map<String, bool> _isLoadingCommentsMap = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadFriends();
    await _loadFriendsPosts();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoadingFriends = true);

    try {
      print('📱 FRIENDS POSTS: Loading friends list...');
      final response = await SocialApiService.getFriends();

      if (response['status'] == 'success') {
        final friendsList = response['data'] as List;
        setState(() {
          _myFriends = friendsList.map((friend) => Map<String, dynamic>.from(friend)).toList();
        });
        print('✅ FRIENDS POSTS: Loaded ${_myFriends.length} friends');
      }
    } catch (e) {
      print('❌ FRIENDS POSTS: Error loading friends: $e');
    } finally {
      setState(() => _isLoadingFriends = false);
    }
  }

  Future<void> _loadFriendsPosts() async {
    setState(() => _isLoadingFriendsPosts = true);

    try {
      print('📱 FRIENDS POSTS: Loading friends posts (visibility=friends)...');

      final response = await SocialApiService.getPosts(
        limit: 50,
        visibility: 'friends',
      );

      if (response['status'] == 'success') {
        final postsList = response['posts'] as List;

        final friendIds = _myFriends.map((f) => f['id'] ?? f['user_id']).toSet();

        final List<int> locallyLikedPosts = await PreferencesService.getLikedPosts();
        print('💾 FRIENDS POSTS: Locally liked posts: $locallyLikedPosts');

        setState(() {
          _friendsPosts = postsList.where((post) {
            final userId = post['user_id'];
            return friendIds.contains(userId);
          }).map((post) => _formatPost(post, locallyLikedPosts)).toList();
        });

        print('✅ FRIENDS POSTS: Loaded ${_friendsPosts.length} friends posts');
      }
    } catch (e) {
      print('❌ FRIENDS POSTS: Error loading friends posts: $e');
    } finally {
      setState(() => _isLoadingFriendsPosts = false);
    }
  }

  Map<String, dynamic> _formatPost(Map<String, dynamic> post, List<int> locallyLikedPosts) {
    final authorName = post['display_name'] ?? 'Unknown';
    final commentsCount = post['comments_count'] ?? 0;
    final likesCount = post['likes_count'] ?? 0;
    final imageUrl = post['image_url'] as String?;

    final postId = post['id'] is int ? post['id'] : int.tryParse(post['id'].toString()) ?? 0;

    final apiLiked = post['user_has_liked'] == 1 || post['user_has_liked'] == true;
    final localLiked = locallyLikedPosts.contains(postId);
    final isLiked = apiLiked || localLiked;

    print('📊 FRIENDS POST $postId: API liked=$apiLiked, Local liked=$localLiked, Final isLiked=$isLiked');

    return {
      'id': postId.toString(),
      'author': authorName,
      'avatar': authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
      'title': post['title'] ?? '',
      'content': post['content'] ?? '',
      'created_at': post['created_at'],
      'likes': likesCount,
      'isLiked': isLiked,
      'comments_count': commentsCount,
      'visibility': post['visibility'] ?? 'friends',
      'image_url': imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null,
    };
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final postId = int.parse(post['id']);
    final bool wasLiked = post['isLiked'];
    final int currentLikes = post['likes'];

    setState(() {
      post['isLiked'] = !wasLiked;
      post['likes'] = wasLiked ? currentLikes - 1 : currentLikes + 1;
    });

    try {
      print('👍 FRIENDS POSTS: ${wasLiked ? 'Unliking' : 'Liking'} post $postId');

      final response = wasLiked
          ? await SocialApiService.unlikePost(postId)
          : await SocialApiService.likePost(postId);

      print('👍 FRIENDS POSTS: Like response: ${response['status']}');

      if (response['status'] == 'success') {
        if (!wasLiked) {
          await PreferencesService.saveLikedPost(postId);
          print('💾 FRIENDS POSTS: Saved like for post $postId to local storage');
        } else {
          await PreferencesService.removeLikedPost(postId);
          print('🗑️ FRIENDS POSTS: Removed like for post $postId from local storage');
        }

        if (response['likes_count'] != null) {
          setState(() {
            post['likes'] = response['likes_count'];
          });
          print('✅ FRIENDS POSTS: Updated likes count from server: ${response['likes_count']}');
        }
      } else {
        if (mounted) {
          setState(() {
            post['isLiked'] = wasLiked;
            post['likes'] = currentLikes;
          });
        }
        print('❌ FRIENDS POSTS: Like/unlike failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          post['isLiked'] = wasLiked;
          post['likes'] = currentLikes;
        });
      }
      print('❌ FRIENDS POSTS: Error in like/unlike: $e');
    }
  }

  Future<void> _loadCommentsForPost(String postId) async {
    if (_isLoadingCommentsMap[postId] == true) return;

    setState(() => _isLoadingCommentsMap[postId] = true);

    try {
      final postIdInt = int.parse(postId);
      final response = await SocialApiService.getComments(postIdInt);

      if (response['status'] == 'success') {
        final rawComments = response['comments'] as List;

        final formattedComments = rawComments.map((comment) {
          final authorName = comment['display_name'] ?? 'Anonymous';

          return {
            'id': comment['id'],
            'author': authorName,
            'avatar': authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
            'content': comment['content'] ?? '',
            'timestamp': _formatTimestamp(comment['created_at']),
            'created_at': comment['created_at'],
          };
        }).toList();

        setState(() {
          _postComments[postId] = formattedComments;
          _showCommentsMap[postId] = true;
          _isLoadingCommentsMap[postId] = false;
        });
      }
    } catch (e) {
      print('❌ Error loading comments: $e');
      setState(() => _isLoadingCommentsMap[postId] = false);
    }
  }

  Future<void> _toggleCommentsForPost(String postId) async {
    if (_showCommentsMap[postId] == true) {
      setState(() => _showCommentsMap[postId] = false);
    } else {
      await _loadCommentsForPost(postId);
    }
  }

  Future<void> _postComment(String postId) async {
    final controller = _commentControllers[postId];
    if (controller == null) return;

    final content = controller.text.trim();
    if (content.isEmpty) return;

    FocusScope.of(context).unfocus();

    try {
      final postIdInt = int.parse(postId);
      final response = await SocialApiService.createComment(postIdInt, content);

      if (response['status'] == 'success') {
        String? userDisplayName;
        try {
          userDisplayName = await PreferencesService.getUserDisplayName();
        } catch (e) {
          userDisplayName = 'Me';
        }

        final newComment = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'author': userDisplayName ?? 'Me',
          'avatar': (userDisplayName ?? 'M').isNotEmpty
              ? (userDisplayName ?? 'M')[0].toUpperCase()
              : 'M',
          'content': content,
          'timestamp': 'Just now',
          'created_at': DateTime.now().toIso8601String(),
        };

        setState(() {
          _postComments[postId] = [
            ...(_postComments[postId] ?? []),
            newComment,
          ];
          controller.clear();

          final index = _friendsPosts.indexWhere((p) => p['id'] == postId);
          if (index != -1) {
            _friendsPosts[index]['comments_count']++;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Comment posted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dateTime = HttpDate.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends Posts'),
      ),
      body: _isLoadingFriends
          ? const Center(child: CircularProgressIndicator())
          : _buildPostsList(),
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingFriendsPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendsPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No friends posts yet!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Posts from your friends will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friendsPosts.length,
        itemBuilder: (context, index) => _buildPostCard(_friendsPosts[index]),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id'] as String;
    final comments = _postComments[postId] ?? [];
    final showComments = _showCommentsMap[postId] ?? false;
    final isLoadingComments = _isLoadingCommentsMap[postId] ?? false;
    final commentsCount = post['comments_count'] ?? 0;
    final imageUrl = post['image_url'] as String?;

    if (!_commentControllers.containsKey(postId)) {
      _commentControllers[postId] = TextEditingController();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header - NAMES REMOVED, only avatar and timestamp
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    post['avatar'],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatTimestamp(post['created_at']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Friends',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Content (NO TITLE SHOWN)
            Text(
              post['content'],
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),

            // Image (if exists)
            if (imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading image: $error');
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _toggleLike(post),
                    icon: Icon(
                      post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                      color: post['isLiked'] ? Colors.red : null,
                      size: 20,
                    ),
                    label: Text('${post['likes']}'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: isLoadingComments
                        ? null
                        : () => _toggleCommentsForPost(postId),
                    icon: isLoadingComments
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Icon(
                      showComments ? Icons.comment : Icons.comment_outlined,
                      size: 20,
                    ),
                    label: Text('$commentsCount'),
                  ),
                ),
              ],
            ),

            // Comments section
            if (showComments) ...[
              const Divider(),
              const SizedBox(height: 8),

              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...comments.map((comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        child: Text(
                          comment['avatar'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
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
                              comment['content'],
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment['timestamp'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

              const SizedBox(height: 12),

              // Comment input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentControllers[postId],
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(postId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _postComment(postId),
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}