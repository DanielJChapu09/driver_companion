import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import '../../../core/utils/logs.dart';
import '../model/notifcation_model.dart';
import '../model/user_location_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/push_notifcation_service.dart';


class CommunityController extends GetxController {
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final PushNotificationService _pushNotificationService = PushNotificationService();

  // Observable variables
  final Rx<UserLocation?> currentLocation = Rx<UserLocation?>(null);
  final RxList<RoadNotification> cityNotifications = <RoadNotification>[].obs;
  final RxList<RoadNotification> nearbyNotifications = <RoadNotification>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentCity = ''.obs;

  // Stream subscription for city notifications
  StreamSubscription<List<RoadNotification>>? _notificationSubscription;

  @override
  void onInit() {
    super.onInit();
    initializeServices();
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    super.onClose();
  }

  // Initialize all services
  Future<void> initializeServices() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Initialize push notification service
      await _pushNotificationService.initialize().catchError((e) {
        DevLogs.logWarning('Push notification initialization warning: $e');
        // Continue execution rather than failing the whole process
      });

      // Get current location
      await updateCurrentLocation().catchError((e) {
        DevLogs.logWarning('Location update warning: $e');
        // Continue execution
      });

      // Only proceed with city operations if location was obtained
      if (currentLocation.value != null) {
        try {
          await _pushNotificationService.subscribeToCity(currentLocation.value!.city);
          currentCity.value = currentLocation.value!.city;
          _listenToCityNotifications(currentLocation.value!.city);
        } catch (e) {
          DevLogs.logWarning('City subscription warning: $e');
          // Continue execution
        }
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Some services failed to initialize';
      DevLogs.logError('Error initializing services: $e');
    }
  }
  // Update current location
  Future<void> updateCurrentLocation() async {
    try {
      UserLocation location = await _locationService.getCurrentLocation();
      currentLocation.value = location;

      // If city has changed, update subscriptions
      if (currentCity.value != location.city) {
        if (currentCity.value.isNotEmpty) {
          await _pushNotificationService.unsubscribeFromCity(currentCity.value);
        }
        await _pushNotificationService.subscribeToCity(location.city);
        currentCity.value = location.city;

        // Update notifications for new city
        _listenToCityNotifications(location.city);
      }

      // Update nearby notifications
      await fetchNearbyNotifications();
    } catch (e) {
      errorMessage.value = 'Failed to update location: $e';
      DevLogs.logError('Error updating location: $e');
    }
  }

  // Listen to notifications for a specific city
  void _listenToCityNotifications(String city) {
    // Cancel previous subscription if exists
    _notificationSubscription?.cancel();

    // Subscribe to new city notifications
    _notificationSubscription = _notificationService
        .getNotificationsForCity(city)
        .listen((notifications) {
      cityNotifications.value = notifications;
    }, onError: (error) {
      errorMessage.value = 'Failed to get notifications: $error';
      DevLogs.logError('Error getting notifications: $error');
    });
  }

  // Fetch notifications near current location
  Future<void> fetchNearbyNotifications() async {
    if (currentLocation.value == null) return;

    try {
      List<RoadNotification> notifications = await _notificationService.getNotificationsNearLocation(
        currentLocation.value!.latitude,
        currentLocation.value!.longitude,
        10.0, // 10km radius
      );

      nearbyNotifications.value = notifications;
    } catch (e) {
      errorMessage.value = 'Failed to fetch nearby notifications: $e';
      DevLogs.logError('Error fetching nearby notifications: $e');
    }
  }

  // Create a new road notification
  Future<void> createRoadNotification({
    required String message,
    required String type,
    List<File> images = const [],
  }) async {
    if (currentLocation.value == null) {
      errorMessage.value = 'Location not available';
      return;
    }

    isSubmitting.value = true;
    errorMessage.value = '';

    try {
      // Create notification in database
      RoadNotification notification = await _notificationService.createRoadNotification(
        message: message,
        type: type,
        location: currentLocation.value!,
        images: images,
      );

      // Send push notification to users in the same city
      await _pushNotificationService.sendNotificationToCity(
        currentLocation.value!.city,
        'New Road Alert: ${notification.type}',
        notification.message,
        {
          'notificationId': notification.id,
          'type': notification.type,
          'latitude': notification.latitude.toString(),
          'longitude': notification.longitude.toString(),
        },
      );

      isSubmitting.value = false;

      // Add to local list if not already there
      if (!cityNotifications.any((n) => n.id == notification.id)) {
        cityNotifications.add(notification);
      }

      Get.snackbar(
        'Success',
        'Your road notification has been shared with other drivers',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      isSubmitting.value = false;
      errorMessage.value = 'Failed to create notification: $e';
      DevLogs.logError('Error creating notification: $e');

      Get.snackbar(
        'Error',
        'Failed to share your notification',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Like a notification
  Future<void> likeNotification(String notificationId) async {
    try {
      await _notificationService.likeNotification(notificationId);

      // Update local list
      int index = cityNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        RoadNotification notification = cityNotifications[index];
        cityNotifications[index] = notification.copyWith(
          likeCount: notification.likeCount + 1,
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to like notification: $e';
      DevLogs.logError('Error liking notification: $e');
    }
  }

  // Mark a notification as resolved
  Future<void> markNotificationAsResolved(String notificationId) async {
    try {
      await _notificationService.markNotificationAsInactive(notificationId);

      // Update local lists
      cityNotifications.removeWhere((n) => n.id == notificationId);
      nearbyNotifications.removeWhere((n) => n.id == notificationId);

      Get.snackbar(
        'Success',
        'Notification marked as resolved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'Failed to update notification: $e';
      DevLogs.logError('Error updating notification: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local lists
      cityNotifications.removeWhere((n) => n.id == notificationId);
      nearbyNotifications.removeWhere((n) => n.id == notificationId);

      Get.snackbar(
        'Success',
        'Notification deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'Failed to delete notification: $e';
      DevLogs.logError('Error deleting notification: $e');

      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

