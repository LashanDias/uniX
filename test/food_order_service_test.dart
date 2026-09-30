import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/models/restaurant.dart';
import 'package:unix_app/services/food_order_service.dart';

const _rice = RestaurantFood(
  name: 'Vegetable rice & curry',
  category: 'Lunch',
  price: 250,
  vegetarian: true,
);
const _chicken = RestaurantFood(
  name: 'Chicken rice & curry',
  category: 'Lunch',
  price: 380,
);
const _hoppers = RestaurantFood(
  name: 'String hoppers & dhal',
  category: 'Breakfast',
  price: 180,
);

void main() {
  setUp(FoodOrderService.clear);
  tearDown(FoodOrderService.clear);

  group('adding to the cart', () {
    test('starts empty', () {
      expect(FoodOrderService.isEmpty, isTrue);
      expect(FoodOrderService.itemCount, 0);
      expect(FoodOrderService.cartTotal, 0);
    });

    test('adds a dish and remembers the venue', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      expect(FoodOrderService.itemCount, 1);
      expect(FoodOrderService.cartRestaurant, 'Main Canteen');
      expect(FoodOrderService.cartTotal, 250);
    });

    test('adding the same dish twice bumps its quantity', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      expect(FoodOrderService.cart.value, hasLength(1));
      expect(FoodOrderService.quantityOf(_rice), 2);
      expect(FoodOrderService.cartTotal, 500);
    });

    test('totals several different dishes', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      FoodOrderService.add(_chicken, restaurantName: 'Main Canteen');
      FoodOrderService.add(_hoppers, restaurantName: 'Main Canteen');
      expect(FoodOrderService.itemCount, 3);
      expect(FoodOrderService.cartTotal, 810);
    });
  });

  group('one venue at a time', () {
    test('ordering from another venue replaces the cart and says so', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      final kept = FoodOrderService.add(_hoppers, restaurantName: 'Hub Cafe');

      // A kitchen cannot cook another venue's food, so the cart resets. The
      // return value lets the screen explain that rather than the order
      // silently changing.
      expect(kept, isFalse);
      expect(FoodOrderService.cartRestaurant, 'Hub Cafe');
      expect(FoodOrderService.itemCount, 1);
      expect(FoodOrderService.quantityOf(_rice), 0);
    });

    test('adding within the same venue keeps the cart', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      final kept = FoodOrderService.add(
        _chicken,
        restaurantName: 'Main Canteen',
      );
      expect(kept, isTrue);
      expect(FoodOrderService.itemCount, 2);
    });
  });

  group('removing', () {
    test('removeOne reduces the quantity', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      FoodOrderService.removeOne(_rice);
      expect(FoodOrderService.quantityOf(_rice), 1);
    });

    test('removing the last one drops the line and forgets the venue', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      FoodOrderService.removeOne(_rice);
      expect(FoodOrderService.isEmpty, isTrue);
      expect(FoodOrderService.cartRestaurant, isNull);
    });

    test('removing a dish that is not in the cart is harmless', () {
      FoodOrderService.add(_rice, restaurantName: 'Main Canteen');
      FoodOrderService.removeOne(_chicken);
      expect(FoodOrderService.itemCount, 1);
    });
  });

  group('collection code', () {
    test('is short and readable', () {
      final code = FoodOrderService.buildCollectionCode(
        DateTime(2026, 6, 10, 12, 30),
      );
      expect(code, startsWith('UX'));
      expect(code.length, 7);
    });

    test('differs for orders placed at different times', () {
      final first = FoodOrderService.buildCollectionCode(
        DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final second = FoodOrderService.buildCollectionCode(
        DateTime.fromMillisecondsSinceEpoch(2000),
      );
      expect(first, isNot(second));
    });
  });

  group('order lines', () {
    test('a line totals price times quantity', () {
      const line = OrderLine(food: _chicken, quantity: 3);
      expect(line.total, 1140);
    });

    test('serialises what the kitchen needs', () {
      const line = OrderLine(food: _rice, quantity: 2);
      expect(line.toJson(), {
        'name': 'Vegetable rice & curry',
        'price': 250.0,
        'quantity': 2,
      });
    });
  });
}
