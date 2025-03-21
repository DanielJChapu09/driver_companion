import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../model/notifcation_model.dart';
import '../model/user_location_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  // Create a new road notification
  Future<RoadNotification> createRoadNotification({
    required String message,
    required String type,
    required UserLocation location,
    List<File> images = const [],
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload images if any
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _uploadImages(images);
      }

      final String notificationId = _uuid.v4();
      final RoadNotification notification = RoadNotification(
        id: notificationId,
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Anonymous Driver',
        message: message,
        city: location.city,
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now(),
        type: type,
        images: imageUrls,
      );

      // Save to Firestore
      await _firestore
          .collection('roadNotifications')
          .doc(notificationId)
          .set(notification.toJson());

      return notification;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> imageUrls = [];

    for (File image in images) {
      String fileName = '${_uuid.v4()}.jpg';
      Reference ref = _storage.ref().child('road_notifications/$fileName');

      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }

  // Get notifications for a specific city
  Stream<List<RoadNotification>> getNotificationsForCity(String city) {
    return _firestore
        .collection('roadNotifications')
        .where('city', isEqualTo: city)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoadNotification.fromJson(doc.data()))
          .toList();
    });
  }

  // Get notifications near a location (within a radius)
  Future<List<RoadNotification>> getNotificationsNearLocation(
      double latitude, double longitude, double radiusInKm) async {
    // Firestore doesn't support geospatial queries directly
    // So we'll fetch by city and then filter by distance

    // First, get all active notifications
    QuerySnapshot snapshot = await _firestore
        .collection('roadNotifications')
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .get();

    List<RoadNotification> allNotifications = snapshot.docs
        .map((doc) => RoadNotification.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Filter notifications by distance
    return allNotifications.where((notification) {
      // Calculate distance using the Haversine formula
      double lat1 = latitude;
      double lon1 = longitude;
      double lat2 = notification.latitude;
      double lon2 = notification.longitude;

      var p = 0.017453292519943295; // Math.PI / 180
      var c = cos;
      var a = 0.5 - c((lat2 - lat1) * p)/2 +
          c(lat1 * p) * c(lat2 * p) *
              (1 - c((lon2 - lon1) * p))/2;

      double distance = 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km

      return distance <= radiusInKm;
    }).toList();
  }

  // Like a notification
  Future<void> likeNotification(String notificationId) async {
    try {
      await _firestore.collection('roadNotifications').doc(notificationId).update({
        'likeCount': FieldValue.increment(1)
      });
    } catch (e) {
      throw Exception('Failed to like notification: $e');
    }
  }

  // Mark a notification as inactive (resolved)
  Future<void> markNotificationAsInactive(String notificationId) async {
    try {
      await _firestore.collection('roadNotifications').doc(notificationId).update({
        'isActive': false
      });
    } catch (e) {
      throw Exception('Failed to update notification status: $e');
    }
  }

  // Delete a notification (only by the creator)
  Future<void> deleteNotification(String notificationId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if the user is the creator
      DocumentSnapshot doc = await _firestore
          .collection('roadNotifications')
          .doc(notificationId)
          .get();

      if (!doc.exists) {
        throw Exception('Notification not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUser.uid) {
        throw Exception('You can only delete your own notifications');
      }

      // Delete the notification
      await _firestore.collection('roadNotifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}

