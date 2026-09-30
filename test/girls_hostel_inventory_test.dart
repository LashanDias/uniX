import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/girls_hostel_inventory.dart';

void main() {
  group('building structure', () {
    test('has 60+ rooms across its floors', () {
      expect(GirlsHostelInventory.totalRooms, greaterThan(60));
      expect(
        GirlsHostelInventory.totalRooms,
        GirlsHostelInventory.floors.length * 23,
      );
    });

    test('every floor holds 23 rooms', () {
      for (var floor = 0; floor < GirlsHostelInventory.floors.length; floor++) {
        expect(GirlsHostelInventory.roomsOn(floor).length, 23);
      }
    });

    test('every floor has 3 six-sharing rooms and 20 four-sharing', () {
      for (var floor = 0; floor < GirlsHostelInventory.floors.length; floor++) {
        final rooms = GirlsHostelInventory.roomsOn(floor);
        expect(rooms.where((room) => room.sharing == 6).length, 3);
        expect(rooms.where((room) => room.sharing == 4).length, 20);
      }
    });

    test('only 4-sharing and 6-sharing rooms exist', () {
      for (var floor = 0; floor < GirlsHostelInventory.floors.length; floor++) {
        for (final room in GirlsHostelInventory.roomsOn(floor)) {
          expect(room.sharing, anyOf(4, 6));
        }
      }
    });
  });

  group('room numbering', () {
    test('encodes floor and room as four digits', () {
      expect(GirlsHostelInventory.numberFor(0, 1), '0001');
      expect(GirlsHostelInventory.numberFor(2, 7), '0207');
      expect(GirlsHostelInventory.numberFor(2, 23), '0223');
    });

    test('every room number in the building is unique', () {
      final numbers = <String>{};
      for (var floor = 0; floor < GirlsHostelInventory.floors.length; floor++) {
        for (final room in GirlsHostelInventory.roomsOn(floor)) {
          expect(numbers.add(room.number), isTrue, reason: room.number);
        }
      }
      expect(numbers.length, GirlsHostelInventory.totalRooms);
    });
  });

  group('availability', () {
    test('never exceeds the number of beds in the room', () {
      for (var floor = 0; floor < GirlsHostelInventory.floors.length; floor++) {
        for (final room in GirlsHostelInventory.roomsOn(floor)) {
          expect(room.bedsAvailable, inInclusiveRange(0, room.sharing));
        }
      }
    });

    test('is stable across rebuilds', () {
      // A random number generator here would reshuffle availability every time
      // the list scrolled, so the count must be derived from the room number.
      final first = GirlsHostelInventory.roomsOn(1).map((r) => r.bedsAvailable);
      final second = GirlsHostelInventory.roomsOn(1).map((r) => r.bedsAvailable);
      expect(first, orderedEquals(second));
    });

    test('availableOn excludes fully booked rooms', () {
      for (var floor = 0; floor < GirlsHostelInventory.floors.length; floor++) {
        final available = GirlsHostelInventory.availableOn(floor);
        expect(available.every((room) => room.bedsAvailable > 0), isTrue);
        expect(available.length, lessThanOrEqualTo(23));
      }
    });
  });

  group('pricing', () {
    test('6-sharing is cheaper per room than 4-sharing', () {
      expect(
        GirlsHostelInventory.monthlyPrice(6),
        lessThan(GirlsHostelInventory.monthlyPrice(4)),
      );
    });

    test('matches the published rates', () {
      expect(GirlsHostelInventory.monthlyPrice(4), 9500);
      expect(GirlsHostelInventory.monthlyPrice(6), 8000);
      expect(GirlsHostelInventory.weeklyPrice(4), 2500);
      expect(GirlsHostelInventory.weeklyPrice(6), 2250);
      expect(GirlsHostelInventory.dailyPrice(4), 900);
      expect(GirlsHostelInventory.dailyPrice(6), 600);
    });
  });

  group('one source of truth for prices', () {
    test('only 4-sharing and 6-sharing rooms are priced', () {
      // The hostel detail screen used to derive prices by adding and
      // subtracting from a per-hostel figure, which produced 12,500 / 10,000 /
      // 8,500 and offered a 2-sharing room that does not exist. Both screens
      // now read these two figures.
      expect(GirlsHostelInventory.monthlyPrice(4), 9500);
      expect(GirlsHostelInventory.monthlyPrice(6), 8000);
    });

    test('an unknown sharing size falls back to the 4-sharing rate', () {
      expect(GirlsHostelInventory.monthlyPrice(2), 9500);
    });
  });

  group('labels', () {
    test('a fully booked room says so instead of showing 0 beds', () {
      const full = HostelRoom(
        number: '0001',
        floorIndex: 0,
        sharing: 4,
        bedsAvailable: 0,
      );
      expect(full.isFull, isTrue);
      expect(full.bedsLabel, 'Fully booked');
    });

    test('one free bed is singular', () {
      const one = HostelRoom(
        number: '0002',
        floorIndex: 0,
        sharing: 4,
        bedsAvailable: 1,
      );
      expect(one.bedsLabel, '1 bed available');
    });

    test('several free beds are plural', () {
      const three = HostelRoom(
        number: '0003',
        floorIndex: 0,
        sharing: 4,
        bedsAvailable: 3,
      );
      expect(three.bedsLabel, '3 beds available');
    });
  });
}
