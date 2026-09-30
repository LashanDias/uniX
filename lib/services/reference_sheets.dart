import 'package:flutter/material.dart';

/// One numbered block on a formula reference sheet.
class FormulaEntry {
  const FormulaEntry({
    required this.title,
    required this.formulas,
    required this.whenToUse,
    required this.colour,
  });

  final String title;

  /// Formulas for this concept, keyed by the case they apply to.
  ///
  /// The key is empty when there is only one form, e.g. the range.
  final Map<String, String> formulas;

  /// Short bullets answering "when to use it?".
  final List<String> whenToUse;

  /// Accent colour for the block, so the sheet is easy to scan.
  final Color colour;
}

/// A one-page formula sheet for a module.
class ReferenceSheet {
  const ReferenceSheet({
    required this.id,
    required this.subject,
    this.degreeGroup = 'Common',
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.entries,
    this.quickReminder = const {},
  });

  final String id;

  /// Module this sheet belongs to, matching the notes catalogue topics.
  final String subject;

  /// Degree group from NotesCatalog, e.g. Common or Data Science.
  ///
  /// Statistics and probability are taught to every IT degree, so they sit
  /// under Common rather than under one degree.
  final String degreeGroup;

  /// Where the sheet sits in the module tree, e.g. "Common · Statistics".
  String get modulePath => '$degreeGroup · $subject';

  final String title;
  final String subtitle;

  /// One line describing what the sheet covers.
  final String summary;

  final List<FormulaEntry> entries;

  /// Short "X means Y" pairs for the footer.
  final Map<String, String> quickReminder;

  bool matches(String term) {
    final needle = term.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return title.toLowerCase().contains(needle) ||
        subject.toLowerCase().contains(needle) ||
        degreeGroup.toLowerCase().contains(needle) ||
        summary.toLowerCase().contains(needle) ||
        entries.any((entry) => entry.title.toLowerCase().contains(needle));
  }
}

/// Formula sheets that ship with the app.
///
/// Formulas are written in Unicode rather than LaTeX so they render with no
/// extra package: x̄, Σ, σ², √ and µ all display in the standard font.
class ReferenceSheets {
  static const _blue = Color(0xFF3B82F6);
  static const _green = Color(0xFF10B981);
  static const _purple = Color(0xFF8B5CF6);
  static const _orange = Color(0xFFF97316);
  static const _teal = Color(0xFF14B8A6);
  static const _pink = Color(0xFFEC4899);

  static const statistics = ReferenceSheet(
    id: 'sheet-statistics',
    subject: 'Statistics',
    title: 'Statistics',
    subtitle: 'Essential Formula Reference Sheet',
    summary:
        'Key formulas for mean, variance, standard deviation and more.',
    quickReminder: {
      'Mean': 'Average',
      'Variance': 'Spread squared',
      'Standard deviation': 'Spread',
    },
    entries: [
      FormulaEntry(
        title: 'Mean',
        colour: _blue,
        formulas: {
          'For ungrouped data': 'x̄ = Σx / n',
          'For frequency data': 'x̄ = Σfx / Σf',
        },
        whenToUse: [
          'To find the average of a set of values.',
          'Use the frequency formula for data in a frequency table '
              '(grouped data).',
        ],
      ),
      FormulaEntry(
        title: 'Weighted Mean',
        colour: _green,
        formulas: {'': 'x̄ = Σwx / Σw'},
        whenToUse: [
          'When values have different levels of importance (weights).',
          'Commonly used in averages with weights, e.g. grades and scores.',
        ],
      ),
      FormulaEntry(
        title: 'Range',
        colour: _purple,
        formulas: {'': 'Range = Maximum − Minimum'},
        whenToUse: [
          'Gives a quick idea of the spread of the data.',
          'Useful for a simple measure of variability.',
        ],
      ),
      FormulaEntry(
        title: 'Variance',
        colour: _orange,
        formulas: {
          'Population': 'σ² = Σ(x − μ)² / N',
          'Sample': 's² = Σ(x − x̄)² / (n − 1)',
        },
        whenToUse: [
          'Measures the average squared deviation from the mean.',
          'Used for both population and sample data.',
        ],
      ),
      FormulaEntry(
        title: 'Standard Deviation',
        colour: _teal,
        formulas: {'': 'σ = √σ²'},
        whenToUse: [
          'Gives the typical distance of data points from the mean.',
          'Expressed in the same units as the data.',
        ],
      ),
      FormulaEntry(
        title: 'Coefficient of Variation',
        colour: _pink,
        formulas: {'': 'CV = (σ / μ) × 100%'},
        whenToUse: [
          'Compares the relative variability of two datasets.',
          'Useful when the means are different.',
        ],
      ),
    ],
  );

