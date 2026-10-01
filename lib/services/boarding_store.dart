import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Which accommodation section a place belongs to.
enum BoardingCategory {
  boarding('Boarding'),
  annex('Annex Houses');

  const BoardingCategory(this.label);

  /// Title shown at the top of the screen.
  final String label;
}

/// A boarding place or annex near campus.
class BoardingPlace {
  const BoardingPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.address,
    required this.distanceKm,
    this.category = BoardingCategory.boarding,
    this.rating,
    this.reviewCount = 0,
    this.note = '',
    this.phone = '',
    this.monthlyPrice,
    this.custom = false,
  });

  final String id;
  final String name;

  /// What the place calls itself: Boarding house, Hostel, Housing complex.
  final String kind;

  /// Which accommodation section this place belongs to.
  final BoardingCategory category;

  final String address;
  final double distanceKm;

  /// Google rating out of 5, when the place has one.
  final double? rating;
  final int reviewCount;

  /// A short quote or remark about the place.
  final String note;
  final String phone;

  /// Monthly rate in LKR, when the student recorded one.
  final int? monthlyPrice;

  /// True for places a student added, which can be edited or removed.
  final bool custom;

  /// Walking distance, shown the way a map app would.
  String get distanceLabel => distanceKm < 1
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(1)} km';

  String get ratingLabel => rating == null
      ? 'No ratings or reviews'
      : '${rating!.toStringAsFixed(1)} ($reviewCount)';

  bool matches(String term) {
    final needle = term.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        kind.toLowerCase().contains(needle) ||
        address.toLowerCase().contains(needle);
  }

  /// `tel:` link, with spaces stripped so dialers accept it.
  Uri get phoneUrl => Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));

  bool get hasPhone => phone.trim().isNotEmpty;

  /// Google Maps search link for this place.
  Uri get mapsUrl => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$name, $address',
  });

  BoardingPlace copyWith({
    String? name,
    String? kind,
    String? address,
    double? distanceKm,
    String? phone,
    int? monthlyPrice,
    String? note,
  }) => BoardingPlace(
    id: id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    category: category,
    address: address ?? this.address,
    distanceKm: distanceKm ?? this.distanceKm,
    rating: rating,
    reviewCount: reviewCount,
    note: note ?? this.note,
    phone: phone ?? this.phone,
    monthlyPrice: monthlyPrice ?? this.monthlyPrice,
    custom: custom,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'category': category.name,
    'address': address,
    'distanceKm': distanceKm,
    'rating': rating,
    'reviewCount': reviewCount,
    'note': note,
    'phone': phone,
    'monthlyPrice': monthlyPrice,
  };

  factory BoardingPlace.fromJson(Map<String, dynamic> json) => BoardingPlace(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: (json['kind'] ?? 'Boarding house') as String,
    category: BoardingCategory.values.firstWhere(
      (value) => value.name == json['category'],
      orElse: () => BoardingCategory.boarding,
    ),
    address: (json['address'] ?? '') as String,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    note: (json['note'] ?? '') as String,
    phone: (json['phone'] ?? '') as String,
    monthlyPrice: (json['monthlyPrice'] as num?)?.toInt(),
    custom: true,
  );
}

/// Boarding places and annexes near SLTC, with the ones students add.
///
/// The built-in list comes from a Google Maps search for accommodation near
/// the Padukka campus. Pet boarding services are deliberately not included: a
/// kennel appears in that search but is not student accommodation.
class BoardingStore {
  static const _key = 'boarding.custom.v1';

