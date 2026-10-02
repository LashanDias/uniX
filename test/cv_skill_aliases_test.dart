import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/cv_comparison_service.dart';

/// Skill matching is the heart of CV analysis and job recommendations: a skill
/// the matcher fails to recognise is reported to the student as one they do
/// not have, which is worse than no advice at all.
///
/// These pin the spellings students actually write.
void main() {
  CvComparison compare(String cv, String requirements) =>
      CvComparisonService.compare(cv, requirements);

  group('a skill written the usual way is recognised', () {
    test('ASP.NET counts as .NET', () {
      // The word boundary before the dot meant ".net" never matched inside
      // "ASP.NET", so this CV scored 0% against a .NET vacancy.
      final result = compare('Experienced with ASP.NET and C#', '.NET developer');
      expect(result.requiredSkills, contains('.NET'));
      expect(result.matchedSkills, contains('.NET'));
      expect(result.missingSkills, isNot(contains('.NET')));
    });

    test('Node JS with a space counts as Node.js', () {
      final result = compare('I know Node JS and React', 'Node.js required');
      expect(result.matchedSkills, contains('Node.js'));
      expect(result.missingSkills, isNot(contains('Node.js')));
    });

    test('dot net written as two words counts as .NET', () {
      final result = compare('dot net framework', '.NET developer');
      expect(result.matchedSkills, contains('.NET'));
    });
  });

  group('a skill the student does not have is not invented', () {
    test('JavaScript on a CV is not read as Java', () {
      // These are different languages; conflating them would overstate the
      // match on every Java vacancy.
      final result = compare('JavaScript expert', 'Java required');
      expect(result.requiredSkills, contains('Java'));
      expect(result.matchedSkills, isEmpty);
      expect(result.coverage, 0);
    });

    test('a missing skill stays missing', () {
      final result = compare('Python and SQL', 'Python, SQL and Docker');
      expect(result.missingSkills, contains('Docker'));
      expect(result.matchedSkills, containsAll(['Python', 'SQL']));
    });
  });

  group('spelling and punctuation do not change the result', () {
    test('case is ignored', () {
      expect(compare('PYTHON, sql', 'Python and SQL').coverage, 100);
    });

    test('a trailing full stop does not hide a skill', () {
      expect(compare('Skills: Python, SQL.', 'Python, SQL').coverage, 100);
    });

    test('problem-solving matches problem solving', () {
      expect(compare('problem-solving mindset', 'Problem solving').coverage, 100);
    });

    test('C++ survives being made of punctuation', () {
      expect(compare('C++ and C# programming', 'C++ developer').coverage, 100);
    });
  });

  test('coverage is null when the vacancy lists no recognised skill', () {
    // Nothing to measure against, so the score must be absent rather than 0 --
    // 0% would read as "you match nothing" when nothing was asked for.
    expect(compare('Python developer', 'Must be punctual and polite').coverage, isNull);
  });

  test('an empty CV or vacancy is refused rather than scored', () {
    expect(() => compare('', 'Python'), throwsFormatException);
    expect(() => compare('Python', ''), throwsFormatException);
  });
}
