import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'logs.dart';

/// A utility class for caching and retrieving application data using
/// `SharedPreferences`. This class provides methods to manage onboarding status,
/// properties, and municipalities.
class CacheUtils {
  /// Key for storing onboarding status in the cache.
  static const _onboardingCacheKey = 'hasSeenOnboarding';

  /// Key for storing in app tutorial status in the cache.
  static const _hasSeenTutorialCacheKey = 'hasSeenOnboarding';


  // --- Onboarding Methods ---

  /// Checks if the user has completed onboarding.
  ///
  /// This method retrieves the onboarding status from the cache. If no value is
  /// stored, it defaults to `false`.
  ///
  /// Returns:
  /// - `true` if the user has completed onboarding.
  /// - `false` otherwise or in case of an error.
  static Future<bool> checkOnBoardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCacheKey) ?? false;
    } catch (e) {
      DevLogs.logError('Error checking onboarding status: $e');
      return false;
    }
  }

  static Future<bool> checkTutorialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenTutorialCacheKey) ?? false;
    } catch (e) {
      DevLogs.logError('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Updates the onboarding status in the cache.
  ///
  /// Parameters:
  /// - [status]: The new onboarding status to save (`true` for completed).
  ///
  /// Returns:
  /// - `true` if the status was successfully updated.
  /// - `false` otherwise or in case of an error.
  static Future<bool> updateOnboardingStatus(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCacheKey, status);
      return prefs.getBool(_onboardingCacheKey) ?? false;
    } catch (e) {
      DevLogs.logError('Error updating tutorial status: $e');
      return false;
    }
  }

  static Future<bool> updateHasSeenTutorialStatus(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenTutorialCacheKey, status);
      return prefs.getBool(_hasSeenTutorialCacheKey) ?? false;
    } catch (e) {
      DevLogs.logError('Error updating tutorial status: $e');
      return false;
    }
  }

}