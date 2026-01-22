// import 'package:flutter/material.dart';
//
// import '../../../../core/services/notification_service.dart';
//
// /// Notification Badge Widget with Auto-refresh
// class NotificationBadge extends StatefulWidget {
//   final Widget child;
//   final VoidCallback? onTap;
//   final Duration refreshInterval;
//
//   const NotificationBadge({
//     Key? key,
//     required this.child,
//     this.onTap,
//     this.refreshInterval = const Duration(minutes: 1),
//   }) : super(key: key);
//
//   @override
//   State<NotificationBadge> createState() => _NotificationBadgeState();
// }
//
// class _NotificationBadgeState extends State<NotificationBadge> {
//   int _unreadCount = 0;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUnreadCount();
//     _startAutoRefresh();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   void _startAutoRefresh() {
//     Future.doWhile(() async {
//       await Future.delayed(widget.refreshInterval);
//       if (mounted) {
//         await _loadUnreadCount();
//         return true;
//       }
//       return false;
//     });
//   }
//
//   Future<void> _loadUnreadCount() async {
//     if (_isLoading) return;
//
//     setState(() => _isLoading = true);
//     try {
//       final response = await NotificationApiService.getNotifications();
//       if (response['status'] == 'success' && mounted) {
//         setState(() {
//           _unreadCount = response['unread_count'] ?? 0;
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ Failed to load unread count: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         GestureDetector(
//           onTap: widget.onTap,
//           child: widget.child,
//         ),
//         if (_unreadCount > 0)
//           Positioned(
//             right: 0,
//             top: 0,
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: Theme.of(context).scaffoldBackgroundColor,
//                   width: 2,
//                 ),
//               ),
//               constraints: const BoxConstraints(
//                 minWidth: 18,
//                 minHeight: 18,
//               ),
//               child: Center(
//                 child: Text(
//                   _unreadCount > 99 ? '99+' : '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
//
// /// Simple usage example for AppBar
// class NotificationIconButton extends StatelessWidget {
//   final VoidCallback onPressed;
//
//   const NotificationIconButton({
//     Key? key,
//     required this.onPressed,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return NotificationBadge(
//       onTap: onPressed,
//       child: IconButton(
//         icon: const Icon(Icons.notifications_outlined),
//         onPressed: onPressed,
//         tooltip: 'Notifications',
//       ),
//     );
//   }
// }