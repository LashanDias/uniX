import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_app/services/boarding_store.dart';

BoardingPlace custom(String name, {double distanceKm = 2, String? id}) =>
    BoardingPlace(
      id: id ?? 'custom-$name',
      name: name,
      kind: 'Boarding house',
      address: 'Somewhere near campus',
      distanceKm: distanceKm,
      custom: true,
    );

void main() {
  late BoardingStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = BoardingStore();
  });

  group('seeded places', () {
    test('ship with the app so the screen is never empty', () async {
      final loaded = await store.load();
      expect(loaded.places, isNotEmpty);
      expect(loaded.storageFailed, isFalse);
    });

    test('exclude the pet boarding service from the map search', () async {
      // A kennel shows up in a Google search for boarding near campus, but it
      // is not student accommodation.
      final names = BoardingStore.seeded.map((p) => p.name.toLowerCase());
      expect(names.any((n) => n.contains('kennel')), isFalse);
    });

    test('are all marked as not custom, so they cannot be edited', () {
      expect(BoardingStore.seeded.every((p) => !p.custom), isTrue);
    });
  });

  group('ordering', () {
    test('lists the nearest place first', () async {
      final loaded = await store.load();
      final distances = loaded.places.map((p) => p.distanceKm).toList();
      final sorted = [...distances]..sort();
      expect(distances, orderedEquals(sorted));
    });

    test('places a student adds are sorted in by distance too', () async {
      await store.add(custom('Very close place', distanceKm: 0.1));
      final loaded = await store.load();
      expect(loaded.places.first.name, 'Very close place');
    });
  });

  group('adding', () {
    test('keeps the place and marks it as the student\'s own', () async {
      await store.add(custom('New place'));
      final loaded = await store.load();
      final added = loaded.places.firstWhere((p) => p.name == 'New place');
      expect(added.custom, isTrue);
    });

    test('refuses a duplicate name', () async {
      await store.add(custom('Same name'));
      expect(
        () => store.add(custom('same NAME')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('updating', () {
    test('changes a place the student added', () async {
      await store.add(custom('Editable', id: 'c1'));
      final loaded = await store.load();
      final place = loaded.places.firstWhere((p) => p.id == 'c1');

      await store.update(place.copyWith(name: 'Renamed', monthlyPrice: 9500));

      final after = await store.load();
      final updated = after.places.firstWhere((p) => p.id == 'c1');
      expect(updated.name, 'Renamed');
      expect(updated.monthlyPrice, 9500);
    });

    test('refuses to edit a seeded place', () async {
      final seeded = BoardingStore.seeded.first;
      expect(
        () => store.update(seeded.copyWith(name: 'Hacked')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('removing', () {
    test('drops a place the student added', () async {
      await store.add(custom('Temporary', id: 'c2'));
      await store.remove('c2');
      final loaded = await store.load();
      expect(loaded.places.any((p) => p.id == 'c2'), isFalse);
    });

    test('leaves the seeded list intact', () async {
      await store.remove(BoardingStore.seeded.first.id);
      final loaded = await store.load();
      expect(loaded.places.length, greaterThanOrEqualTo(
        BoardingStore.seeded.length,
      ));
    });
  });

  group('labels', () {
    test('shows metres under a kilometre', () {
      expect(custom('x', distanceKm: 0.35).distanceLabel, '350 m');
    });

    test('shows kilometres above one', () {
      expect(custom('x', distanceKm: 1.6).distanceLabel, '1.6 km');
    });

    test('says so when a place has no rating', () {
      // Same wording Google Maps uses, so the card reads familiarly.
      expect(custom('x').ratingLabel, 'No ratings or reviews');
    });

    test('shows the rating and review count when there is one', () {
      expect(BoardingStore.seeded.first.ratingLabel, '3.9 (11)');
    });
  });

  group('search', () {
    test('matches on name, type and address', () {
      final place = custom('Indika House');
      expect(place.matches('indika'), isTrue);
      expect(place.matches('BOARDING'), isTrue);
      expect(place.matches('campus'), isTrue);
      expect(place.matches('zzz'), isFalse);
    });

    test('an empty search keeps everything', () {
      expect(custom('x').matches('  '), isTrue);
    });
  });

  group('round trip', () {
    test('survives being written and read back', () async {
      await store.add(
        BoardingPlace(
          id: 'c3',
          name: 'Full details',
          kind: 'Annex',
          address: '1 Main Street',
          distanceKm: 0.8,
          phone: '0112 100 500',
          monthlyPrice: 8000,
          note: 'Meals included',
          custom: true,
        ),
      );
      final loaded = await store.load();
      final place = loaded.places.firstWhere((p) => p.id == 'c3');
      expect(place.kind, 'Annex');
      expect(place.phone, '0112 100 500');
      expect(place.monthlyPrice, 8000);
      expect(place.note, 'Meals included');
      expect(place.distanceKm, 0.8);
    });
  });
}
