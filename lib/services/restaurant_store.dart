import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import 'restaurant_catalog.dart';

class RestaurantStore {
  static const _placesKey = 'restaurants.custom.v1';
  static const _savedKey = 'restaurants.saved.v1';

  /// Restaurants to show, and whether the device's own storage could be read.
  ///
  /// The built-in catalogue needs no storage, so it is always returned. Only
  /// the places the student added themselves, and which ones they saved,
  /// depend on SharedPreferences. Previously any storage error failed the
  /// whole load and the screen showed nothing at all -- ten built-in venues
  /// disappeared because a preference could not be read.
  Future<RestaurantLoad> loadAll() async {
    var storageFailed = false;
    var custom = <Restaurant>[];
    var saved = <String>{};

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_placesKey);
      if (raw != null) {
        custom = (jsonDecode(raw) as List)
            .map(
              (value) =>
                  Restaurant.fromJson(Map<String, dynamic>.from(value as Map)),
            )
            .toList();
      }
      saved = (prefs.getStringList(_savedKey) ?? []).toSet();
    } catch (_) {
      storageFailed = true;
    }

    return RestaurantLoad(
      places: [...custom, ...restaurantCatalog],
      saved: saved,
      storageFailed: storageFailed,
    );
  }

  Future<List<Restaurant>> load() async => (await loadAll()).places;

  Future<void> add(Restaurant place) async {
    final existing = await load();
    if (existing.any(
      (item) =>
          item.id == place.id ||
          (item.name.trim().toLowerCase() == place.name.trim().toLowerCase() &&
              item.address.trim().toLowerCase() ==
                  place.address.trim().toLowerCase()),
    )) {
      throw StateError('This restaurant is already in your list.');
    }
    final builtInIds = restaurantCatalog.map((item) => item.id).toSet();
    final custom = [
      place,
      ...existing.where((item) => !builtInIds.contains(item.id)),
    ];
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _placesKey,
      jsonEncode(custom.map((item) => item.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save this restaurant.');
  }

  Future<Set<String>> savedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_savedKey) ?? []).toSet();
  }

  Future<void> setSaved(String id, bool saved) async {
    final ids = await savedIds();
    saved ? ids.add(id) : ids.remove(id);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setStringList(_savedKey, ids.toList())) {
      throw StateError('Could not update saved restaurants.');
    }
  }
}

/// The result of reading the restaurant list.
class RestaurantLoad {
  const RestaurantLoad({
    required this.places,
    required this.saved,
    required this.storageFailed,
  });

  final List<Restaurant> places;
  final Set<String> saved;

  /// True when this device's storage could not be read, so places the student
  /// added and their saved marks are missing. The catalogue is still present.
  final bool storageFailed;
}
