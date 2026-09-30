import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/event_date_parser.dart';

/// Text taken from the Gavel Club AGM flyer, typo and all.
const _gavelFlyer = '''
The Executive Committee of the GAVEL CLUB OF SLTC warmly invites you to the
ANNUAL GENERAL MEETING 2025/2026
: 29th November 2025
: 2.00 PM - 4.00 aM
: RBGF 3
''';

void main() {
  group('findDate', () {
    test('reads "29th November 2025" from a flyer', () {
      expect(EventDateParser.findDate(_gavelFlyer), DateTime(2025, 11, 29));
    });

    test('reads the month-first form', () {
      expect(
        EventDateParser.findDate('Seminar on November 29, 2025 in Hall A'),
        DateTime(2025, 11, 29),
      );
    });

    test('reads an ISO date', () {
      expect(
        EventDateParser.findDate('Deadline 2026-03-05'),
        DateTime(2026, 3, 5),
      );
    });

    test('reads a slash date as day first', () {
      // Sri Lankan flyers write 05/03/2026 for the 5th of March.
      expect(
        EventDateParser.findDate('Workshop 05/03/2026'),
        DateTime(2026, 3, 5),
      );
    });

    test('accepts abbreviated months', () {
      expect(
        EventDateParser.findDate('AGM 29 Nov 2025'),
        DateTime(2025, 11, 29),
      );
    });

    test('rejects an impossible date rather than rolling it over', () {
      // DateTime(2025, 2, 31) silently becomes 3 March; that must not pass.
      expect(EventDateParser.findDate('Due 31 February 2025'), isNull);
    });

    test('returns null when there is no date', () {
      expect(EventDateParser.findDate('Club meeting in the main hall'), isNull);
    });
  });

  group('findTimes', () {
    test('reads a start and end time', () {
      final times = EventDateParser.findTimes('2.00 PM - 4.00 PM');
      expect(times, hasLength(2));
      expect(times.first, const Duration(hours: 14));
      expect(times[1], const Duration(hours: 16));
    });

    test('reads 24-hour times', () {
      expect(
        EventDateParser.findTimes('Starts 14:30').first,
        const Duration(hours: 14, minutes: 30),
      );
    });

    test('does not mistake a room number for a time', () {
      // "RBGF 3" must not become three o'clock.
      expect(EventDateParser.findTimes('Venue: RBGF 3'), isEmpty);
    });

    test('handles midnight and noon correctly', () {
      expect(
        EventDateParser.findTimes('12.00 AM').first,
        Duration.zero,
      );
      expect(
        EventDateParser.findTimes('12.00 PM').first,
        const Duration(hours: 12),
      );
    });
  });

  group('parse', () {
    test('reads date and start time from the real flyer', () {
      final schedule = EventDateParser.parse(_gavelFlyer)!;
      expect(schedule.start, DateTime(2025, 11, 29, 14));
      expect(schedule.hasTime, isTrue);
    });

    test('ignores an end time that falls before the start', () {
      // The flyer says "2.00 PM - 4.00 aM", so the end reads as 4am, which is
      // before the start. Keeping it would make the event expire instantly.
      final schedule = EventDateParser.parse(_gavelFlyer)!;
      expect(schedule.end, isNull);
      expect(schedule.expiresAt.isAfter(schedule.start), isTrue);
    });

    test('keeps a valid end time', () {
      final schedule = EventDateParser.parse('29 Nov 2025, 2.00 PM - 4.00 PM')!;
      expect(schedule.end, DateTime(2025, 11, 29, 16));
    });

    test('a date with no time runs to the end of that day', () {
      final schedule = EventDateParser.parse('Sports day on 12 June 2026')!;
      expect(schedule.hasTime, isFalse);
      expect(schedule.expiresAt, DateTime(2026, 6, 12, 23, 59, 59));
    });

    test('returns null when the text has no date', () {
      expect(EventDateParser.parse('Come to the club room any time'), isNull);
    });
  });

  group('urgency', () {
    final now = DateTime(2026, 6, 10, 9);

    EventSchedule on(int day, {int hour = 15}) =>
        EventSchedule(start: DateTime(2026, 6, day, hour), hasTime: true);

    test('an event later today is today', () {
      expect(on(10).urgency(now), EventUrgency.today);
    });

    test('an event tomorrow is tomorrow', () {
      expect(on(11).urgency(now), EventUrgency.tomorrow);
    });

    test('an event in three days is this week', () {
      expect(on(13).urgency(now), EventUrgency.thisWeek);
    });

    test('an event next month is later', () {
      expect(on(30).urgency(now), EventUrgency.later);
    });

    test('a finished event is past', () {
      expect(on(9).urgency(now), EventUrgency.past);
      expect(on(9).isPast(now), isTrue);
    });

    test('an event earlier today has not expired until it ends', () {
      // 8am start, checked at 9am: still running under the 3 hour default.
      expect(on(10, hour: 8).isPast(now), isFalse);
    });

    test('urgency order puts today before tomorrow before later', () {
      expect(
        EventUrgency.today.index < EventUrgency.tomorrow.index,
        isTrue,
      );
      expect(
        EventUrgency.tomorrow.index < EventUrgency.thisWeek.index,
        isTrue,
      );
      expect(
        EventUrgency.thisWeek.index < EventUrgency.later.index,
        isTrue,
      );
    });
  });
}