  /// Places that ship with the app and need no storage to show.
  static const seeded = <BoardingPlace>[
    BoardingPlace(
      id: 'seed-mahagedara',
      name: 'මහගෙදර බෝඩිම්',
      kind: 'Hotel',
      address: 'No:132/C Pitumpe - Wawulkele Waththa Rd',
      distanceKm: 1.6,
      rating: 3.9,
      reviewCount: 11,
      phone: '077 885 8192',
      note: 'The safest and peaceful boarding house I ever seen.',
    ),
    BoardingPlace(
      id: 'seed-boarding-p',
      name: 'Boarding P',
      kind: 'Housing complex',
      address: 'V34Q+6CR, 1st Ln',
      distanceKm: 0.35,
      rating: 5,
      reviewCount: 1,
      phone: '071 867 2930',
      note: 'Nice boarding house.',
    ),
    BoardingPlace(
      id: 'seed-indika',
      name: "Indika's bordim House",
      kind: 'Hostel',
      address: 'V33X+2MJ',
      distanceKm: 1,
      rating: 5,
      reviewCount: 1,
      phone: '076 885 8023',
    ),
    BoardingPlace(
      id: 'seed-vivekapanchaya',
      name: 'විවේක පංචය – The Five of Discernment',
      kind: 'Boarding house',
      address: '164, 11 Dekaduwala Road',
      distanceKm: 0.55,
      rating: 5,
      reviewCount: 4,
      // As supplied. Nine digits rather than the usual ten for a Sri Lankan
      // mobile, so it may be missing one.
      phone: '078 902 345',
    ),
    BoardingPlace(
      id: 'seed-sltc-annex',
      name: 'SLTC Annex',
      kind: 'Student housing center',
      category: BoardingCategory.annex,
      address: 'V34W+9WC, Padukka',
      distanceKm: 0.7,
      phone: '072 147 8876',
    ),
  ];

  /// What kind of place a student can record.
  static const kinds = [
    'Boarding house',
    'Hostel',
    'Annex',
    'Housing complex',
    'Student housing center',
    'Hotel',
  ];

  /// Places in [category], nearest first, plus the student's own.
  ///
  /// The seeded list is compiled in, so it is returned even when storage
  /// cannot be read; only the student's additions are lost in that case.
  Future<BoardingLoad> load({BoardingCategory? category}) async {
    var custom = <BoardingPlace>[];
    var storageFailed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        custom = (jsonDecode(raw) as List)
            .map(
              (value) => BoardingPlace.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList();
      }
    } catch (_) {
      storageFailed = true;
    }
    final all =
        [...custom, ...seeded]
            .where((place) => category == null || place.category == category)
            .toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return BoardingLoad(places: all, storageFailed: storageFailed);
  }

  Future<List<BoardingPlace>> _customOnly() async {
    final loaded = await load();
    return loaded.places.where((place) => place.custom).toList();
  }

  /// Adds a place a student found. Names must be unique among custom places.
  Future<void> add(BoardingPlace place) async {
    final custom = await _customOnly();
    final clash = custom.any(
      (item) =>
          item.name.trim().toLowerCase() == place.name.trim().toLowerCase(),
    );
    if (clash) {
      throw StateError('You have already added a place with that name.');
    }
    await _save([place, ...custom]);
  }

  /// Updates a place the student added. Seeded places cannot be edited.
  Future<void> update(BoardingPlace place) async {
    final custom = await _customOnly();
    final index = custom.indexWhere((item) => item.id == place.id);
    if (index == -1) {
      throw StateError('Only places you added yourself can be edited.');
    }
    custom[index] = place;
    await _save(custom);
  }

  Future<void> remove(String id) async {
    final custom = await _customOnly();
    await _save(custom.where((item) => item.id != id).toList());
  }

  Future<void> _save(List<BoardingPlace> custom) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      _key,
      jsonEncode(custom.map((item) => item.toJson()).toList()),
    );
    if (!ok) throw StateError('Could not save this boarding place.');
  }
}

class BoardingLoad {
  const BoardingLoad({required this.places, required this.storageFailed});

  final List<BoardingPlace> places;

  /// True when this device's storage could not be read, so places the student
  /// added are missing. The seeded list is still present.
  final bool storageFailed;
}