  static const probability = ReferenceSheet(
    id: 'sheet-probability',
    subject: 'Statistics',
    title: 'Probability',
    subtitle: 'Essential Formula Reference Sheet',
    summary: 'Rules for combining events, conditional probability and Bayes.',
    quickReminder: {
      'Independent': 'One does not affect the other',
      'Mutually exclusive': 'Cannot both happen',
    },
    entries: [
      FormulaEntry(
        title: 'Basic Probability',
        colour: _blue,
        formulas: {'': 'P(A) = favourable outcomes / total outcomes'},
        whenToUse: [
          'When every outcome is equally likely.',
          'Always between 0 and 1.',
        ],
      ),
      FormulaEntry(
        title: 'Addition Rule',
        colour: _green,
        formulas: {
          'General': 'P(A ∪ B) = P(A) + P(B) − P(A ∩ B)',
          'Mutually exclusive': 'P(A ∪ B) = P(A) + P(B)',
        },
        whenToUse: [
          'For the chance that A or B happens.',
          'Drop the overlap term only when A and B cannot both occur.',
        ],
      ),
      FormulaEntry(
        title: 'Multiplication Rule',
        colour: _purple,
        formulas: {
          'General': 'P(A ∩ B) = P(A) × P(B | A)',
          'Independent': 'P(A ∩ B) = P(A) × P(B)',
        },
        whenToUse: [
          'For the chance that A and B both happen.',
          'Use the independent form only when A does not change B.',
        ],
      ),
      FormulaEntry(
        title: 'Conditional Probability',
        colour: _orange,
        formulas: {'': 'P(A | B) = P(A ∩ B) / P(B)'},
        whenToUse: [
          'The chance of A given that B has already happened.',
          'Undefined when P(B) = 0.',
        ],
      ),
      FormulaEntry(
        title: "Bayes' Theorem",
        colour: _teal,
        formulas: {'': 'P(A | B) = P(B | A) × P(A) / P(B)'},
        whenToUse: [
          'To reverse a conditional probability.',
          'Used in spam filters, medical tests and classification.',
        ],
      ),
    ],
  );

  static const bigO = ReferenceSheet(
    id: 'sheet-complexity',
    subject: 'Data Structures & Algorithms',
    degreeGroup: 'Software Engineering',
    title: 'Time Complexity',
    subtitle: 'Big-O Reference Sheet',
    summary: 'How the common algorithms and structures scale with input size.',
    quickReminder: {
      'O(1)': 'Same time whatever n is',
      'O(n)': 'Doubles when n doubles',
      'O(n log n)': 'Best a comparison sort can do',
    },
    entries: [
      FormulaEntry(
        title: 'Constant and Logarithmic',
        colour: _green,
        formulas: {
          'Constant': 'O(1)',
          'Logarithmic': 'O(log n)',
        },
        whenToUse: [
          'Array index access and hash lookups are O(1).',
          'Binary search is O(log n): it halves the data each step.',
        ],
      ),
      FormulaEntry(
        title: 'Linear and Linearithmic',
        colour: _blue,
        formulas: {
          'Linear': 'O(n)',
          'Linearithmic': 'O(n log n)',
        },
        whenToUse: [
          'One pass over the data is O(n).',
          'Merge sort, heap sort and Dart\'s List.sort are O(n log n).',
        ],
      ),
      FormulaEntry(
        title: 'Quadratic and worse',
        colour: _orange,
        formulas: {
          'Quadratic': 'O(n²)',
          'Exponential': 'O(2ⁿ)',
        },
        whenToUse: [
          'Nested loops over the same data give O(n²).',
          'Bubble and insertion sort are O(n²) in the worst case.',
          'Avoid O(2ⁿ) for anything but tiny inputs.',
        ],
      ),
      FormulaEntry(
        title: 'Common structures',
        colour: _purple,
        formulas: {
          'Hash map': 'search O(1), worst O(n)',
          'Balanced tree': 'search O(log n)',
        },
        whenToUse: [
          'Hash maps are fastest on average but degrade with collisions.',
          'Balanced trees keep O(log n) and stay sorted.',
        ],
      ),
    ],
  );

  static const all = [statistics, probability, bigO];

  /// Sheets for [subject], or all of them when no subject is given.
  static List<ReferenceSheet> forSubject(String? subject) => subject == null
      ? all
      : all.where((sheet) => sheet.subject == subject).toList();
}
