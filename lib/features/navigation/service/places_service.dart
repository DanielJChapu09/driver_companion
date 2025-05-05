import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:uuid/uuid.dart';
import '../model/place_model.dart';
import 'package:flutter/material.dart';

class PlacesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  // Get favorite places
  Future<List<Place>> getFavoritePlaces() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favoritePlaces')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Place.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      DevLogs.logError('Error getting favorite places: $e');
      return [];
    }
  }

  // Get recent places
  Future<List<Place>> getRecentPlaces() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('recentPlaces')
          .orderBy('lastVisited', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Place.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      DevLogs.logError('Error getting recent places: $e');
      return [];
    }
  }

  // Add place to favorites
  Future<bool> addFavoritePlace(Place place) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      String placeId = _uuid.v4();
      place = place.copyWith(id: placeId);

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favoritePlaces')
          .doc(placeId)
          .set(place.toJson());

      return true;
    } catch (e) {
      DevLogs.logError('Error adding favorite place: $e');
      return false;
    }
  }

  // Remove place from favorites
  Future<bool> removeFavoritePlace(String placeId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favoritePlaces')
          .doc(placeId)
          .delete();

      return true;
    } catch (e) {
      DevLogs.logError('Error removing favorite place: $e');
      return false;
    }
  }

  // Add place to recent places
  Future<bool> addRecentPlace(Place place) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Check if place already exists in recent places
      QuerySnapshot existingPlaces = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('recentPlaces')
          .where('latitude', isEqualTo: place.latitude)
          .where('longitude', isEqualTo: place.longitude)
          .get();

      if (existingPlaces.docs.isNotEmpty) {
        // Update existing place
        String placeId = existingPlaces.docs.first.id;
        Place existingPlace = Place.fromJson({
          ...existingPlaces.docs.first.data() as Map<String, dynamic>,
          'id': placeId
        });

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('recentPlaces')
            .doc(placeId)
            .update({
          'lastVisited': DateTime.now().toIso8601String(),
          'visitCount': existingPlace.visitCount + 1,
        });
      } else {
        // Add new place
        String placeId = _uuid.v4();
        place = place.copyWith(
          id: placeId,
          lastVisited: DateTime.now(),
          visitCount: 1,
        );

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('recentPlaces')
            .doc(placeId)
            .set(place.toJson());

        // Limit recent places to 20
        QuerySnapshot allRecentPlaces = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('recentPlaces')
            .orderBy('lastVisited', descending: true)
            .get();

        if (allRecentPlaces.docs.length > 20) {
          // Delete oldest places
          for (int i = 20; i < allRecentPlaces.docs.length; i++) {
            await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .collection('recentPlaces')
                .doc(allRecentPlaces.docs[i].id)
                .delete();
          }
        }
      }

      return true;
    } catch (e) {
      DevLogs.logError('Error adding recent place: $e');
      return false;
    }
  }

  // Clear recent places
  Future<bool> clearRecentPlaces() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('recentPlaces')
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      DevLogs.logError('Error clearing recent places: $e');
      return false;
    }
  }

  // Update place
  Future<bool> updatePlace(Place place) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favoritePlaces')
          .doc(place.id)
          .update(place.toJson());

      return true;
    } catch (e) {
      DevLogs.logError('Error updating place: $e');
      return false;
    }
  }

  // Get place categories
  List<Map<String, dynamic>> getPlaceCategories() {
    return [
      {'id': 'home', 'name': 'Home', 'icon': Icons.home},
      {'id': 'work', 'name': 'Work', 'icon': Icons.work},
      {'id': 'school', 'name': 'School', 'icon': Icons.school},
      {'id': 'restaurant', 'name': 'Restaurant', 'icon': Icons.restaurant},
      {'id': 'shopping', 'name': 'Shopping', 'icon': Icons.shopping_cart},
      {'id': 'gas', 'name': 'Gas Station', 'icon': Icons.local_gas_station},
      {'id': 'parking', 'name': 'Parking', 'icon': Icons.local_parking},
      {'id': 'hospital', 'name': 'Hospital', 'icon': Icons.local_hospital},
      {'id': 'gym', 'name': 'Gym', 'icon': Icons.fitness_center},
      {'id': 'entertainment', 'name': 'Entertainment', 'icon': Icons.movie},
      {'id': 'other', 'name': 'Other', 'icon': Icons.place},
    ];
  }
}
