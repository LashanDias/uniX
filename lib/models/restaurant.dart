class RestaurantFood {
  const RestaurantFood({
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.vegetarian = false,
  });
  final String name;
  final String category;
  final double price;
  final String description;
  final bool vegetarian;

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'vegetarian': vegetarian,
  };

  factory RestaurantFood.fromJson(Map<String, dynamic> json) => RestaurantFood(
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    description: json['description'] as String? ?? '',
    vegetarian: json['vegetarian'] as bool? ?? false,
  );
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.description,
    required this.menu,
    this.phone = '',
    this.hours = '',
    this.rating,
    this.reviewCount,
    this.sampleMenu = true,
    this.photoBase64 = '',
    this.reference = false,
  });
  final String id;
  final String name;
  final String category;
  final String address;
  final String description;
  final String phone;
  final String hours;
  final double? rating;
  final int? reviewCount;
  final List<RestaurantFood> menu;
  final bool sampleMenu;
  final String photoBase64;
  final bool reference;

  bool get isCanteen => category == 'Canteen';
  Uri get mapsUrl => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$name, $address, Sri Lanka',
  });
  Uri get directionsUrl => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$name, $address, Sri Lanka',
  });
  Uri get phoneUrl =>
      Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^+\d]'), ''));

  bool matches(String query) {
    final text =
        '$name $category $address ${menu.map((food) => food.name).join(' ')}'
            .toLowerCase();
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .every(text.contains);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'address': address,
    'description': description,
    'phone': phone,
    'hours': hours,
    'rating': rating,
    'reviewCount': reviewCount,
    'sampleMenu': sampleMenu,
    'photoBase64': photoBase64,
    'reference': reference,
    'menu': menu.map((food) => food.toJson()).toList(),
  };

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    address: json['address'] as String,
    description: json['description'] as String,
    phone: json['phone'] as String? ?? '',
    hours: json['hours'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: json['reviewCount'] as int?,
    sampleMenu: json['sampleMenu'] as bool? ?? true,
    photoBase64: json['photoBase64'] as String? ?? '',
    reference: json['reference'] as bool? ?? false,
    menu: (json['menu'] as List)
        .map(
          (food) =>
              RestaurantFood.fromJson(Map<String, dynamic>.from(food as Map)),
        )
        .toList(),
  );
}
