/// Condensed revision notes generated from a longer document.
class ShortNotes {
  const ShortNotes({
    required this.title,
    required this.summary,
    required this.keyPoints,
    required this.definitions,
    required this.keyTerms,
    required this.sourceWordCount,
  });

  final String title;

  /// A few sentences describing what the document is about.
  final String summary;

  /// The sentences worth revising, shortest useful form.
  final List<String> keyPoints;

  /// Sentences that define a term, as `term -> meaning`.
  final Map<String, String> definitions;

  /// The terms the document keeps coming back to.
  final List<String> keyTerms;

  final int sourceWordCount;

  int get shortWordCount =>
      NoteSummarizer.countWords(summary) +
      keyPoints.fold(0, (sum, p) => sum + NoteSummarizer.countWords(p));

  /// How much shorter the notes are than the source, as a percentage.
  int get reductionPercent {
    if (sourceWordCount == 0) return 0;
    final kept = shortWordCount / sourceWordCount;
    return ((1 - kept) * 100).clamp(0, 100).round();
  }

  bool get isEmpty => keyPoints.isEmpty && summary.isEmpty;

  /// Plain-text version, for copying to the clipboard or sharing.
  String toPlainText() {
    final buffer = StringBuffer('$title\n\n');
    if (summary.isNotEmpty) buffer.writeln('SUMMARY\n$summary\n');
    if (keyPoints.isNotEmpty) {
      buffer.writeln('KEY POINTS');
      for (final point in keyPoints) {
        buffer.writeln('- $point');
      }
      buffer.writeln();
    }
    if (definitions.isNotEmpty) {
      buffer.writeln('DEFINITIONS');
      definitions.forEach((term, meaning) {
        buffer.writeln('- $term: $meaning');
      });
      buffer.writeln();
    }
    if (keyTerms.isNotEmpty) {
      buffer.writeln('KEY TERMS\n${keyTerms.join(', ')}');
    }
    return buffer.toString().trimRight();
  }
}

/// Turns a long document into short revision notes, entirely on-device.
///
/// This is extractive, not generative: it scores the document's own sentences
/// and keeps the highest scoring ones. That means it never invents a fact that
/// is not in the source, which matters when students revise from the output.
/// It also needs no API key and works with no network.
class NoteSummarizer {
  /// Words too common to say anything about what a document is about.
  static const _stopWords = {
    'a',
    'about',
    'above',
    'after',
    'again',
    'all',
    'also',
    'am',
    'an',
    'and',
    'any',
    'are',
    'as',
    'at',
    'be',
    'because',
    'been',
    'before',
    'being',
    'below',
    'between',
    'both',
    'but',
    'by',
    'can',
    'did',
    'do',
    'does',
    'doing',
    'down',
    'during',
    'each',
    'few',
    'for',
    'from',
    'further',
    'had',
    'has',
    'have',
    'having',
    'he',
    'her',
    'here',
    'hers',
    'him',
    'his',
    'how',
    'i',
    'if',
    'in',
    'into',
    'is',
    'it',
    'its',
    'just',
    'me',
    'more',
    'most',
    'my',
    'no',
    'nor',
    'not',
    'now',
    'of',
    'off',
    'on',
    'once',
    'only',
    'or',
    'other',
    'our',
    'out',
    'over',
    'own',
    'same',
    'she',
    'should',
    'so',
    'some',
    'such',
    'than',
    'that',
    'the',
    'their',
    'them',
    'then',
    'there',
    'these',
    'they',
    'this',
    'those',
    'through',
    'to',
    'too',
    'under',
    'until',
    'up',
    'very',
    'was',
    'we',
    'were',
    'what',
    'when',
    'where',
    'which',
    'while',
    'who',
    'whom',
    'why',
    'will',
    'with',
    'you',
    'your',
  };

  /// Verbs that introduce a definition, e.g. "A stack is a structure ...".
  static final _definitionPattern = RegExp(
    r'^(.{3,60}?)\s+(?:is|are|refers to|means|is called|is known as)\s+(.{10,})$',
    caseSensitive: false,
  );

