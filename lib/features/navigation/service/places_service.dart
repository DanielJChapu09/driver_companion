import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../model/place_model.dart';

class PlacesService {
  static const String _favoritePlacesKey = 'favorite_places';
  static const String _recentPlacesKey = 'recent_places';
  final Uuid _uuid = Uuid();

  // Get all favorite places
  Future<List<Place>> getFavoritePlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? placesJson = prefs.getString(_favoritePlacesKey);

      if (placesJson == null) {
        return [];
      }

      List<dynamic> placesList = jsonDecode(placesJson);
      return placesList.map((place) => Place.fromJson(place)).toList();
    } catch (e) {
      print('Error getting favorite places: $e');
      return [];
    }
  }

  // Get all recent places
  Future<List<Place>> getRecentPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? placesJson = prefs.getString(_recentPlacesKey);

      if (placesJson == null) {
        return [];
      }

      List<dynamic> placesList = jsonDecode(placesJson);
      return placesList.map((place) => Place.fromJson(place)).toList();
    } catch (e) {
      print('Error getting recent places: $e');
      return [];
    }
  }

  // Add a place to favorites
  Future<bool> addFavoritePlace(Place place) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Place> places = await getFavoritePlaces();

      // Check if place already exists
      int existingIndex = places.indexWhere((p) =>
      p.latitude == place.latitude && p.longitude == place.longitude);

      if (existingIndex != -1) {
        // Update existing place
        places[existingIndex] = place.copyWith(isFavorite: true);
      } else {
        // Add new place with a unique ID
        places.add(place.copyWith(
            id: place.id.isEmpty ? _uuid.v4() : place.id,
            isFavorite: true
        ));
      }

      // Save updated list
      final String placesJson = jsonEncode(places.map((p) => p.toJson()).toList());
      await prefs.setString(_favoritePlacesKey, placesJson);

      return true;
    } catch (e) {
      print('Error adding favorite place: $e');
      return false;
    }
  }

  // Remove a place from favorites
  Future<bool> removeFavoritePlace(String placeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Place> places = await getFavoritePlaces();

      places.removeWhere((place) => place.id == placeId);

      final String placesJson = jsonEncode(places.map((p) => p.toJson()).toList());
      await prefs.setString(_favoritePlacesKey, placesJson);

      return true;
    } catch (e) {
      print('Error removing favorite place: $e');
      return false;
    }
  }

  // Add a place to recent places
  Future<bool> addRecentPlace(Place place) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Place> places = await getRecentPlaces();

      // Check if place already exists
      int existingIndex = places.indexWhere((p) =>
      p.latitude == place.latitude && p.longitude == place.longitude);

      if (existingIndex != -1) {
        // Update existing place with increased visit count and updated timestamp
        Place existingPlace = places[existingIndex];
        places.removeAt(existingIndex);
        places.insert(0, existingPlace.copyWith(
          visitCount: existingPlace.visitCount + 1,
          lastVisited: DateTime.now(),
        ));
      } else {
        // Add new place with a unique ID
        places.insert(0, place.copyWith(
          id: place.id.isEmpty ? _uuid.v4() : place.id,
          visitCount: 1,
          lastVisited: DateTime.now(),
        ));

        // Limit to 20 recent places
        if (places.length > 20) {
          places = places.sublist(0, 20);
        }
      }

      // Save updated list
      final String placesJson = jsonEncode(places.map((p) => p.toJson()).toList());
      await prefs.setString(_recentPlacesKey, placesJson);

      return true;
    } catch (e) {
      print('Error adding recent place: $e');
      return false;
    }
  }

  // Clear recent places
  Future<bool> clearRecentPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentPlacesKey);
      return true;
    } catch (e) {
      print('Error clearing recent places: $e');
      return false;
    }
  }

  // Update a place
  Future<bool> updatePlace(Place place) async {
    try {
      // Update in favorites if it exists there
      List<Place> favorites = await getFavoritePlaces();
      int favoriteIndex = favorites.indexWhere((p) => p.id == place.id);

      if (favoriteIndex != -1) {
        favorites[favoriteIndex] = place;
        final prefs = await SharedPreferences.getInstance();
        final String favoritesJson = jsonEncode(favorites.map((p) => p.toJson()).toList());
        await prefs.setString(_favoritePlacesKey, favoritesJson);
      }

      // Update in recents if it exists there
      List<Place> recents = await getRecentPlaces();
      int recentIndex = recents.indexWhere((p) => p.id == place.id);

      if (recentIndex != -1) {
        recents[recentIndex] = place;
        final prefs = await SharedPreferences.getInstance();
        final String recentsJson = jsonEncode(recents.map((p) => p.toJson()).toList());
        await prefs.setString(_recentPlacesKey, recentsJson);
      }

      return true;
    } catch (e) {
      print('Error updating place: $e');
      return false;
    }
  }

  // Get place by ID
  Future<Place?> getPlaceById(String id) async {
    try {
      // Check favorites
      List<Place> favorites = await getFavoritePlaces();
      int favoriteIndex = favorites.indexWhere((p) => p.id == id);

      if (favoriteIndex != -1) {
        return favorites[favoriteIndex];
      }

      // Check recents
      List<Place> recents = await getRecentPlaces();
      int recentIndex = recents.indexWhere((p) => p.id == id);

      if (recentIndex != -1) {
        return recents[recentIndex];
      }

      return null;
    } catch (e) {
      print('Error getting place by ID: $e');
      return null;
    }
  }

  // Get predefined categories
  List<Map<String, dynamic>> getPlaceCategories() {
    return [
      {'id': 'home', 'name': 'Home', 'icon': 'home'},
      {'id': 'work', 'name': 'Work', 'icon': 'work'},
      {'id': 'school', 'name': 'School', 'icon': 'school'},
      {'id': 'restaurant', 'name': 'Restaurant', 'icon': 'restaurant'},
      {'id': 'shopping', 'name': 'Shopping', 'icon': 'shopping_cart'},
      {'id': 'gas', 'name': 'Gas Station', 'icon': 'local_gas_station'},
      {'id': 'parking', 'name': 'Parking', 'icon': 'local_parking'},
      {'id': 'other', 'name': 'Other', 'icon': 'place'},
    ];
  }
}

