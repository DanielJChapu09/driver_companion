import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mymaptest/core/utils/logs.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize the service
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      DevLogs.logSuccess('User granted permission');

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    } else {
      DevLogs.logError('User declined or has not accepted permission');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // Reference to user document
      final userDoc = _firestore.collection('users').doc(user.uid);

      // Check if document exists
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // Update existing document
        await userDoc.update({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document
        await userDoc.set({
          'fcmTokens': [token],
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'subscribedCities': [],
          'userId': user.uid,
          'email': user.email,
          // Add any other user fields you need
        });
      }
    }
  }

  // Subscribe to city topic for targeted notifications
  Future<void> subscribeToCity(String city) async {
    if (city.isNotEmpty) {
      // Remove spaces and special characters for topic name
      String formattedCity = city.replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      await _fcm.subscribeToTopic(formattedCity);

      // Update user's subscribed cities in Firestore
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'subscribedCities': FieldValue.arrayUnion([city]),
        });
      }
    }
  }

  // Unsubscribe from city topic
  Future<void> unsubscribeFromCity(String city) async {
    if (city.isNotEmpty) {
      String formattedCity = city.replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      await _fcm.unsubscribeFromTopic(formattedCity);

      // Update user's subscribed cities in Firestore
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'subscribedCities': FieldValue.arrayRemove([city]),
        });
      }
    }
  }

  // Send notification to users in a specific city
  Future<void> sendNotificationToCity(
      String city, String title, String body, Map<String, dynamic> data) async {
    try {
      // Format city name for topic
      String formattedCity = city.replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();

      // Prepare notification data
      Map<String, dynamic> message = {
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
        'topic': formattedCity,
      };

      // Use Cloud Functions to send the notification
      // This requires a Cloud Function to be set up
      await _firestore.collection('notifications').add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      DevLogs.logError('Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }

  // Show local notification
  void _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'driver_community_channel',
            'Driver Community Notifications',
            channelDescription: 'Notifications for road conditions and alerts',
            importance: Importance.high,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  DevLogs.logError("Handling a background message: ${message.messageId}");
}

