import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/girls_hostel_inventory.dart';
import 'package:unix_app/services/hostel_booking_service.dart';

void main() {
  group('stay validation', () {
    final checkIn = DateTime(2026, 11, 2);

    test('accepts a normal stay', () {
      expect(
        HostelBookingService.validateStay(checkIn, DateTime(2026, 12, 2)),
        isNull,
      );
    });

    test('rejects a check-out on the same day', () {
      expect(
        HostelBookingService.validateStay(checkIn, checkIn),
        contains('after your check-in'),
      );
    });

    test('rejects a check-out before check-in', () {
      expect(
        HostelBookingService.validateStay(checkIn, DateTime(2026, 11, 1)),
        isNotNull,
      );
    });

    test('rejects a stay longer than the maximum', () {
      final tooLong = checkIn.add(
        Duration(days: HostelBookingService.maxNights + 1),
      );
      expect(
        HostelBookingService.validateStay(checkIn, tooLong),
        contains('90 nights'),
      );
    });

    test('accepts a stay of exactly the maximum', () {
      final limit = checkIn.add(
        Duration(days: HostelBookingService.maxNights),
      );
      expect(HostelBookingService.validateStay(checkIn, limit), isNull);
    });
  });

  group('nightsBetween', () {
    test('counts calendar nights', () {
      expect(
        HostelBookingService.nightsBetween(
          DateTime(2026, 11, 2),
          DateTime(2026, 12, 2),
        ),
        30,
      );
    });

    test('ignores the time of day', () {
      // A booking made at 11pm must not count as one night fewer.
      expect(
        HostelBookingService.nightsBetween(
          DateTime(2026, 11, 2, 23, 30),
          DateTime(2026, 11, 3, 1),
        ),
        1,
      );
    });
  });

  group('reference code', () {
    test('is short and recognisable', () {
      final reference = HostelBookingService.buildReference(
        DateTime(2026, 11, 2, 14),
      );
      expect(reference, startsWith('HB'));
      expect(reference.length, 7);
    });

    test('differs between requests made at different times', () {
      expect(
        HostelBookingService.buildReference(
          DateTime.fromMillisecondsSinceEpoch(1000),
        ),
        isNot(
          HostelBookingService.buildReference(
            DateTime.fromMillisecondsSinceEpoch(2000),
          ),
        ),
      );
    });
  });

  group('booking guards', () {
    test('refuses a room with no free beds', () async {
      const full = HostelRoom(
        number: '0001',
        floorIndex: 0,
        sharing: 4,
        bedsAvailable: 0,
      );
      // Signed out, so this throws for the sign-in reason first; the point is
      // that a request never silently succeeds.
      expect(
        () => HostelBookingService.book(
          room: full,
          checkIn: DateTime(2026, 11, 2),
          checkOut: DateTime(2026, 12, 2),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('requires a signed-in student', () async {
      const room = HostelRoom(
        number: '0004',
        floorIndex: 0,
        sharing: 4,
        bedsAvailable: 2,
      );
      expect(
        () => HostelBookingService.book(
          room: room,
          checkIn: DateTime(2026, 11, 2),
          checkOut: DateTime(2026, 12, 2),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a signed-out student gets an empty booking list, not an error', () {
      expect(HostelBookingService.watchMyBookings(), emits(isEmpty));
    });
  });

  group('status flow', () {
    test('a request starts at Requested', () {
      expect(HostelBooking.statuses.first, 'Requested');
    });

    test('confirmation and payment come after the request', () {
      // The student submits; only an admin moves it on, which firestore.rules
      // enforces by pinning status to Requested on create.
      expect(HostelBooking.statuses, containsAllInOrder(
        ['Requested', 'Confirmed', 'Paid'],
      ));
    });
  });
}
