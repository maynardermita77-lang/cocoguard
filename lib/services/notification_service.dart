import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Notification model for pest alerts
class PestNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String? pestType;
  final String? locationText;
  final int? scanId;
  final bool isRead;
  final DateTime createdAt;

  PestNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.pestType,
    this.locationText,
    this.scanId,
    required this.isRead,
    required this.createdAt,
  });

  factory PestNotification.fromJson(Map<String, dynamic> json) {
    return PestNotification(
      id: json['id'],
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type'] ?? 'pest_alert',
      pestType: json['pest_type'],
      locationText: json['location_text'],
      scanId: json['scan_id'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
    );
  }
}

/// Service for managing pest alert notifications
class NotificationService {
  /// ValueNotifier for unread notification count - UI can listen to this
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Cached notifications list
  static List<PestNotification> _notifications = [];
  static List<PestNotification> get notifications => _notifications;

  /// Fetch all notifications for the current user
  static Future<List<PestNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (unreadOnly) queryParams['unread_only'] = 'true';
      queryParams['limit'] = limit.toString();

      final url = Uri.parse(
        '${ApiService.baseUrl}/notifications',
      ).replace(queryParameters: queryParams);

      final response = await ApiService.get(
        url.toString().replaceFirst(ApiService.baseUrl, ''),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data
            .map((json) => PestNotification.fromJson(json))
            .toList();

        // Update unread count
        final unread = _notifications.where((n) => !n.isRead).length;
        unreadCount.value = unread;

        developer.log(
          'Fetched ${_notifications.length} notifications, $unread unread',
          name: 'NotificationService',
        );

        return _notifications;
      } else {
        developer.log(
          'Failed to fetch notifications: ${response.statusCode}',
          name: 'NotificationService',
        );
        return [];
      }
    } catch (e) {
      developer.log(
        'Error fetching notifications: $e',
        name: 'NotificationService',
      );
      return [];
    }
  }

  /// Get unread notification count from server
  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.get('/notifications/unread-count');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['unread_count'] ?? 0;
        unreadCount.value = count;
        return count;
      }
      return 0;
    } catch (e) {
      developer.log(
        'Error getting unread count: $e',
        name: 'NotificationService',
      );
      return 0;
    }
  }

  /// Mark specific notifications as read
  static Future<bool> markAsRead(List<int> notificationIds) async {
    try {
      final response = await ApiService.post('/notifications/mark-read', {
        'notification_ids': notificationIds,
      });

      if (response.statusCode == 200) {
        // Update local cache
        for (var notification in _notifications) {
          if (notificationIds.contains(notification.id)) {
            // Since PestNotification is immutable, we need to refresh from server
          }
        }
        // Refresh unread count
        await getUnreadCount();
        return true;
      }
      return false;
    } catch (e) {
      developer.log(
        'Error marking notifications as read: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final response = await ApiService.post(
        '/notifications/mark-all-read',
        {},
      );

      if (response.statusCode == 200) {
        unreadCount.value = 0;
        // Refresh notifications
        await getNotifications();
        return true;
      }
      return false;
    } catch (e) {
      developer.log(
        'Error marking all as read: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await ApiService.delete(
        '/notifications/$notificationId',
      );

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        await getUnreadCount();
        return true;
      }
      return false;
    } catch (e) {
      developer.log(
        'Error deleting notification: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  /// Refresh notifications - call this periodically or on app resume
  static Future<void> refresh() async {
    await getUnreadCount();
    await getNotifications();
  }

  /// Check if there are dangerous pest alerts (APW)
  static bool hasDangerousAlerts() {
    return _notifications.any(
      (n) =>
          !n.isRead &&
          n.pestType != null &&
          (n.pestType!.contains('APW') ||
              n.pestType!.toLowerCase().contains('asiatic')),
    );
  }
}
