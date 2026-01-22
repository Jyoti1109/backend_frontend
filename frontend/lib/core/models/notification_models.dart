// lib/core/models/notification_models.dart

enum NotificationType {
  friendRequest,
  friendPost,
  postLike,
  postComment,
  general,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: _parseNotificationType(json['type']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] ?? {},
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'friend_request':
        return NotificationType.friendRequest;
      case 'friend_post':
        return NotificationType.friendPost;
      case 'post_like':
        return NotificationType.postLike;
      case 'post_comment':
        return NotificationType.postComment;
      default:
        return NotificationType.general;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class FriendRequestNotificationData {
  final int requestId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;

  FriendRequestNotificationData({
    required this.requestId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
  });

  factory FriendRequestNotificationData.fromJson(Map<String, dynamic> json) {
    return FriendRequestNotificationData(
      requestId: int.parse(json['request_id']?.toString() ?? '0'),
      senderId: int.parse(json['sender_id']?.toString() ?? '0'),
      senderName: json['sender_name'] ?? 'Someone',
      senderAvatar: json['sender_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId.toString(),
      'sender_id': senderId.toString(),
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
    };
  }
}

class PostNotificationData {
  final int postId;
  final int authorId;
  final String authorName;
  final String? postTitle;
  final String? actionUserName; // For likes/comments

  PostNotificationData({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.postTitle,
    this.actionUserName,
  });

  factory PostNotificationData.fromJson(Map<String, dynamic> json) {
    return PostNotificationData(
      postId: int.parse(json['post_id']?.toString() ?? '0'),
      authorId: int.parse(json['author_id']?.toString() ?? '0'),
      authorName: json['author_name'] ?? 'Someone',
      postTitle: json['post_title'],
      actionUserName: json['action_user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId.toString(),
      'author_id': authorId.toString(),
      'author_name': authorName,
      'post_title': postTitle,
      'action_user_name': actionUserName,
    };
  }
}