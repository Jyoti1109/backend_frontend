// import 'package:flutter/material.dart';
// import 'package:timeago/timeago.dart' as timeago;
//
// import '../../../../core/services/notification_service.dart';
//
// class NotificationsScreen extends StatefulWidget {
//   const NotificationsScreen({Key? key}) : super(key: key);
//
//   @override
//   State<NotificationsScreen> createState() => _NotificationsScreenState();
// }
//
// class _NotificationsScreenState extends State<NotificationsScreen> {
//   List<Map<String, dynamic>> _notifications = [];
//   int _unreadCount = 0;
//   bool _isLoading = true;
//   bool _isRefreshing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadNotifications();
//   }
//
//   Future<void> _loadNotifications() async {
//     setState(() => _isLoading = true);
//     try {
//       final response = await NotificationApiService.getNotifications();
//       if (response['status'] == 'success' && mounted) {
//         setState(() {
//           _notifications = List<Map<String, dynamic>>.from(
//               response['notifications'] ?? []
//           );
//           _unreadCount = response['unread_count'] ?? 0;
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ Failed to load notifications: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _handleRefresh() async {
//     setState(() => _isRefreshing = true);
//     await _loadNotifications();
//     if (mounted) {
//       setState(() => _isRefreshing = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('✨ Notifications refreshed!'),
//           duration: Duration(seconds: 1),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }
//
//   Future<void> _markAsRead(int notificationId, int index) async {
//     final notification = _notifications[index];
//     if (notification['is_read'] == true) return;
//
//     // Optimistic update
//     setState(() {
//       _notifications[index]['is_read'] = true;
//       if (_unreadCount > 0) _unreadCount--;
//     });
//
//     try {
//       final response = await NotificationApiService.markNotificationRead(notificationId);
//       if (response['status'] != 'success' && mounted) {
//         // Rollback on failure
//         setState(() {
//           _notifications[index]['is_read'] = false;
//           _unreadCount++;
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ Failed to mark notification as read: $e');
//       if (mounted) {
//         setState(() {
//           _notifications[index]['is_read'] = false;
//           _unreadCount++;
//         });
//       }
//     }
//   }
//
//   Future<void> _markAllAsRead() async {
//     if (_unreadCount == 0) return;
//
//     // Optimistic update
//     final oldNotifications = List<Map<String, dynamic>>.from(_notifications);
//     final oldUnreadCount = _unreadCount;
//
//     setState(() {
//       for (var notification in _notifications) {
//         notification['is_read'] = true;
//       }
//       _unreadCount = 0;
//     });
//
//     try {
//       final response = await NotificationApiService.markAllNotificationsRead();
//       if (response['status'] == 'success' && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('✅ All notifications marked as read'),
//             duration: Duration(seconds: 2),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else if (mounted) {
//         // Rollback on failure
//         setState(() {
//           _notifications = oldNotifications;
//           _unreadCount = oldUnreadCount;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('❌ Failed to mark all as read'),
//             duration: Duration(seconds: 2),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint('❌ Failed to mark all as read: $e');
//       if (mounted) {
//         setState(() {
//           _notifications = oldNotifications;
//           _unreadCount = oldUnreadCount;
//         });
//       }
//     }
//   }
//
//   void _handleNotificationTap(Map<String, dynamic> notification, int index) {
//     _markAsRead(notification['id'], index);
//
//     final type = notification['type'];
//     final data = notification['data'] ?? {};
//
//     // Navigate based on notification type
//     switch (type) {
//       case 'friend_request':
//       // Navigate to friend requests screen
//         Navigator.pushNamed(context, '/friends');
//         break;
//       case 'post_like':
//       case 'post_comment':
//         final postId = data['post_id'];
//         if (postId != null) {
//           // Navigate to specific post
//           Navigator.pushNamed(
//             context,
//             '/post',
//             arguments: {'post_id': postId},
//           );
//         }
//         break;
//       case 'new_message':
//         final senderId = data['sender_id'];
//         if (senderId != null) {
//           // Navigate to chat with sender
//           Navigator.pushNamed(
//             context,
//             '/chat',
//             arguments: {'user_id': senderId},
//           );
//         }
//         break;
//       default:
//         debugPrint('Unknown notification type: $type');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const Text('Notifications'),
//             if (_unreadCount > 0) ...[
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//         actions: [
//           if (_unreadCount > 0)
//             IconButton(
//               icon: const Icon(Icons.done_all),
//               tooltip: 'Mark all as read',
//               onPressed: _markAllAsRead,
//             ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _handleRefresh,
//         color: Theme.of(context).colorScheme.primary,
//         child: _isLoading
//             ? Center(
//           child: CircularProgressIndicator(
//             color: Theme.of(context).colorScheme.primary,
//           ),
//         )
//             : _notifications.isEmpty
//             ? _buildEmptyState(isDark)
//             : ListView.builder(
//           physics: const AlwaysScrollableScrollPhysics(),
//           itemCount: _notifications.length,
//           itemBuilder: (context, index) {
//             final notification = _notifications[index];
//             return _buildNotificationItem(notification, index, isDark);
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNotificationItem(
//       Map<String, dynamic> notification,
//       int index,
//       bool isDark,
//       ) {
//     final isRead = notification['is_read'] == true;
//     final type = notification['type'] ?? '';
//     final title = notification['title'] ?? 'Notification';
//     final message = notification['message'] ?? '';
//     final createdAt = notification['created_at'];
//     final timeAgo = _formatTimeAgo(createdAt);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: isRead
//             ? Colors.transparent
//             : (isDark ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50),
//         border: Border(
//           bottom: BorderSide(
//             color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
//             width: 1,
//           ),
//         ),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: _buildNotificationIcon(type, isDark),
//         title: Text(
//           title,
//           style: TextStyle(
//             fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
//             fontSize: 15,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 4),
//             Text(
//               message,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               timeAgo,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
//               ),
//             ),
//           ],
//         ),
//         trailing: !isRead
//             ? Container(
//           width: 10,
//           height: 10,
//           decoration: const BoxDecoration(
//             color: Colors.blue,
//             shape: BoxShape.circle,
//           ),
//         )
//             : null,
//         onTap: () => _handleNotificationTap(notification, index),
//       ),
//     );
//   }
//
//   Widget _buildNotificationIcon(String type, bool isDark) {
//     IconData iconData;
//     Color iconColor;
//
//     switch (type) {
//       case 'friend_request':
//         iconData = Icons.person_add;
//         iconColor = Colors.blue;
//         break;
//       case 'post_like':
//         iconData = Icons.favorite;
//         iconColor = Colors.red;
//         break;
//       case 'post_comment':
//         iconData = Icons.comment;
//         iconColor = Colors.green;
//         break;
//       case 'new_message':
//         iconData = Icons.message;
//         iconColor = Colors.purple;
//         break;
//       default:
//         iconData = Icons.notifications;
//         iconColor = Colors.orange;
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: iconColor.withOpacity(0.1),
//         shape: BoxShape.circle,
//       ),
//       child: Icon(
//         iconData,
//         color: iconColor,
//         size: 24,
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(bool isDark) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.notifications_none,
//               size: 80,
//               color: isDark ? Colors.white38 : Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No notifications yet',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 color: isDark ? Colors.white70 : Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'When you get notifications, they\'ll show up here',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: isDark ? Colors.white54 : Colors.grey[500],
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatTimeAgo(String? timestamp) {
//     if (timestamp == null) return 'Just now';
//     try {
//       final dateTime = DateTime.parse(timestamp);
//       return timeago.format(dateTime, locale: 'en_short');
//     } catch (e) {
//       return 'Just now';
//     }
//   }
// }