// // lib/core/services/fcm_notification_service.dart
//
// import 'dart:convert';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:good_news/core/models/notification_models.dart';
// import 'package:good_news/core/services/preferences_service.dart';
// import 'package:good_news/core/services/api_service.dart';
//
// // ✅ Top-level background message handler (MUST be top-level or static)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print('📱 Background message received: ${message.messageId}');
//   print('📱 Data: ${message.data}');
//
//   // Handle notification data when app is in background
//   if (message.data.isNotEmpty) {
//     await FCMNotificationService._handleBackgroundNotification(message);
//   }
// }
//
// class FCMNotificationService {
//   static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//   FlutterLocalNotificationsPlugin();
//
//   static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
//   static bool _isInitialized = false;
//   static String? _fcmToken;
//
//   // ✅ Initialize FCM
//   static Future<void> initialize() async {
//     if (_isInitialized) {
//       print('⚠️ FCM already initialized');
//       return;
//     }
//
//     try {
//       print('🚀 Initializing FCM...');
//
//       // 1️⃣ Request permission
//       NotificationSettings settings = await _fcm.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         announcement: false,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//       );
//
//       print('✅ Notification permission: ${settings.authorizationStatus}');
//
//       if (settings.authorizationStatus != AuthorizationStatus.authorized) {
//         print('⚠️ Notification permission denied');
//         return;
//       }
//
//       // 2️⃣ Initialize local notifications
//       await _initializeLocalNotifications();
//
//       // 3️⃣ Get FCM token
//       _fcmToken = await _fcm.getToken();
//       print('✅ FCM Token: $_fcmToken');
//
//       if (_fcmToken != null) {
//         // Save token to backend
//         await _saveFCMTokenToBackend(_fcmToken!);
//       }
//
//       // 4️⃣ Set up background message handler
//       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//       // 5️⃣ Handle foreground messages
//       FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//
//       // 6️⃣ Handle notification tap when app is in background/terminated
//       FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
//
//       // 7️⃣ Check if app was opened from a notification
//       RemoteMessage? initialMessage = await _fcm.getInitialMessage();
//       if (initialMessage != null) {
//         print('📱 App opened from notification: ${initialMessage.messageId}');
//         _handleNotificationTap(initialMessage);
//       }
//
//       // 8️⃣ Listen for token refresh
//       _fcm.onTokenRefresh.listen((newToken) {
//         print('🔄 FCM Token refreshed: $newToken');
//         _fcmToken = newToken;
//         _saveFCMTokenToBackend(newToken);
//       });
//
//       _isInitialized = true;
//       print('✅ FCM initialized successfully');
//     } catch (e) {
//       print('❌ FCM initialization failed: $e');
//     }
//   }
//
//   // ✅ Initialize local notifications
//   static Future<void> _initializeLocalNotifications() async {
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _localNotifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _onLocalNotificationTap,
//     );
//
//     print('✅ Local notifications initialized');
//   }
//
//   // ✅ Handle foreground messages
//   static Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     print('📱 Foreground message received: ${message.notification?.title}');
//     print('📱 Data: ${message.data}');
//
//     // Show local notification when app is in foreground
//     if (message.notification != null) {
//       await _showLocalNotification(
//         title: message.notification!.title ?? 'Good News',
//         body: message.notification!.body ?? '',
//         data: message.data,
//       );
//     }
//   }
//
//   // ✅ Show local notification
//   static Future<void> _showLocalNotification({
//     required String title,
//     required String body,
//     required Map<String, dynamic> data,
//   }) async {
//     try {
//       const androidDetails = AndroidNotificationDetails(
//         'good_news_channel',
//         'Good News Notifications',
//         channelDescription: 'Notifications for Good News App',
//         importance: Importance.high,
//         priority: Priority.high,
//         icon: '@mipmap/ic_launcher',
//         playSound: true,
//         enableVibration: true,
//       );
//
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );
//
//       const details = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
//
//       await _localNotifications.show(
//         DateTime.now().millisecond,
//         title,
//         body,
//         details,
//         payload: jsonEncode(data),
//       );
//
//       print('✅ Local notification shown: $title');
//     } catch (e) {
//       print('❌ Failed to show local notification: $e');
//     }
//   }
//
//   // ✅ Handle notification tap (background/terminated)
//   static void _handleNotificationTap(RemoteMessage message) {
//     print('📱 Notification tapped: ${message.data}');
//     _navigateBasedOnNotification(message.data);
//   }
//
//   // ✅ Handle local notification tap
//   static void _onLocalNotificationTap(NotificationResponse response) {
//     print('📱 Local notification tapped: ${response.payload}');
//     if (response.payload != null) {
//       try {
//         final data = jsonDecode(response.payload!);
//         _navigateBasedOnNotification(data);
//       } catch (e) {
//         print('❌ Failed to parse notification payload: $e');
//       }
//     }
//   }
//
//   // ✅ Navigate based on notification type
//   static void _navigateBasedOnNotification(Map<String, dynamic> data) {
//     if (navigatorKey.currentContext == null) {
//       print('⚠️ No navigator context available');
//       return;
//     }
//
//     final type = data['type'] as String?;
//     print('🧭 Navigating for notification type: $type');
//
//     switch (type) {
//       case 'friend_request':
//         _navigateToFriendRequests();
//         break;
//       case 'friend_post':
//         _navigateToPost(data);
//         break;
//       case 'post_like':
//       case 'post_comment':
//         _navigateToOwnPost(data);
//         break;
//       default:
//         print('⚠️ Unknown notification type: $type');
//     }
//   }
//
//   // ✅ Navigate to friend requests screen
//   static void _navigateToFriendRequests() {
//     print('🧭 Navigating to Friend Requests');
//     navigatorKey.currentState?.pushNamed('/friend-requests');
//   }
//
//   // ✅ Navigate to friend's post
//   static void _navigateToPost(Map<String, dynamic> data) {
//     final postId = data['post_id'];
//     print('🧭 Navigating to post: $postId');
//
//     if (postId != null) {
//       navigatorKey.currentState?.pushNamed('/post-details', arguments: {'postId': postId});
//     }
//   }
//
//   // ✅ Navigate to user's own post
//   static void _navigateToOwnPost(Map<String, dynamic> data) {
//     final postId = data['post_id'];
//     print('🧭 Navigating to own post: $postId');
//
//     if (postId != null) {
//       navigatorKey.currentState?.pushNamed('/my-posts', arguments: {'postId': postId});
//     }
//   }
//
//   // ✅ Save FCM token to backend
//   static Future<void> _saveFCMTokenToBackend(String token) async {
//     try {
//       final userToken = await PreferencesService.getToken();
//       if (userToken == null) {
//         print('⚠️ User not logged in, cannot save FCM token');
//         return;
//       }
//
//       print('📤 Saving FCM token to backend...');
//
//       final response = await ApiService.authenticatedRequest(
//         '/user/fcm-token',
//         method: 'POST',
//         token: userToken,
//         data: {'fcm_token': token},
//       );
//
//       if (response['status'] == 'success') {
//         print('✅ FCM token saved to backend');
//       } else {
//         print('⚠️ Failed to save FCM token: ${response['error']}');
//       }
//     } catch (e) {
//       print('❌ Error saving FCM token: $e');
//     }
//   }
//
//   // ✅ Handle background notification (static method)
//   static Future<void> _handleBackgroundNotification(RemoteMessage message) async {
//     print('📱 Processing background notification: ${message.data}');
//     // You can add custom logic here (e.g., update local database)
//   }
//
//   // ✅ Get FCM token
//   static String? get fcmToken => _fcmToken;
//
//   // ✅ Delete FCM token (on logout)
//   static Future<void> deleteToken() async {
//     try {
//       await _fcm.deleteToken();
//       _fcmToken = null;
//       print('✅ FCM token deleted');
//     } catch (e) {
//       print('❌ Failed to delete FCM token: $e');
//     }
//   }
//
//   // ✅ Subscribe to topic (e.g., for friend posts)
//   static Future<void> subscribeToTopic(String topic) async {
//     try {
//       await _fcm.subscribeToTopic(topic);
//       print('✅ Subscribed to topic: $topic');
//     } catch (e) {
//       print('❌ Failed to subscribe to topic: $e');
//     }
//   }
//
//   // ✅ Unsubscribe from topic
//   static Future<void> unsubscribeFromTopic(String topic) async {
//     try {
//       await _fcm.unsubscribeFromTopic(topic);
//       print('✅ Unsubscribed from topic: $topic');
//     } catch (e) {
//       print('❌ Failed to unsubscribe from topic: $e');
//     }
//   }
// }