  static int countWords(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// Splits [text] into sentences, dropping fragments too short to revise.
  static List<String> splitSentences(String text) {
    final normalised = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalised.isEmpty) return const [];
    return normalised
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => countWords(sentence) >= 4)
        .toList();
  }

  static List<String> _words(String text) => text
      .toLowerCase()
      .split(RegExp(r"[^a-z0-9'+#-]+"))
      .where((word) => word.length > 2 && !_stopWords.contains(word))
      .toList();

  /// Terms the document returns to most often, most frequent first.
  static List<String> keyTerms(String text, {int limit = 8}) {
    final counts = <String, int>{};
    for (final word in _words(text)) {
      counts[word] = (counts[word] ?? 0) + 1;
    }
    final ranked = counts.entries.where((e) => e.value > 1).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return ranked.take(limit).map((entry) => entry.key).toList();
  }

  /// Sentences that define a term, keyed by the term.
  static Map<String, String> definitions(List<String> sentences) {
    final found = <String, String>{};
    for (final sentence in sentences) {
      final match = _definitionPattern.firstMatch(
        sentence.replaceAll(RegExp(r'[.!?]+$'), ''),
      );
      if (match == null) continue;
      final term = match.group(1)!.trim();
      // A definition subject is a short noun phrase, not half a paragraph.
      if (countWords(term) > 6 || term.isEmpty) continue;
      found.putIfAbsent(term, () => match.group(2)!.trim());
      if (found.length >= 6) break;
    }
    return found;
  }

  /// Generates short notes for [text].
  ///
  /// [title] names the source. [maxPoints] caps how many key points are kept.
  static ShortNotes generate(
    String text, {
    String title = 'Short notes',
    int maxPoints = 8,
  }) {
    final sentences = splitSentences(text);
    final sourceWordCount = countWords(text);
    if (sentences.isEmpty) {
      return ShortNotes(
        title: title,
        summary: '',
        keyPoints: const [],
        definitions: const {},
        keyTerms: const [],
        sourceWordCount: sourceWordCount,
      );
    }

    // Score each sentence by how many of the document's frequent terms it
    // carries, normalised by length so a long rambling sentence does not win
    // just by containing more words.
    final frequencies = <String, int>{};
    for (final word in _words(text)) {
      frequencies[word] = (frequencies[word] ?? 0) + 1;
    }
    final maxFrequency = frequencies.values.fold(1, (a, b) => a > b ? a : b);

    final scored = <({int index, String sentence, double score})>[];
    for (var index = 0; index < sentences.length; index++) {
      final sentence = sentences[index];
      final words = _words(sentence);
      if (words.isEmpty) continue;
      final weight =
          words
              .map((word) => (frequencies[word] ?? 0) / maxFrequency)
              .fold(0.0, (a, b) => a + b) /
          words.length;
      // Opening sentences usually state the topic, so give them a nudge.
      final positionBonus = index < 3 ? 0.15 : 0.0;
      scored.add((
        index: index,
        sentence: sentence,
        score: weight + positionBonus,
      ));
    }

    final ranked = [...scored]..sort((a, b) => b.score.compareTo(a.score));

    final summarySentences =
        (ranked.take(2).toList()..sort((a, b) => a.index.compareTo(b.index)))
            .map((entry) => entry.sentence)
            .toList();

    // Key points come from the rest, kept in document order so the notes
    // still read in the order the material was taught.
    //
    // How many to keep scales with the document: a fixed cap would return the
    // whole thing for a short passage, which is not a short note at all.
    final summarySet = summarySentences.toSet();
    final targetPoints = (sentences.length * 0.3).round().clamp(2, maxPoints);
    final points =
        (ranked
                .where((entry) => !summarySet.contains(entry.sentence))
                .take(targetPoints)
                .toList()
              ..sort((a, b) => a.index.compareTo(b.index)))
            .map((entry) => entry.sentence)
            .toList();

    return ShortNotes(
      title: title,
      summary: summarySentences.join(' '),
      keyPoints: points,
      definitions: definitions(sentences),
      keyTerms: keyTerms(text),
      sourceWordCount: sourceWordCount,
    );
  }
}
