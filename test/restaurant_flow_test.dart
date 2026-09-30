import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_app/core/theme/app_theme.dart';
import 'package:unix_app/models/restaurant.dart';
import 'package:unix_app/services/restaurant_catalog.dart';
import 'package:unix_app/services/restaurant_store.dart';
import 'package:unix_app/screens/restaurants/restaurants_screen.dart';
import 'package:unix_app/screens/restaurants/add_restaurant_screen.dart';
import 'package:unix_app/widgets/app_back_button.dart';
import 'package:unix_app/screens/hostels/hostels_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Custom restaurants and bookmarks persist across store instances',
    () async {
      final place = Restaurant(
        id: 'new',
        name: 'Student Café',
        category: 'Café',
        address: 'Campus road',
        description: 'Handmade snacks',
        menu: sampleRestaurantMenu('Café'),
      );
      await RestaurantStore().add(place);
      await RestaurantStore().setSaved('new', true);
      final restored = await RestaurantStore().load();
      expect(restored.first.name, 'Student Café');
      expect(restored.first.menu.first.name, 'Chicken burger');
      expect(await RestaurantStore().savedIds(), contains('new'));
      await expectLater(RestaurantStore().add(place), throwsStateError);
      expect(
        (await RestaurantStore().load()).where((item) => item.id == 'new'),
        hasLength(1),
      );
      await RestaurantStore().setSaved('new', false);
      expect(await RestaurantStore().savedIds(), isEmpty);
    },
  );

  testWidgets(
    'Canteen filters, menus and back navigation fit a narrow screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RestaurantsScreen(),
          routes: {'/main': (_) => const Scaffold(body: Text('Home'))},
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Canteens'));
      await tester.tap(find.text('Canteens'));
      await tester.pumpAndSettle();
      expect(find.text('SLTC Hostel Canteen'), findsOneWidget);
      expect(find.text('SLTC Main Canteen'), findsOneWidget);
      expect(find.text('Amavi Family Restaurant'), findsNothing);
      await tester.ensureVisible(find.text('View menu').first);
      await tester.tap(find.text('View menu').first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sample menu · estimated LKR'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Dinner').first);
      await tester.tap(find.text('Dinner').first);
      await tester.pumpAndSettle();
      expect(find.text('Egg kottu'), findsOneWidget);
      expect(find.text('Chicken rice & curry'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Restaurants & Canteens'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Add Restaurant validates and saves entered dishes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Restaurant? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<Restaurant>(
                  builder: (_) => AddRestaurantScreen(
                    onSave: (place) async {
                      saved = place;
                    },
                  ),
                ),
              ),
              child: const Text('Open restaurant form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open restaurant form'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save restaurant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save restaurant'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    for (final entry in {
      'Restaurant name': 'Student Kitchen',
      'Address': 'Campus Road',
      'Dish name': 'Rice and curry',
      'Price (LKR)': '350',
    }.entries) {
      final field = find.widgetWithText(TextFormField, entry.key);
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Save restaurant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save restaurant'));
    await tester.pumpAndSettle();
    expect(saved?.name, 'Student Kitchen');
    expect(saved?.sampleMenu, false);
    expect(saved?.menu.single.price, 350);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back on a root page returns to Home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: AppBar(leading: const AppBackButton())),
        routes: {'/main': (_) => const Scaffold(body: Text('Home'))},
      ),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Only boys hostels show Pending instead of available rooms', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HostelListScreen(gender: 'Boys')),
    );
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Boys Hostel A'), findsNothing);
    expect(find.textContaining('Rooms Available'), findsNothing);
    expect(
      HostelsScreen.hostels.where((hostel) => hostel.gender == 'Girls'),
      hasLength(2),
    );
  });
}
