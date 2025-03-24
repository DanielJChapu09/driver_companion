import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mymaptest/core/utils/logs.dart';
import '../model/driving_event_model.dart';

enum HapticIntensity {
  light,
  medium,
  heavy
}

class FeedbackService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FlutterTts _flutterTts = FlutterTts();

  bool _initialized = false;
  bool _voiceFeedbackEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _notificationFeedbackEnabled = true;

  // Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize notifications
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      // Initialize text-to-speech
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _initialized = true;
    } catch (e) {
      DevLogs.logError('Error initializing feedback service: $e');
    }
  }

  // Set feedback preferences
  void setFeedbackPreferences({
    bool? voiceFeedback,
    bool? hapticFeedback,
    bool? notificationFeedback,
  }) {
    if (voiceFeedback != null) _voiceFeedbackEnabled = voiceFeedback;
    if (hapticFeedback != null) _hapticFeedbackEnabled = hapticFeedback;
    if (notificationFeedback != null) _notificationFeedbackEnabled = notificationFeedback;
  }

  // Provide haptic feedback
  Future<void> provideHapticFeedback({required HapticIntensity intensity}) async {
    if (!_hapticFeedbackEnabled) return;

    try {
      switch (intensity) {
        case HapticIntensity.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticIntensity.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticIntensity.heavy:
          await HapticFeedback.heavyImpact();
          break;
      }
    } catch (e) {
      DevLogs.logError('Error providing haptic feedback: $e');
    }
  }

  // Speak a message
  Future<void> speakMessage(String message) async {
    if (!_voiceFeedbackEnabled) return;

    try {
      await _flutterTts.speak(message);
    } catch (e) {
      DevLogs.logError('Error speaking message: $e');
    }
  }

  // Show a notification
  Future<void> showNotification({
    required String title,
    required String message,
    required EventSeverity severity,
  }) async {
    if (!_notificationFeedbackEnabled) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'driver_behavior_channel',
        'Driver Behavior',
        channelDescription: 'Driver behavior alerts and notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        message,
        notificationDetails,
      );
    } catch (e) {
      DevLogs.logError('Error showing notification: $e');
    }
  }

  // Stop all speech
  Future<void> stopSpeech() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      DevLogs.logError('Error stopping speech: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}

