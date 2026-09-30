/// Local career guidance assistant.
///
/// Produces friendly, actionable advice entirely on-device so the chat keeps
/// working with no network and no API key. Wording is user-facing only: never
/// surface configuration or placeholder text to a student.
class CareerAiService {
  /// Topic keywords mapped to the tip shown when a student mentions them.
  static const Map<String, String> _topicTips = {
    'cv': 'Keep your CV to one page and lead each bullet with a verb '
        '("Built", "Led", "Analysed") plus a number you can defend.',
    'resume': 'Keep your CV to one page and lead each bullet with a verb '
        '("Built", "Led", "Analysed") plus a number you can defend.',
    'interview': 'Prepare three stories in STAR form (Situation, Task, Action, '
        'Result). Most interviewers ask for examples, not definitions.',
    'internship': 'Apply to internships 3-4 months early, and ask a lecturer '
        'for a reference before you need it.',
    'salary': 'Research the local range first, then give a band rather than a '
        'single number, and let the employer name theirs first.',
    'portfolio': 'Two finished projects with a clear README beat six unfinished '
        'ones. Explain the problem before the tech stack.',
    'linkedin': 'Write your LinkedIn headline as "what you do + for whom". '
        'Recruiters search by skill keywords, so spell them out.',
    'skills': 'Pick one depth skill and one breadth skill per semester. '
        'Scattered learning is hard to show on a CV.',
    'network': 'Message one alum a week with a specific question. Short, '
        'specific notes get answered far more often than generic ones.',
  };

  /// Analyses [message] and returns advice to show in the career chat.
  static Future<String> analyze(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return 'I did not catch that. Tell me what you would like help with — '
          'for example your CV, an interview, or which skills to learn next.';
    }

    final words = trimmed.toLowerCase().split(RegExp(r'[^a-z0-9+#]+'))
      ..removeWhere((word) => word.isEmpty);

    // Longer words carry the topic; short ones are usually filler.
    final focus = words.where((word) => word.length >= 4).take(4).toList();
    final focusLabel = focus.isEmpty ? trimmed : focus.join(', ');

    final tips = <String>[];
    for (final word in words) {
      final tip = _topicTips[word];
      if (tip != null && !tips.contains(tip)) tips.add(tip);
    }

    final advice = tips.isEmpty
        ? const [
            'Name the exact role you want — advice only gets useful once the '
                'target is specific.',
            'List the skills that role asks for, then mark which two you are '
                'weakest in.',
            'Build one small project that proves those two skills.',
          ]
        : tips.take(3).toList();

    final steps = advice
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');

    return 'I reviewed your message. Priority focus: $focusLabel.\n\n'
        'Here is what I suggest:\n$steps\n\n'
        'Ask me a follow-up any time — mention your CV, interviews, '
        'internships or skills and I will go deeper.';
  }
}
