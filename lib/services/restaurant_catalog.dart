import '../models/restaurant.dart';

// Menus and prices below are examples, not the venues' published menus.
List<RestaurantFood> sampleRestaurantMenu(
  String category, {
  bool hostel = false,
}) {
  if (category == 'Canteen') {
    return [
      const RestaurantFood(
        name: 'String hoppers & dhal',
        category: 'Breakfast',
        price: 180,
        vegetarian: true,
        description: 'String hoppers, dhal and coconut sambol',
      ),
      const RestaurantFood(
        name: 'Vegetable rice & curry',
        category: 'Lunch',
        price: 250,
        vegetarian: true,
        description: 'Rice with three vegetable curries',
      ),
      const RestaurantFood(
        name: 'Chicken rice & curry',
        category: 'Lunch',
        price: 380,
        description: 'Rice, chicken curry, vegetables and papadam',
      ),
      RestaurantFood(
        name: hostel ? 'Egg kottu' : 'Egg fried rice',
        category: hostel ? 'Dinner' : 'Lunch',
        price: hostel ? 400 : 350,
        description: hostel
            ? 'Chopped roti, egg and vegetables'
            : 'Wok-fried rice with egg and vegetables',
      ),
      if (hostel)
        const RestaurantFood(
          name: 'Roti & dhal',
          category: 'Dinner',
          price: 180,
          vegetarian: true,
          description: 'Two rotis with dhal curry',
        ),
      const RestaurantFood(
        name: 'Vegetable roti',
        category: 'Snacks',
        price: 100,
        vegetarian: true,
      ),
      const RestaurantFood(
        name: 'Milk tea',
        category: 'Drinks',
        price: 100,
        vegetarian: true,
      ),
    ];
  }
  if (category == 'Café') {
    return const [
      RestaurantFood(
        name: 'Chicken burger',
        category: 'Mains',
        price: 650,
        description: 'Chicken patty, lettuce and house-style sauce',
      ),
      RestaurantFood(
        name: 'Vegetable sandwich',
        category: 'Snacks',
        price: 400,
        vegetarian: true,
      ),
      RestaurantFood(
        name: 'French fries',
        category: 'Snacks',
        price: 350,
        vegetarian: true,
      ),
      RestaurantFood(
        name: 'Iced coffee',
        category: 'Drinks',
        price: 350,
        vegetarian: true,
      ),
      RestaurantFood(
        name: 'Lime juice',
        category: 'Drinks',
        price: 250,
        vegetarian: true,
      ),
    ];
  }
  return const [
    RestaurantFood(
      name: 'Chicken fried rice',
      category: 'Mains',
      price: 750,
      description: 'Wok-fried rice with chicken, egg and vegetables',
    ),
    RestaurantFood(
      name: 'Cheese kottu',
      category: 'Mains',
      price: 900,
      description: 'Chopped roti with cheese, egg and vegetables',
    ),
    RestaurantFood(
      name: 'Vegetable rice & curry',
      category: 'Mains',
      price: 450,
      vegetarian: true,
    ),
    RestaurantFood(name: 'Chicken noodles', category: 'Mains', price: 700),
    RestaurantFood(
      name: 'Vegetable roti',
      category: 'Snacks',
      price: 120,
      vegetarian: true,
    ),
    RestaurantFood(
      name: 'Fresh lime juice',
      category: 'Drinks',
      price: 250,
      vegetarian: true,
    ),
  ];
}

final restaurantCatalog = <Restaurant>[
  Restaurant(
    id: 'sltc-hostel',
    name: 'SLTC Hostel Canteen',
    category: 'Canteen',
    address: 'SLTC hostel, Meepe',
    description:
        'A campus food stop for hostel residents. Browse breakfast, lunch, dinner and quick bites.',
    menu: sampleRestaurantMenu('Canteen', hostel: true),
  ),
  Restaurant(
    id: 'sltc-main',
    name: 'SLTC Main Canteen',
    category: 'Canteen',
    address: 'SLTC campus, Meepe',
    description:
        'Explore meals and snacks for a break between classes. Confirm today’s food at the counter.',
    menu: sampleRestaurantMenu('Canteen'),
  ),
  Restaurant(
    id: 'amavi',
    name: 'Amavi Family Restaurant',
    category: 'Restaurant',
    address: 'Galagedara, No. 199/A New Road, Padukka 10500',
    phone: '0112 188 688',
    hours: '9:00 AM – 11:00 PM, Monday–Sunday',
    rating: 4.0,
    reviewCount: 558,
    description:
        'Family dining in Padukka. The shared listing mentions local short eats, fried rice and cheese kottu.',
    reference: true,
    menu: sampleRestaurantMenu('Restaurant'),
  ),
  Restaurant(
    id: 'heapich',
    name: 'Heapich Café',
    category: 'Café',
    address: '143 A/3, High Level Road, Meepe',
    description:
        'A café along the main road. The shared listing highlights burgers and casual café bites.',
    reference: true,
    menu: sampleRestaurantMenu('Café'),
  ),
  Restaurant(
    id: 'reliance',
    name: 'Reliance Restaurant',
    category: 'Restaurant',
    address: 'Avissawella Road, Padukka / Meepe',
    rating: 4.3,
    reviewCount: 26,
    description:
        'A casual meal stop. The shared listing mentions fried rice, rice and curry, and quick bites.',
    reference: true,
    menu: sampleRestaurantMenu('Restaurant'),
  ),
  Restaurant(
    id: 'mihiketha',
    name: 'Mihiketha Family Restaurant',
    category: 'Restaurant',
    address: 'R3RR+JX9, Padukka',
    rating: 3.9,
    reviewCount: 70,
    description: 'A family restaurant from your shared local listings.',
    reference: true,
    menu: sampleRestaurantMenu('Restaurant'),
  ),
  for (final name in [
    'Nimsara Hotel',
    'Dasatha Hotel',
    'City Rest',
    'Ceylon BakeHouse',
  ])
    Restaurant(
      id: 'existing-${name.toLowerCase().replaceAll(' ', '-')}',
      name: name,
      category: 'Restaurant',
      address: 'Meepe – Padukka',
      description:
          'An existing listing in the app. Confirm the exact address and menu with the restaurant.',
      menu: sampleRestaurantMenu('Restaurant'),
    ),
];
