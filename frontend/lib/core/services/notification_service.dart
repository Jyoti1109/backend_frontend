import 'package:flutter/material.dart';

enum NotificationType { success, error, info, warning }

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
  GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;

  static void showToast({
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
              semanticLabel: _getSemanticLabel(type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        )
            : null,
      ),
    );
  }

  static void showSuccess(String message) {
    showToast(message: message, type: NotificationType.success);
  }

  static void showError(String message) {
    showToast(message: message, type: NotificationType.error);
  }

  static void showInfo(String message) {
    showToast(message: message, type: NotificationType.info);
  }

  static void showWarning(String message) {
    showToast(message: message, type: NotificationType.warning);
  }

  static void showMessageNotification({
    required String senderName,
    required String message,
    VoidCallback? onTap,
  }) {
    showToast(
      message: '$senderName: ${message.length > 30 ? '${message.substring(0, 30)}...' : message}',
      type: NotificationType.info,
      duration: const Duration(seconds: 4),
      actionLabel: 'Reply',
      onAction: onTap,
    );
  }

  static void showPostNotification({
    required String type, // 'like' or 'comment'
    required String userName,
    VoidCallback? onTap,
  }) {
    final message = type == 'like'
        ? '$userName liked your post'
        : '$userName commented on your post';

    showToast(
      message: message,
      type: NotificationType.success,
      duration: const Duration(seconds: 4),
      actionLabel: 'View',
      onAction: onTap,
    );
  }

  static Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50);
      case NotificationType.error:
        return const Color(0xFFF44336);
      case NotificationType.warning:
        return const Color(0xFFFF9800);
      case NotificationType.info:
        return const Color(0xFF2196F3);
    }
  }

  static IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  static String _getSemanticLabel(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return 'Success notification';
      case NotificationType.error:
        return 'Error notification';
      case NotificationType.warning:
        return 'Warning notification';
      case NotificationType.info:
        return 'Information notification';
    }
  }
}