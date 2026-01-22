import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:good_news/core/services/preferences_service.dart';
import 'package:good_news/core/services/social_api_service.dart';
import 'package:good_news/core/utils/responsive_helper.dart';
import 'package:good_news/features/articles/presentation/screens/friends_posts_screen.dart';
import 'package:good_news/features/social/presentation/screens/create_post_screen.dart';
import 'package:good_news/features/social/presentation/screens/friend_requests_screen.dart';
import 'package:good_news/features/social/presentation/screens/friends_modal.dart';
import 'package:good_news/features/social/presentation/screens/messages_screen.dart';
import 'package:good_news/widgets/speed_dial_fab.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class SocialScreen extends StatefulWidget {
  const SocialScreen({Key? key}) : super(key: key);

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  final Map<int, TextEditingController> _commentControllers = {};
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _isLoading = true);
      final token = await PreferencesService.getUserToken();

      final response = await http.get(
        Uri.parse('https://goodnewsapp.lemmecode.com/api/v1/posts'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final localLikes = await PreferencesService.getLikedPosts();

        setState(() {
          _posts = data.map<Map<String, dynamic>>((post) {
            final id = int.tryParse(post['id'].toString()) ?? 0;
            final apiLiked =
                post['user_has_liked'] == 1 || post['user_has_liked'] == true;
            final isLiked = apiLiked || localLikes.contains(id);
            return {
              'id': id,
              'author': post['display_name'] ?? 'Unknown',
              'avatar': (post['display_name'] ?? 'U')[0].toUpperCase(),
              'title': post['title'] ?? '',
              'content': post['content'] ?? '',
              'image_url': post['image_url'],
              'likes': post['likes_count'] ?? 0,
              'isLiked': isLiked,
              'created_at': post['created_at'],
              'comments': <Map<String, dynamic>>[],
              'showComments': false,
              'isLoadingComments': false,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading posts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(int postId, int index) async {
    final post = _posts[index];
    final wasLiked = post['isLiked'];
    final currentLikes = post['likes'];

    setState(() {
      post['isLiked'] = !wasLiked;
      post['likes'] = wasLiked ? currentLikes - 1 : currentLikes + 1;
    });

    try {
      final token = await PreferencesService.getUserToken();
      final url = Uri.parse(
        'https://goodnewsapp.lemmecode.com/api/v1/posts/$postId/${wasLiked ? 'unlike' : 'like'}',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          post['likes'] = data['likes_count'] ?? post['likes'];
        });

        if (!wasLiked) {
          await PreferencesService.saveLikedPost(postId);
        } else {
          await PreferencesService.removeLikedPost(postId);
        }
      } else {
        setState(() {
          post['isLiked'] = wasLiked;
          post['likes'] = currentLikes;
        });
      }
    } catch (e) {
      setState(() {
        post['isLiked'] = wasLiked;
        post['likes'] = currentLikes;
      });
    }
  }

  Future<void> _loadComments(int index) async {
    final post = _posts[index];
    final postId = post['id'];

    if (post['showComments']) {
      setState(() => post['showComments'] = false);
      _showFab = true; // 👈 show back FAB
      return;
    }

    setState(() => _showFab = false);
    setState(() {
      post['isLoadingComments'] = true;
      post['showComments'] = true;

    });

    try {
      final response = await SocialApiService.getComments(postId);
      if (response['status'] == 'success') {
        final comments = (response['comments'] as List).map((c) {
          final author = c['display_name'] ?? 'User';
          return {
            'author': author,
            'avatar': author[0].toUpperCase(),
            'content': c['content'] ?? '',
            'created_at': c['created_at'],
          };
        }).toList();
        setState(() {
          post['comments'] = comments;
          post['isLoadingComments'] = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading comments: $e');
      setState(() {
        post['isLoadingComments'] = false;
        post['showComments'] = false;
      });
    }
  }

  Future<void> _postComment(int index) async {
    if (!_commentControllers.containsKey(index)) {
      _commentControllers[index] = TextEditingController();
    }

    final controller = _commentControllers[index]!;
    final content = controller.text.trim();
    setState(() => _showFab = true);

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    final postId = _posts[index]['id'];

    try {
      final res = await SocialApiService.createComment(postId, content);
      if (res['status'] == 'success') {
        String? userDisplayName;
        try {
          userDisplayName = await PreferencesService.getUserDisplayName(); // ✅ GET DISPLAY NAME
        } catch (e) {
          userDisplayName = 'Me';
        }

        setState(() {
          _posts[index]['comments'].add({
            'author': userDisplayName ?? 'Me', // ✅ Always use display name
            'avatar': (userDisplayName ?? 'M')[0].toUpperCase(), // ✅ Use first letter of display name
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
          });
          controller.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Comment posted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  void _sharePost(Map<String, dynamic> post) {
    final content = post['content'];
    final title = post['title'];
    final shareText =
        '"$content"\n\n${title.isNotEmpty ? 'Post: $title' : ''}\nShared via Good News App';
    Share.share(shareText);
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
        title: const Text('Social Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? SpeedDialFAB(
        actions: [
          SpeedDialAction(
            icon: Icons.edit,
            label: 'New Post',
            heroTag: 'post',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
              if (res == true) _loadPosts();
            },
          ),
          SpeedDialAction(
            icon: Icons.chat_bubble_outline,
            label: 'Messages',
            heroTag: 'msg',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendsPostsScreen()),
            ),
          ),
          SpeedDialAction(
            icon: Icons.person_add,
            label: 'Add Friend',
            heroTag: 'addFriend',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const FriendsModal(),
            ),
          ),
        ],
      )
          : null,

      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
            ? _emptyState()
            : ListView.builder(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: 100,
          ),
          itemCount: _posts.length,
          itemBuilder: (context, i) => _postCard(i),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.people_outline,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
        ),
        const SizedBox(height: 16),
        const Text('No posts yet — share something positive!'),
      ],
    ),
  );

  Widget _postCard(int index) {
    final post = _posts[index];
    final showComments = post['showComments'] as bool;
    final imageUrl = post['image_url'];
    final comments = post['comments'] as List;

    if (!_commentControllers.containsKey(index)) {
      _commentControllers[index] = TextEditingController();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - REMOVED AUTHOR NAME (only timestamp)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  child: Text(post['avatar']),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatTimestamp(post['created_at']),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Title
          if (post['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                post['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(post['content']),
          ),

          // Image
          if (imageUrl != null && imageUrl.toString().isNotEmpty)
            Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: GestureDetector(
                onTap: () => _showFullImage(context, imageUrl),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleLike(post['id'], index),
                  icon: Icon(
                    post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                    color: post['isLiked'] ? Colors.red : null,
                  ),
                  label: Text('${post['likes']}'),
                ),
                TextButton.icon(
                  onPressed: () => _loadComments(index),
                  icon: Icon(
                    showComments ? Icons.comment : Icons.comment_outlined,
                  ),
                  label: const Text('Comment'),
                ),
                TextButton.icon(
                  onPressed: () => _sharePost(post),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),

          // Comments Section
          if (showComments)
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  if (post['isLoadingComments'])
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (comments.isEmpty)
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
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: comments.length,
                        itemBuilder: (context, i) {
                          final comment = comments[i];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                              child: Text(
                                comment['avatar'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            title: Text(
                              comment['content'],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              _formatTimestamp(comment['created_at']),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Comment Input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentControllers[index],
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
                            onTap: () => setState(() => _showFab = false),
                            onSubmitted: (_) {
                              _postComment(index);
                              setState(() => _showFab = true);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _postComment(index),
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}