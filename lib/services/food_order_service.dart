import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/restaurant.dart';

/// One dish in the cart, with how many of it.
class OrderLine {
  const OrderLine({required this.food, required this.quantity});

  final RestaurantFood food;
  final int quantity;

  double get total => food.price * quantity;

  OrderLine copyWith({int? quantity}) =>
      OrderLine(food: food, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toJson() => {
    'name': food.name,
    'price': food.price,
    'quantity': quantity,
  };
}

/// A placed order and where it has got to.
class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.restaurantName,
    required this.lines,
    required this.total,
    required this.status,
    required this.placedAt,
    required this.collectionCode,
  });

  final String id;
  final String restaurantName;
  final List<String> lines;
  final double total;
  final String status;
  final DateTime placedAt;

  /// Short code the student shows at the counter.
  final String collectionCode;

  static const statuses = ['Placed', 'Preparing', 'Ready', 'Collected'];

  static FoodOrder fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return FoodOrder(
      id: doc.id,
      restaurantName: (data['restaurantName'] ?? '').toString(),
      lines: [
        for (final line in (data['lines'] as List? ?? []))
          '${(line as Map)['quantity']} x ${line['name']}',
      ],
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: (data['status'] ?? 'Placed').toString(),
      placedAt: (data['placedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      collectionCode: (data['collectionCode'] ?? '').toString(),
    );
  }
}

/// The current cart and order placement.
///
/// Orders are collect-and-pay-at-the-counter: the app reserves the food and
/// hands over a code. It takes no payment, because that needs a payment
/// provider the university has not set up.
class FoodOrderService {
  /// The cart, broadcast so the menu and the cart bar stay in step.
  static final ValueNotifier<List<OrderLine>> cart =
      ValueNotifier<List<OrderLine>>([]);

  /// The venue the cart belongs to. Ordering from another clears it.
  static String? cartRestaurant;

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const collection = 'foodOrders';

  static int get itemCount =>
      cart.value.fold(0, (running, line) => running + line.quantity);

  static double get cartTotal =>
      cart.value.fold(0, (running, line) => running + line.total);

  static bool get isEmpty => cart.value.isEmpty;

  /// Adds [food] to the cart, or bumps its quantity if already there.
  ///
  /// Returns false when the cart held another venue's food and was replaced,
  /// so the screen can tell the student.
  static bool add(RestaurantFood food, {required String restaurantName}) {
    var kept = true;
    if (cartRestaurant != null && cartRestaurant != restaurantName) {
      cart.value = [];
      kept = false;
    }
    cartRestaurant = restaurantName;

    final existing = cart.value.indexWhere((l) => l.food.name == food.name);
    if (existing == -1) {
      cart.value = [...cart.value, OrderLine(food: food, quantity: 1)];
    } else {
      final lines = [...cart.value];
      lines[existing] = lines[existing].copyWith(
        quantity: lines[existing].quantity + 1,
      );
      cart.value = lines;
    }
    return kept;
  }

  /// Reduces the quantity of [food], removing the line when it hits zero.
  static void removeOne(RestaurantFood food) {
    final index = cart.value.indexWhere((l) => l.food.name == food.name);
    if (index == -1) return;
    final lines = [...cart.value];
    if (lines[index].quantity <= 1) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(
        quantity: lines[index].quantity - 1,
      );
    }
    cart.value = lines;
    if (cart.value.isEmpty) cartRestaurant = null;
  }

  static int quantityOf(RestaurantFood food) => cart.value
      .firstWhere(
        (l) => l.food.name == food.name,
        orElse: () => OrderLine(food: food, quantity: 0),
      )
      .quantity;

  static void clear() {
    cart.value = [];
    cartRestaurant = null;
  }

  /// A short, readable pickup code derived from the time of placing.
  static String buildCollectionCode(DateTime at) {
    final stamp = at.millisecondsSinceEpoch.remainder(100000);
    return 'UX${stamp.toString().padLeft(5, '0')}';
  }

  /// Places the cart as an order and clears it.
  static Future<FoodOrder> placeOrder({String? note}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in to place an order.');
    if (isEmpty) throw StateError('Your cart is empty.');
    final restaurant = cartRestaurant;
    if (restaurant == null) throw StateError('Your cart is empty.');

    final lines = [...cart.value];
    final total = cartTotal;
    final code = buildCollectionCode(DateTime.now());

    final reference = await _db.collection(collection).add({
      'userId': user.uid,
      'restaurantName': restaurant,
      'lines': [for (final line in lines) line.toJson()],
      'total': total,
      'status': 'Placed',
      'note': (note ?? '').trim(),
      'collectionCode': code,
      'placedAt': FieldValue.serverTimestamp(),
    });

    clear();
    return FoodOrder(
      id: reference.id,
      restaurantName: restaurant,
      lines: [for (final line in lines) '${line.quantity} x ${line.food.name}'],
      total: total,
      status: 'Placed',
      placedAt: DateTime.now(),
      collectionCode: code,
    );
  }

  /// The signed-in student's own orders, newest first.
  static Stream<List<FoodOrder>> watchMyOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(const []);
    return _db
        .collection(collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('placedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FoodOrder.fromDoc).toList());
  }
}
