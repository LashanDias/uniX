import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import 'restaurant_catalog.dart';

class RestaurantStore {
  static const _placesKey = 'restaurants.custom.v1';
  static const _savedKey = 'restaurants.saved.v1';

  Future<List<Restaurant>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_placesKey);
    final custom = raw == null
        ? <Restaurant>[]
        : (jsonDecode(raw) as List)
              .map(
                (value) => Restaurant.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ),
              )
              .toList();
    return [...custom, ...restaurantCatalog];
  }

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
