// lib/features/profile/presentation/screens/my_posts_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:good_news/core/services/social_api_service.dart';
import 'package:intl/intl.dart';

class MyPostsScreen extends StatefulWidget {
  final int? userId;

  const MyPostsScreen({super.key, this.userId});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _publicPosts = [];
  List<Map<String, dynamic>> _friendsPosts = [];
  List<Map<String, dynamic>> _privatePosts = [];

  bool _isLoading = true;
  String _error = '';

  // Store comments for each post: postId -> List of comments
  final Map<int, List<Map<String, dynamic>>> _postComments = {};

  // Track whether comments are expanded for each post
  final Map<int, bool> _isCommentsExpanded = {};

  // Track loading state for comments
  final Map<int, bool> _isLoadingComments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.userId != null) {
      _loadMyPosts();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'User ID not available';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommentsForPost(int postId) async {
    if (_postComments.containsKey(postId) || _isLoadingComments[postId] == true) {
      return; // Already loaded or loading
    }

    setState(() {
      _isLoadingComments[postId] = true;
    });

    print('📡 MY POSTS: Loading comments for post $postId');

    final result = await SocialApiService.getComments(postId);

    print('📡 MY POSTS: Comments result: $result');

    if (result['status'] == 'success') {
      final comments = (result['comments'] as List?)
          ?.map((c) => Map<String, dynamic>.from(c))
          .toList() ?? [];

      print('✅ MY POSTS: Loaded ${comments.length} comments for post $postId');

      setState(() {
        _postComments[postId] = comments;
        _isLoadingComments[postId] = false;
      });
    } else {
      print('❌ MY POSTS: Failed to load comments: ${result['error']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load comments: ${result['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingComments[postId] = false;
      });
    }
  }

  Future<void> _loadMyPosts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print('📱 MY POSTS: Loading ALL posts for user ${widget.userId}');

      final publicResponse = await SocialApiService.getPosts(limit: 100, visibility: 'public');
      final friendsResponse = await SocialApiService.getPosts(limit: 100, visibility: 'friends');
      final privateResponse = await SocialApiService.getPosts(limit: 100, visibility: 'private');

      List<Map<String, dynamic>> filterUserPosts(dynamic response) {
        if (response['status'] != 'success') return [];
        final posts = (response['posts'] as List?) ?? [];
        return posts
            .where((post) => post['user_id'] == widget.userId)
            .map((p) {
          final post = Map<String, dynamic>.from(p);
          // Ensure comments_count is an integer
          if (post['comments_count'] == null) {
            post['comments_count'] = 0;
          } else if (post['comments_count'] is String) {
            post['comments_count'] = int.tryParse(post['comments_count']) ?? 0;
          }
          return post;
        })
            .toList();
      }

      final publicPosts = filterUserPosts(publicResponse);
      final friendsPosts = filterUserPosts(friendsResponse);
      final privatePosts = filterUserPosts(privateResponse);

      print('📱 MY POSTS: Public: ${publicPosts.length}, Friends: ${friendsPosts.length}, Private: ${privatePosts.length}');

      setState(() {
        _publicPosts = publicPosts;
        _friendsPosts = friendsPosts;
        _privatePosts = privatePosts;
      });

    } catch (e) {
      print('❌ MY POSTS: Error loading posts: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editPost(BuildContext context, int postId, String currentContent) async {
    final controller = TextEditingController(text: currentContent);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Update your post...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);

                final result = await SocialApiService.updatePost(postId, controller.text.trim());

                if (result['status'] == 'success') {
                  setState(() {
                    final publicIndex = _publicPosts.indexWhere((p) => p['id'] == postId);
                    if (publicIndex != -1) {
                      _publicPosts[publicIndex]['content'] = controller.text.trim();
                    }

                    final friendsIndex = _friendsPosts.indexWhere((p) => p['id'] == postId);
                    if (friendsIndex != -1) {
                      _friendsPosts[friendsIndex]['content'] = controller.text.trim();
                    }

                    final privateIndex = _privatePosts.indexWhere((p) => p['id'] == postId);
                    if (privateIndex != -1) {
                      _privatePosts[privateIndex]['content'] = controller.text.trim();
                    }
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Post updated!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Failed to update: ${result['error'] ?? 'Unknown error'}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int postId, String visibility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final result = await SocialApiService.deletePost(postId);

              if (result['status'] == 'success') {
                setState(() {
                  if (visibility == 'public') {
                    _publicPosts.removeWhere((p) => p['id'] == postId);
                  } else if (visibility == 'friends') {
                    _friendsPosts.removeWhere((p) => p['id'] == postId);
                  } else if (visibility == 'private') {
                    _privatePosts.removeWhere((p) => p['id'] == postId);
                  }
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Post deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Failed to delete: ${result['error'] ?? 'Unknown error'}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Just now';
    try {
      final dt = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(dt.toLocal());
    } catch (e) {
      try {
        final dt = DateTime.parse(dateTimeStr);
        return DateFormat('MMM dd, yyyy hh:mm a').format(dt.toLocal());
      } catch (e2) {
        return 'Unknown date';
      }
    }
  }

  void _toggleComments(int postId, int commentsCount) {
    if (commentsCount == 0) {
      // No comments to show
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No comments yet'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final isCurrentlyExpanded = _isCommentsExpanded[postId] ?? false;

    setState(() {
      _isCommentsExpanded[postId] = !isCurrentlyExpanded;
    });

    // Load comments if expanding and not already loaded
    if (!isCurrentlyExpanded && !_postComments.containsKey(postId)) {
      _loadCommentsForPost(postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyPosts,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // ✅ फक्त ही लाईन जोडली आहे!
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, size: 18),
                  const SizedBox(width: 6),
                  Text('Public (${_publicPosts.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 18),
                  const SizedBox(width: 6),
                  Text('Friends (${_friendsPosts.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 18),
                  const SizedBox(width: 6),
                  Text('Private (${_privatePosts.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMyPosts,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : TabBarView(
          controller: _tabController,
          children: [
            _buildPostsList(_publicPosts, 'public'),
            _buildPostsList(_friendsPosts, 'friends'),
            _buildPostsList(_privatePosts, 'private'),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(List<Map<String, dynamic>> posts, String visibility) {
    if (posts.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;

      switch (visibility) {
        case 'public':
          emptyMessage = 'No public posts yet.\nShare something with everyone!';
          emptyIcon = Icons.public;
          break;
        case 'friends':
          emptyMessage = 'No friends posts yet.\nShare something with your friends!';
          emptyIcon = Icons.people;
          break;
        case 'private':
          emptyMessage = 'No private posts yet.\nKeep your thoughts private!';
          emptyIcon = Icons.lock;
          break;
        default:
          emptyMessage = 'No posts yet';
          emptyIcon = Icons.article_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) => _buildPostCard(posts[index], visibility),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, String visibility) {
    final content = post['content'] as String;
    final title = post['title'] as String?;
    final createdAt = _formatDate(post['created_at']);
    final likes = post['likes_count'] ?? 0;
    final commentsCount = (post['comments_count'] is int)
        ? post['comments_count'] as int
        : int.tryParse(post['comments_count']?.toString() ?? '0') ?? 0;
    final postId = post['id'] as int;
    final imageUrl = post['image_url'] as String?;

    final comments = _postComments[postId] ?? [];
    final isExpanded = _isCommentsExpanded[postId] ?? false;
    final isLoadingComments = _isLoadingComments[postId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with visibility badge
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getVisibilityColor(visibility).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getVisibilityIcon(visibility),
                          size: 14,
                          color: _getVisibilityColor(visibility),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getVisibilityLabel(visibility),
                          style: TextStyle(
                            color: _getVisibilityColor(visibility),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      createdAt,
                      textAlign: TextAlign.end,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post content
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
              softWrap: true,
              overflow: TextOverflow.clip,
            ),

            // Post image (if exists)
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
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
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Likes & Comments count + Actions
            Row(
              children: [
                // Likes (display only)
                Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: Colors.red.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: TextStyle(
                        color: likes > 0 ? Colors.red : Colors.grey[600],
                        fontWeight: likes > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Comments count (clickable)
                InkWell(
                  onTap: () => _toggleComments(postId, commentsCount),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: commentsCount > 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$commentsCount',
                          style: TextStyle(
                            color: commentsCount > 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                            fontWeight: commentsCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Edit & Delete
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editPost(context, postId, content),
                  tooltip: 'Edit post',
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _showDeleteDialog(context, postId, visibility),
                  tooltip: 'Delete post',
                  color: Colors.red,
                ),
              ],
            ),

            // Comments section toggle (expandable text)
            if (commentsCount > 0) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _toggleComments(postId, commentsCount),
                child: Row(
                  children: [
                    Text(
                      isExpanded
                          ? 'Hide comments'
                          : 'View $commentsCount ${commentsCount == 1 ? 'comment' : 'comments'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],

            // Show actual comments if expanded
            if (isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              if (isLoadingComments)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_postComments.containsKey(postId)) ...[
                if (comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No comments yet.',
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
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: Text(
                            (comment['display_name'] as String?)?.substring(0, 1)?.toUpperCase() ?? '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['display_name'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment['content'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(comment['created_at']),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getVisibilityColor(String visibility) {
    switch (visibility) {
      case 'public':
        return Colors.green;
      case 'friends':
        return Colors.blue;
      case 'private':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.people;
      case 'private':
        return Icons.lock;
      default:
        return Icons.help_outline;
    }
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'friends':
        return 'Friends';
      case 'private':
        return 'Private';
      default:
        return 'Unknown';
    }
  }
}