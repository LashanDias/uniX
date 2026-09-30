import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/event_date_parser.dart';
import 'package:unix_app/services/notice_board_service.dart';

final _now = DateTime(2026, 6, 10, 9);

Notice notice(
  String title, {
  String body = '',
  bool pinned = false,
  Duration postedAgo = const Duration(hours: 1),
}) => Notice(
  id: title,
  title: title,
  body: body,
  category: 'Events',
  postedBy: 'Club',
  postedAt: _now.subtract(postedAgo),
  pinned: pinned,
);

void main() {
  group('event detection on a notice', () {
    test('reads the date out of the flyer text', () {
      final agm = notice(
        'Gavel Club AGM',
        body: 'Annual General Meeting on 29th November 2026 at 2.00 PM.',
      );
      expect(agm.schedule, isNotNull);
      expect(agm.schedule!.start, DateTime(2026, 11, 29, 14));
    });

    test('a notice with no date has no schedule and no badge', () {
      final general = notice('Library rules', body: 'Please keep quiet.');
      expect(general.schedule, isNull);
      expect(general.urgency(now: _now), EventUrgency.undated);
      expect(general.whenLabel, isNull);
    });
  });

  group('sortForBoard', () {
    test('drops events that have already finished', () {
      final board = NoticeBoardService.sortForBoard([
        notice('Old AGM', body: 'Held on 1 June 2026 at 2.00 PM.'),
        notice('Future AGM', body: 'On 30 June 2026 at 2.00 PM.'),
      ], now: _now);

      expect(board.map((n) => n.title), ['Future AGM']);
    });

    test('keeps finished events when asked for them', () {
      final board = NoticeBoardService.sortForBoard(
        [notice('Old AGM', body: 'Held on 1 June 2026 at 2.00 PM.')],
        now: _now,
        includePast: true,
      );
      expect(board, hasLength(1));
    });

    test('puts today first, then tomorrow, then later', () {
      final board = NoticeBoardService.sortForBoard([
        notice('Next month', body: 'On 30 June 2026 at 2.00 PM.'),
        notice('Tomorrow', body: 'On 11 June 2026 at 2.00 PM.'),
        notice('Today', body: 'On 10 June 2026 at 2.00 PM.'),
      ], now: _now);

      expect(board.map((n) => n.title), ['Today', 'Tomorrow', 'Next month']);
    });

    test('a dated event outranks an undated notice', () {
      final board = NoticeBoardService.sortForBoard([
        notice('No date here', postedAgo: const Duration(minutes: 1)),
        notice('Today', body: 'On 10 June 2026 at 2.00 PM.'),
      ], now: _now);

      expect(board.first.title, 'Today');
    });

    test('pinned notices lead regardless of date', () {
      final board = NoticeBoardService.sortForBoard([
        notice('Today', body: 'On 10 June 2026 at 2.00 PM.'),
        notice('Pinned rules', pinned: true),
      ], now: _now);

      expect(board.first.title, 'Pinned rules');
    });

    test('two events on the same day are ordered by start time', () {
      final board = NoticeBoardService.sortForBoard([
        notice('Evening', body: 'On 10 June 2026 at 6.00 PM.'),
        notice('Noon', body: 'On 10 June 2026 at 12.00 PM.'),
      ], now: _now);

      expect(board.map((n) => n.title), ['Noon', 'Evening']);
    });

    test('undated notices fall back to newest first', () {
      final board = NoticeBoardService.sortForBoard([
        notice('Older', postedAgo: const Duration(days: 2)),
        notice('Newer', postedAgo: const Duration(minutes: 5)),
      ], now: _now);

      expect(board.map((n) => n.title), ['Newer', 'Older']);
    });
  });

  group('whenLabel', () {
    test('names the bucket a student cares about', () {
      final today = notice('T', body: 'On 10 June 2026 at 8.00 PM.');
      expect(today.urgency(now: _now), EventUrgency.today);
    });
  });

  group('sample notices', () {
    test('are provided so the board is never blank', () {
      expect(NoticeBoardService.sampleNotices(), isNotEmpty);
    });

    test('every sample has a category the form offers', () {
      for (final sample in NoticeBoardService.sampleNotices()) {
        expect(Notice.categories, contains(sample.category));
      }
    });
  });
}
