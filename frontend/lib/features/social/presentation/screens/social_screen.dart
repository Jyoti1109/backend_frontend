// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:good_news/core/utils/responsive_helper.dart';
// import 'package:good_news/core/services/social_api_service.dart';
// import 'package:good_news/features/social/presentation/screens/create_post_screen.dart';
// import 'package:good_news/features/social/presentation/screens/messages_screen.dart';
// import 'package:good_news/features/social/presentation/screens/friends_modal.dart';
// import 'package:good_news/features/social/presentation/screens/friend_requests_screen.dart';
// import 'package:good_news/widgets/speed_dial_fab.dart';
//
// import '../../../../core/services/preferences_service.dart';
// import 'package:share_plus/share_plus.dart';
//
// class SocialScreen extends StatefulWidget {
//   const SocialScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SocialScreen> createState() => _SocialScreenState();
// }
//
// class _SocialScreenState extends State<SocialScreen> {
//   List<Map<String, dynamic>> _friendPosts = [];
//   bool _isLoading = true;
//   bool _hasMore = false;
//   int _totalCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadFriendPosts();
//   }
//
//   Future<void> _loadFriendPosts() async {
//     setState(() => _isLoading = true);
//
//     try {
//       final response = await SocialApiService.getPosts();
//
//       if (response['status'] == 'success') {
//         final postsList = response['posts'] as List;
//
//         setState(() {
//           _friendPosts = postsList.map((post) {
//             final authorName = post['display_name'] ?? 'Unknown';
//             return {
//               'id': post['id']?.toString() ?? '0',
//               'author': authorName,
//               'avatar': authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
//               'title': post['title'] ?? '',
//               'content': post['content'] ?? '',
//               'timestamp': _formatTimestamp(post['created_at']),
//               'likes': post['likes_count'] ?? 0,
//               'isLiked': post['is_liked'] ?? false,
//               'comments': <Map<String, dynamic>>[],
//               'showComments': false,
//               'isMyPost': false,
//               'user_id': post['user_id'],
//               'user_email': authorName,
//             };
//           }).toList();
//
//           _hasMore = response['has_more'] ?? false;
//           _totalCount = response['total_count'] ?? _friendPosts.length;
//           _isLoading = false;
//         });
//       } else {
//         throw Exception(response['error'] ?? 'Failed to load posts');
//       }
//     } catch (e) {
//       setState(() {
//         _friendPosts = [];
//         _isLoading = false;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to load posts: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           action: SnackBarAction(
//             label: 'Retry',
//             onPressed: _loadFriendPosts,
//           ),
//         ),
//       );
//     }
//   }
//
//
//
//   String _formatTimestamp(String? timestamp) {
//     if (timestamp == null) return 'Just now';
//     try {
//       final dateTime = HttpDate.parse(timestamp); // handles "Mon, 29 Sep 2025 ..."
//       final now = DateTime.now();
//       final difference = now.difference(dateTime);
//       if (difference.inMinutes < 60) {
//         return '${difference.inMinutes} minutes ago';
//       } else if (difference.inHours < 24) {
//         return '${difference.inHours} hours ago';
//       } else {
//         return '${difference.inDays} days ago';
//       }
//     } catch (e) {
//       return 'Just now';
//     }
//   }
//
//   // 👇 NEW: Load comments for a post
//   Future<void> _loadCommentsForPost(int postIndex) async {
//     final post = _friendPosts[postIndex];
//     final postId = int.parse(post['id']);
//
//     // If already loaded, just toggle visibility
//     if ((post['comments'] as List).isNotEmpty) {
//       _toggleCommentsVisibility(postIndex);
//       return;
//     }
//
//     try {
//       final response = await SocialApiService.getComments(postId);
//       if (response['status'] == 'success') {
//         final rawComments = response['comments'] as List;
//         final formattedComments = rawComments.map((comment) {
//           final authorEmail = comment['author_email'] ?? comment['user_email'] ?? 'Anonymous';
//           return {
//             'id': comment['id'],
//             'author': authorEmail,
//             'avatar': authorEmail.isNotEmpty ? authorEmail[0].toUpperCase() : 'A',
//             'content': comment['content'] ?? '',
//             'timestamp': _formatTimestamp(comment['created_at']),
//           };
//         }).toList();
//
//         setState(() {
//           _friendPosts[postIndex]['comments'] = formattedComments;
//           _friendPosts[postIndex]['showComments'] = true;
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load comments: ${response['error']}')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   void _toggleCommentsVisibility(int postIndex) {
//     setState(() {
//       _friendPosts[postIndex]['showComments'] = !_friendPosts[postIndex]['showComments'];
//     });
//   }
//
//   // 👇 NEW: Post a new comment
//   Future<void> _postComment(int postIndex) async {
//     final post = _friendPosts[postIndex];
//     final postId = int.parse(post['id']);
//     final controller = TextEditingController();
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Add Comment'),
//           content: TextField(
//             controller: controller,
//             decoration: const InputDecoration(hintText: 'Write a comment...'),
//             maxLines: 3,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final content = controller.text.trim();
//                 if (content.isEmpty) {
//                   Navigator.pop(context);
//                   return;
//                 }
//                 Navigator.pop(context); // Close dialog
//
//                 // Show loading snackbar (optional)
//                 final snackBar = SnackBar(
//                   content: const Row(
//                     children: [
//                       SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       SizedBox(width: 8),
//                       Text('Posting comment...'),
//                     ],
//                   ),
//                   duration: const Duration(seconds: 2),
//                 );
//                 ScaffoldMessenger.of(context).showSnackBar(snackBar);
//
//                 final response = await SocialApiService.createComment(postId, content);
//                 if (response['status'] == 'success') {
//                   // Get user email
//                   String? userEmail;
//                   try {
//                     userEmail = await PreferencesService.getUserEmail();
//                   } catch (e) {
//                     userEmail = 'Me';
//                   }
//
//                   final newComment = {
//                     'id': DateTime.now().millisecondsSinceEpoch,
//                     'author': userEmail ?? 'Me',
//                     'avatar': (userEmail ?? 'M').isNotEmpty ? (userEmail ?? 'M')[0].toUpperCase() : 'M',
//                     'content': content,
//                     'timestamp': 'Just now',
//                   };
//
//                   setState(() {
//                     final currentComments = List<Map<String, dynamic>>.from(post['comments']);
//                     currentComments.add(newComment);
//                     _friendPosts[postIndex]['comments'] = currentComments;
//                     _friendPosts[postIndex]['showComments'] = true;
//                   });
//
//                   // ✅ Show SUCCESS SnackBar
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('✅ Comment added!'),
//                       backgroundColor: Colors.green,
//                       duration: Duration(seconds: 1),
//                     ),
//                   );
//                 } else {
//                   // ❌ Show ERROR SnackBar
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('❌ Failed: ${response['error']}'),
//                       backgroundColor: Colors.red,
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 }
//               },
//               child: const Text('Post'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: Text('Social Feed ${_totalCount > 0 ? '($_totalCount)' : ''}'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person_add_outlined, size: 24),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const FriendRequestsScreen(),
//                 ),
//               );
//             },
//             tooltip: 'Friend Requests',
//           ),
//           IconButton(
//             icon: Stack(
//               children: [
//                 const Icon(Icons.notifications_outlined, size: 24),
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   child: Container(
//                     width: 8,
//                     height: 8,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.primary,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             onPressed: () {},
//             tooltip: 'Notifications',
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       floatingActionButton: SpeedDialFAB(
//         actions: [
//           SpeedDialAction(
//             icon: Icons.edit,
//             label: 'New Post',
//             semanticLabel: 'Create new post',
//             heroTag: 'fab_new_post', // ✅ unique heroTag
//             onPressed: () async {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const CreatePostScreen()),
//               );
//               if (result == true) {
//                 _loadFriendPosts();
//               }
//             },
//           ),
//           SpeedDialAction(
//             icon: Icons.chat_bubble_outline,
//             label: 'New Message',
//             semanticLabel: 'Start new message',
//             heroTag: 'fab_new_message', // ✅ unique heroTag
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const MessagesScreen()),
//               );
//             },
//           ),
//           SpeedDialAction(
//             icon: Icons.person_add,
//             label: 'Add Friend',
//             semanticLabel: 'Add new friend',
//             heroTag: 'fab_add_friend', // ✅ unique heroTag
//             onPressed: () {
//               showModalBottomSheet(
//                 context: context,
//                 isScrollControlled: true,
//                 backgroundColor: Colors.transparent,
//                 builder: (context) => const FriendSearchScreen(),
//               );
//             },
//           ),
//         ],
//       ),
//
//       body: RefreshIndicator(
//         onRefresh: _loadFriendPosts,
//         color: Theme.of(context).colorScheme.primary,
//         child: _isLoading
//             ? const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Loading posts...'),
//             ],
//           ),
//         )
//             : _friendPosts.isEmpty
//             ? _buildEmptyState()
//             : _buildPostsList(),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.people_outline,
//             size: 80,
//             color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No posts yet — share something positive today!',
//             style: Theme.of(context).textTheme.bodyLarge,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () async {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const CreatePostScreen()),
//               );
//               if (result == true) {
//                 _loadFriendPosts();
//               }
//             },
//             icon: const Icon(Icons.add, size: 20),
//             label: const Text('Create Post'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).colorScheme.primary,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(24),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextButton(
//             onPressed: _loadFriendPosts,
//             child: const Text('Refresh'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPostsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       itemCount: _friendPosts.length + (_hasMore ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index >= _friendPosts.length) {
//           return const Padding(
//             padding: EdgeInsets.all(16),
//             child: Center(
//               child: Text('Load more posts coming soon...'),
//             ),
//           );
//         }
//
//         final post = _friendPosts[index];
//         return Center(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               maxWidth: ResponsiveHelper.getResponsiveCardWidth(context),
//             ),
//             child: _buildPostCard(post, index),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildPostCard(Map<String, dynamic> post, int index) {
//     final comments = post['comments'] as List;
//     final showComments = post['showComments'] as bool;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 20,
//                   backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
//                   child: Text(
//                     post['avatar'],
//                     style: TextStyle(
//                       color: Theme.of(context).colorScheme.primary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         post['author'],
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Text(
//                         post['timestamp'],
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.outline,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '#${post['id']}',
//                     style: TextStyle(
//                       color: Theme.of(context).colorScheme.primary,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Title
//           if (post['title'] != null && post['title'].toString().isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//               child: Text(
//                 post['title'],
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//
//           // Content
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             child: Text(
//               post['content'],
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//           ),
//
//           // Actions
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextButton.icon(
//                     onPressed: () => _toggleLike(index),
//                     icon: Icon(
//                       post['isLiked'] ? Icons.favorite : Icons.favorite_border,
//                       color: post['isLiked'] ? Colors.red : null,
//                       size: 16,
//                     ),
//                     label: Text('${post['likes']}'),
//                   ),
//                 ),
//                 Expanded(
//                   child: TextButton.icon(
//                     onPressed: () => _loadCommentsForPost(index),
//                     icon: const Icon(Icons.comment_outlined, size: 16),
//                     label: Text('${comments.length}'),
//                   ),
//                 ),
//                 Expanded(
//                   child: TextButton.icon(
//                     onPressed: () {
//                       final post = _friendPosts[index];
//                       final author = post['author'];
//                       final content = post['content'];
//                       final title = post['title'] ?? '';
//                       final timestamp = post['timestamp'];
//
//                       // Build shareable text
//                       final shareText = '''
//                         "${content}"
//
//                         — ${author}
//                         ${title.isNotEmpty ? 'Post: $title' : ''}
//                         Shared via Good News App
//                         '''.trim();
//
//                       // Optional: you can also generate a deep link if you have post URLs
//                       // String? postUrl = 'https://yourapp.com/post/${post['id']}';
//
//                       Share.share(shareText);
//                     },
//                     icon: const Icon(Icons.share_outlined, size: 16),
//                     label: const Text('Share'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // 👇 NEW: Comments Section
//           if (showComments)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Divider(height: 1),
//                   const SizedBox(height: 8),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: TextButton(
//                       onPressed: () => _postComment(index),
//                       child: const Text('Add Comment', style: TextStyle(fontSize: 12)),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ...List.generate(
//                     comments.length,
//                         (i) {
//                       final comment = comments[i];
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 12),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             CircleAvatar(
//                               radius: 12,
//                               backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
//                               child: Text(
//                                 comment['avatar'],
//                                 style: TextStyle(
//                                   color: Theme.of(context).colorScheme.primary,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   RichText(
//                                     text: TextSpan(
//                                       children: [
//                                         TextSpan(
//                                           text: '${comment['author']}: ',
//                                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//                                         ),
//                                         TextSpan(
//                                           text: comment['content'],
//                                           style: const TextStyle(fontSize: 13),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 2),
//                                   Text(
//                                     comment['timestamp'],
//                                     style: TextStyle(
//                                       color: Theme.of(context).colorScheme.outline,
//                                       fontSize: 11,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                   if (comments.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.all(8),
//                       child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.grey)),
//                     ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _toggleLike(int index) async {
//     final post = _friendPosts[index];
//     final postId = int.parse(post['id']);
//
//     // Show loading indicator (optional)
//     final snackBar = SnackBar(
//       content: Row(
//         children: [
//           SizedBox(
//             height: 20,
//             width: 20,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//           const SizedBox(width: 8),
//           const Text('Liking...'),
//         ],
//       ),
//       duration: const Duration(seconds: 2),
//     );
//     // ScaffoldMessenger.of(context).showSnackBar(snackBar);
//
//     // Optimistically update UI
//     setState(() {
//       post['isLiked'] = !post['isLiked'];
//       if (post['isLiked']) {
//         post['likes']++;
//       } else {
//         post['likes']--;
//       }
//     });
//
//     try {
//       final response = await SocialApiService.likePost(postId);
//
//       if (response['status'] == 'success') {
//         // Keep UI as is (already updated optimistically)
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('✅ Post liked!'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 1),
//           ),
//         );
//       } else {
//         // Revert UI
//         setState(() {
//           post['isLiked'] = !post['isLiked'];
//           if (post['isLiked']) {
//             post['likes']++;
//           } else {
//             post['likes']--;
//           }
//         });
//
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Failed: ${response['error'] ?? 'Unknown error'}'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       // Revert UI on error
//       setState(() {
//         post['isLiked'] = !post['isLiked'];
//         if (post['isLiked']) {
//           post['likes']++;
//         } else {
//           post['likes']--;
//         }
//       });
//
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Network error: $e'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
// }