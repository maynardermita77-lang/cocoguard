import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Top-level function for background message handling (required by Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log(
    'Handling background message: ${message.messageId}',
    name: 'PushNotification',
  );
  // NOTE: Do NOT show local notification here!
  // When app is in background and FCM message has a 'notification' payload,
  // Android automatically displays the notification.
  // Calling _showLocalNotification here would cause DUPLICATE notifications.
  //
  // This handler is only for processing data payloads or updating app state.
  // The notification is already shown by the system.
}

/// Service for handling push notifications (FCM)
/// Displays notifications at the top of the screen like Messenger/NDRRMC alerts
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Notification channel for Android (high importance for heads-up display)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pest_alerts_channel', // id
    'Pest Alerts', // name
    description: 'Critical pest detection alerts for coconut farmers',
    importance: Importance.max, // Ensures heads-up notification
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Callback when notification is tapped
  static Function(String? payload)? onNotificationTapped;

  /// Initialize push notification service
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      developer.log('Firebase initialized', name: 'PushNotification');

      // Request notification permissions
      await _requestPermissions();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Create notification channel for Android
      await _createNotificationChannel();

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get and register FCM token
      await _registerToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      developer.log(
        'Push notification service initialized successfully',
        name: 'PushNotification',
      );
    } catch (e) {
      developer.log(
        'Failed to initialize push notifications: $e',
        name: 'PushNotification',
      );
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true, // For emergency-like alerts
      provisional: false,
      sound: true,
    );

    developer.log(
      'Permission status: ${settings.authorizationStatus}',
      name: 'PushNotification',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted permission', name: 'PushNotification');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      developer.log(
        'User granted provisional permission',
        name: 'PushNotification',
      );
    } else {
      developer.log('User declined permission', name: 'PushNotification');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // App icon
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        developer.log(
          'Notification tapped: ${response.payload}',
          name: 'PushNotification',
        );
        if (onNotificationTapped != null) {
          onNotificationTapped!(response.payload);
        }
      },
    );

    developer.log('Local notifications initialized', name: 'PushNotification');
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    developer.log(
      'Notification channel created: ${_channel.id}',
      name: 'PushNotification',
    );
  }

  /// Handle foreground messages - show as heads-up notification
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    developer.log(
      'Foreground message received: ${message.messageId}',
      name: 'PushNotification',
    );

    await _showLocalNotification(message);
  }

  /// Show local notification (heads-up style)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Determine if this is a critical pest alert
    final bool isCritical =
        data['pest_type']?.contains('APW') == true ||
        data['is_critical'] == 'true';

    // Build notification title and body
    String title = notification?.title ?? data['title'] ?? '⚠️ Pest Alert!';
    String body =
        notification?.body ??
        data['message'] ??
        'A dangerous pest has been detected in your area.';

    // Android notification details - heads-up display
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      visibility: NotificationVisibility.public,
      category: isCritical
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.message,
      fullScreenIntent: isCritical, // Shows even on lock screen for critical
      ticker: title,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        summaryText: data['location_text'] ?? 'CocoGuard Alert',
      ),
      // Visual styling
      color: isCritical ? const Color(0xFFDC3545) : const Color(0xFF2D7A3E),
      colorized: true,
      // Sound and vibration
      playSound: true,
      enableVibration: true,
      vibrationPattern: isCritical
          ? Int64List.fromList([
              0,
              500,
              200,
              500,
              200,
              500,
            ]) // Emergency pattern
          : Int64List.fromList([0, 250, 250, 250]),
      // Actions
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_details',
          '📋 View Details',
          showsUserInterface: true,
        ),
        if (isCritical)
          const AndroidNotificationAction(
            'emergency_contact',
            '📞 Contact PCA',
            showsUserInterface: true,
          ),
      ],
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload for navigation when tapped
    final payload = jsonEncode({
      'type': 'pest_alert',
      'scan_id': data['scan_id'],
      'pest_type': data['pest_type'],
      'notification_id': data['notification_id'],
    });

    // Show the notification
    await _localNotifications.show(
      message.hashCode, // Unique ID
      title,
      body,
      details,
      payload: payload,
    );

    developer.log(
      'Local notification displayed: $title',
      name: 'PushNotification',
    );
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    developer.log(
      'Notification tapped: ${message.messageId}',
      name: 'PushNotification',
    );

    final payload = jsonEncode(message.data);
    if (onNotificationTapped != null) {
      onNotificationTapped!(payload);
    }
  }

  /// Get and register FCM token with backend
  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        developer.log('FCM Token: $token', name: 'PushNotification');
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      developer.log('Failed to get FCM token: $e', name: 'PushNotification');
    }
  }

  /// Handle token refresh
  static Future<void> _onTokenRefresh(String token) async {
    developer.log('FCM Token refreshed: $token', name: 'PushNotification');
    await _saveTokenToBackend(token);
  }

  /// Save FCM token to backend
  static Future<void> _saveTokenToBackend(String token) async {
    try {
      // Store locally first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // Send to backend if user is logged in
      final authToken = ApiService.getToken();
      if (authToken != null) {
        final response = await ApiService.post('/users/fcm-token', {
          'fcm_token': token,
        });

        if (response.statusCode == 200) {
          developer.log(
            'FCM token registered with backend',
            name: 'PushNotification',
          );
        } else {
          developer.log(
            'Failed to register FCM token: ${response.statusCode}',
            name: 'PushNotification',
          );
        }
      } else {
        developer.log(
          'User not logged in, FCM token stored locally',
          name: 'PushNotification',
        );
      }
    } catch (e) {
      developer.log(
        'Error saving FCM token to backend: $e',
        name: 'PushNotification',
      );
    }
  }

  /// Re-register token after user login
  static Future<void> registerTokenAfterLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        await _saveTokenToBackend(token);
      } else {
        await _registerToken();
      }
    } catch (e) {
      developer.log(
        'Error registering token after login: $e',
        name: 'PushNotification',
      );
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'PushNotification');
      return null;
    }
  }

  /// Subscribe to topic (e.g., 'pest_alerts' for all users)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'PushNotification');
    } catch (e) {
      developer.log('Error subscribing to topic: $e', name: 'PushNotification');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      developer.log(
        'Unsubscribed from topic: $topic',
        name: 'PushNotification',
      );
    } catch (e) {
      developer.log(
        'Error unsubscribing from topic: $e',
        name: 'PushNotification',
      );
    }
  }

  /// Show a test notification (for debugging)
  static Future<void> showTestNotification() async {
    final testMessage = RemoteMessage(
      messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      notification: const RemoteNotification(
        title: '⚠️ Mapanganib na Peste ang Natuklasan!',
        body:
            'Ang Asiatic Palm Weevil (APW Adult) ay natuklasan sa inyong lugar. Mangyaring mag-ingat at suriin ang inyong mga puno ng niyog.',
      ),
      data: {
        'type': 'pest_alert',
        'pest_type': 'APW Adult',
        'is_critical': 'true',
        'location_text': 'Brgy. Sample, Municipality, Province',
        'scan_id': '123',
      },
    );

    await _showLocalNotification(testMessage);
  }
}
