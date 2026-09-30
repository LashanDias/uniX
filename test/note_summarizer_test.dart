import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/note_summarizer.dart';

/// A lecture-note style passage, long enough to actually condense.
const _lecture = '''
A stack is a linear data structure that follows the last in first out
principle. Elements are added and removed from one end only, called the top
of the stack. The push operation adds an element to the top of the stack.
The pop operation removes the element currently at the top of the stack.
A queue is a linear data structure that follows the first in first out
principle. Stacks are used for undo features, expression evaluation and
recursion. Every recursive call places a new frame on the call stack.
When the stack has no space left the program reports a stack overflow.
It was raining outside the lecture hall that afternoon.
''';

void main() {
  group('splitSentences', () {
    test('drops fragments too short to revise', () {
      final sentences = NoteSummarizer.splitSentences('Yes. No. A stack is a linear structure used widely.');
      expect(sentences, hasLength(1));
      expect(sentences.single, startsWith('A stack is'));
    });

    test('returns nothing for empty input', () {
      expect(NoteSummarizer.splitSentences('   '), isEmpty);
    });
  });

  group('keyTerms', () {
    test('surfaces the repeated subject words', () {
      final terms = NoteSummarizer.keyTerms(_lecture);
      expect(terms, contains('stack'));
      expect(terms.length, lessThanOrEqualTo(8));
    });

    test('ignores common filler words', () {
      final terms = NoteSummarizer.keyTerms(_lecture);
      expect(terms, isNot(contains('the')));
      expect(terms, isNot(contains('that')));
      expect(terms, isNot(contains('and')));
    });
  });

  group('definitions', () {
    test('extracts the term being defined', () {
      final found = NoteSummarizer.definitions(
        NoteSummarizer.splitSentences(_lecture),
      );
      expect(found.keys, contains('A stack'));
      expect(found['A stack'], contains('last in first out'));
    });

    test('ignores a sentence whose subject is a whole clause', () {
      final found = NoteSummarizer.definitions([
        'The thing that really matters here when you think about it '
            'carefully is something else entirely.',
      ]);
      expect(found, isEmpty);
    });
  });

  group('generate', () {
    test('produces notes shorter than the source', () {
      final notes = NoteSummarizer.generate(_lecture, title: 'Data structures');
      expect(notes.isEmpty, isFalse);
      expect(notes.shortWordCount, lessThan(notes.sourceWordCount));
      expect(notes.reductionPercent, greaterThan(0));
    });

    test('names the source', () {
      final notes = NoteSummarizer.generate(_lecture, title: 'Data structures');
      expect(notes.title, 'Data structures');
    });

    test('only ever reuses the source text, never invents a sentence', () {
      final notes = NoteSummarizer.generate(_lecture);
      final source = NoteSummarizer.splitSentences(_lecture);
      for (final point in notes.keyPoints) {
        expect(source, contains(point));
      }
    });

    test('keeps key points in the order they were taught', () {
      final notes = NoteSummarizer.generate(_lecture);
      final source = NoteSummarizer.splitSentences(_lecture);
      final indices = notes.keyPoints.map(source.indexOf).toList();
      final sorted = [...indices]..sort();
      expect(indices, orderedEquals(sorted));
    });

    test('respects maxPoints', () {
      final notes = NoteSummarizer.generate(_lecture, maxPoints: 3);
      expect(notes.keyPoints.length, lessThanOrEqualTo(3));
    });

    test('drops the off-topic sentence before the on-topic ones', () {
      final notes = NoteSummarizer.generate(_lecture, maxPoints: 3);
      final kept = [notes.summary, ...notes.keyPoints].join(' ');
      expect(kept, isNot(contains('raining outside')));
    });

    test('handles empty input without throwing', () {
      final notes = NoteSummarizer.generate('   ', title: 'Nothing');
      expect(notes.isEmpty, isTrue);
      expect(notes.keyPoints, isEmpty);
      expect(notes.reductionPercent, 0);
    });
  });

  group('toPlainText', () {
    test('includes every section that has content', () {
      final text = NoteSummarizer.generate(
        _lecture,
        title: 'Data structures',
      ).toPlainText();
      expect(text, startsWith('Data structures'));
      expect(text, contains('SUMMARY'));
      expect(text, contains('KEY POINTS'));
      expect(text, contains('KEY TERMS'));
    });
  });
}
