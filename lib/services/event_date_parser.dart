/// How soon an event is, used to order the notice board.
///
/// Declaration order is the display order: today first, then tomorrow, and so
/// on, with undated notices last and past events filtered out.
enum EventUrgency { today, tomorrow, thisWeek, later, undated, past }

/// When an event happens, read out of a flyer's text.
class EventSchedule {
  const EventSchedule({required this.start, this.end, this.hasTime = false});

  /// Start of the event. Midnight when the flyer gave a date but no time.
  final DateTime start;

  /// End time, when the flyer gave a range.
  final DateTime? end;

  /// Whether a time of day was found, as opposed to a date alone.
  final bool hasTime;

  /// The moment the event stops being upcoming.
  ///
  /// A dateless event runs to the end of its day, so a flyer for "today" does
  /// not vanish at midnight that morning.
  DateTime get expiresAt =>
      end ?? (hasTime ? start.add(const Duration(hours: 3)) : _endOfDay(start));

  static DateTime _endOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, 23, 59, 59);

  bool isPast(DateTime now) => expiresAt.isBefore(now);

  EventUrgency urgency(DateTime now) {
    if (isPast(now)) return EventUrgency.past;
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(start.year, start.month, start.day);
    final days = eventDay.difference(today).inDays;
    if (days <= 0) return EventUrgency.today;
    if (days == 1) return EventUrgency.tomorrow;
    if (days <= 7) return EventUrgency.thisWeek;
    return EventUrgency.later;
  }
}

/// Reads event dates and times out of free-form flyer text.
///
/// Campus flyers are posters, not structured data: the date can appear as
/// "29th November 2025", "29/11/2025" or "Nov 29, 2025", and the time as
/// "2.00 PM - 4.00 PM" or "14:00". This normalises them so the board can hide
/// events that have already happened and put the soonest first.
class EventDateParser {
  static const _months = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  static String get _monthAlternatives => _months.keys.join('|');

  /// "29th November 2025", "29 Nov 2025".
  static RegExp get _dayMonthYear => RegExp(
    r'\b(\d{1,2})\s*(?:st|nd|rd|th)?\s+(' +
        _monthAlternatives +
        r')\.?\s*,?\s*(\d{4})\b',
    caseSensitive: false,
  );

  /// "November 29, 2025", "Nov 29 2025".
  static RegExp get _monthDayYear => RegExp(
    r'\b(' +
        _monthAlternatives +
        r')\.?\s+(\d{1,2})\s*(?:st|nd|rd|th)?\s*,?\s*(\d{4})\b',
    caseSensitive: false,
  );

  /// "2025-11-29".
  static final _isoDate = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b');

  /// "29/11/2025", "29-11-2025". Day first, as written in Sri Lanka.
  static final _slashDate = RegExp(r'\b(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})\b');

  /// "2.00 PM", "2:00pm", "14:00", "2 PM".
  static final _time = RegExp(
    r'\b(\d{1,2})[.:]?(\d{2})?\s*(am|pm)?\b',
    caseSensitive: false,
  );

  static DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    // DateTime rolls 31 February over into March; reject that.
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// The first date found in [text], or null.
  static DateTime? findDate(String text) {
    var match = _dayMonthYear.firstMatch(text);
    if (match != null) {
      final month = _months[match.group(2)!.toLowerCase()];
      if (month != null) {
        final date = _safeDate(
          int.parse(match.group(3)!),
          month,
          int.parse(match.group(1)!),
        );
        if (date != null) return date;
      }
    }

    match = _monthDayYear.firstMatch(text);
    if (match != null) {
      final month = _months[match.group(1)!.toLowerCase()];
      if (month != null) {
        final date = _safeDate(
          int.parse(match.group(3)!),
          month,
          int.parse(match.group(2)!),
        );
        if (date != null) return date;
      }
    }

    match = _isoDate.firstMatch(text);
    if (match != null) {
      final date = _safeDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
      if (date != null) return date;
    }

    match = _slashDate.firstMatch(text);
    if (match != null) {
      final date = _safeDate(
        int.parse(match.group(3)!),
        int.parse(match.group(2)!),
        int.parse(match.group(1)!),
      );
      if (date != null) return date;
    }

    return null;
  }

  /// Times of day found after [from] in [text], in order.
  ///
  /// Only accepts a bare number as a time when it carries am/pm or a colon,
  /// so "RBGF 3" and "2025" are not mistaken for three o'clock.
  static List<Duration> findTimes(String text, {int from = 0}) {
    final times = <Duration>[];
    for (final match in _time.allMatches(text.substring(from))) {
      final meridiem = match.group(3)?.toLowerCase();
      final minuteGroup = match.group(2);
      final raw = match.group(0)!;
      final hasSeparator = raw.contains(':') || raw.contains('.');
      if (meridiem == null && !hasSeparator) continue;
      if (meridiem == null && minuteGroup == null) continue;

      var hour = int.parse(match.group(1)!);
      final minute = int.parse(minuteGroup ?? '0');
      if (hour > 23 || minute > 59) continue;
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      times.add(Duration(hours: hour, minutes: minute));
      if (times.length == 2) break;
    }
    return times;
  }

  /// Reads the schedule out of [text], or returns null if it has no date.
  static EventSchedule? parse(String text) {
    final date = findDate(text);
    if (date == null) return null;

    final times = findTimes(text);
    if (times.isEmpty) {
      return EventSchedule(start: date);
    }
    final start = date.add(times.first);
    // A second time is only an end time if it is after the start; flyers with
    // a typo like "2.00 PM - 4.00 aM" would otherwise end before they begin.
    DateTime? end;
    if (times.length > 1) {
      final candidate = date.add(times[1]);
      if (candidate.isAfter(start)) end = candidate;
    }
    return EventSchedule(start: start, end: end, hasTime: true);
  }
}
