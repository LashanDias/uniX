import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_app/screens/restaurants/restaurants_screen.dart';
import 'package:unix_app/widgets/floating_icons.dart';
import 'package:unix_app/services/restaurant_catalog.dart';
import 'package:unix_app/services/restaurant_store.dart';

/// A store whose device storage always fails.
class _BrokenStore extends RestaurantStore {
  @override
  Future<RestaurantLoad> loadAll() async => RestaurantLoad(
    places: restaurantCatalog,
    saved: const {},
    storageFailed: true,
  );
}

void main() {
  // The hero banners drift icons forever, which stops pumpAndSettle ever
  // returning. Hold them still for these tests.
  setUp(() => FloatingIcons.animationsEnabled = false);
  tearDown(() => FloatingIcons.animationsEnabled = true);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the built-in venues still show when storage fails', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: RestaurantsScreen(store: _BrokenStore())),
    );
    await tester.pumpAndSettle();

    // The screen used to render the failure notice *instead of* the list, so
    // one unreadable preference hid all ten compiled-in venues and the page
    // looked completely empty.
    expect(
      find.textContaining('${restaurantCatalog.length} places to explore'),
      findsOneWidget,
    );
    expect(find.textContaining('Could not load your saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a healthy load shows no failure notice', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: RestaurantsScreen(store: RestaurantStore())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load your saved'), findsNothing);
    expect(
      find.textContaining('${restaurantCatalog.length} places to explore'),
      findsOneWidget,
    );
  });

  test('the catalogue is compiled in, so it never depends on storage', () {
    expect(restaurantCatalog, isNotEmpty);
    expect(restaurantCatalog.every((place) => place.menu.isNotEmpty), isTrue);
  });
}
