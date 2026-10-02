import 'package:cloud_functions/cloud_functions.dart';

class CvComparison {
  const CvComparison(
    this.requiredSkills,
    this.matchedSkills,
    this.missingSkills,
  );
  final List<String> requiredSkills;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  int? get coverage => requiredSkills.isEmpty
      ? null
      : (matchedSkills.length / requiredSkills.length * 100).round();
}

class CvComparisonService {
  static const aiEnabled = bool.fromEnvironment('CAREER_AI_ENABLED');
  static const skills = <String, List<String>>{
    'Flutter': ['flutter'],
    'Dart': ['dart'],
    'Python': ['python'],
    'Java': ['java'],
    'JavaScript': ['javascript', 'js'],
    'TypeScript': ['typescript'],
    'React': ['react', 'reactjs'],
    'Node.js': ['node.js', 'nodejs'],
    'SQL': ['sql', 'mysql', 'postgresql'],
    'HTML': ['html', 'html5'],
    'CSS': ['css', 'css3'],
    'Git': ['git', 'github', 'gitlab'],
    'Figma': ['figma'],
    'UI/UX': ['ui/ux', 'ux design', 'ui design', 'user experience'],
    'Excel': ['excel'],
    'Power BI': ['power bi', 'powerbi'],
    'Tableau': ['tableau'],
    'Pandas': ['pandas'],
    'Machine learning': ['machine learning'],
    'Data analysis': ['data analysis', 'data analytics'],
    'Statistics': ['statistics', 'statistical analysis'],
    'Data visualization': ['data visualization', 'data visualisation'],
    'Advanced SQL': ['advanced sql', 'window functions', 'query optimization'],
    'Cloud computing': ['cloud computing'],
    'C++': ['c++'],
    'C#': ['c#'],
    '.NET': ['.net', 'dotnet'],
    'AWS': ['aws', 'amazon web services'],
    'Azure': ['azure'],
    'Docker': ['docker'],
    'Linux': ['linux'],
    'AutoCAD': ['autocad'],
    'SolidWorks': ['solidworks'],
    'Photoshop': ['photoshop'],
    'Illustrator': ['illustrator'],
    'Accounting': ['accounting'],
    'Marketing': ['marketing'],
    'Communication': ['communication'],
    'Teamwork': ['teamwork', 'team work', 'team collaboration'],
    'Project management': ['project management'],
    'Customer service': ['customer service'],
    'Problem solving': ['problem solving', 'problem-solving'],
  };

  static bool _contains(String text, String term) => RegExp(
    '(?<![a-z0-9])${RegExp.escape(term)}(?![a-z0-9])',
    caseSensitive: false,
  ).hasMatch(text);

  static CvComparison compare(String cv, String requirements) {
    if (cv.trim().isEmpty || requirements.trim().isEmpty) {
      throw const FormatException(
        'Add both a student CV and HR requirements first.',
      );
    }
    final required = skills.entries
        .where(
          (entry) => entry.value.any((alias) => _contains(requirements, alias)),
        )
        .map((entry) => entry.key)
        .toList();
    final matched = required
        .where((skill) => skills[skill]!.any((alias) => _contains(cv, alias)))
        .toList();
    return CvComparison(
      required,
      matched,
      required.where((skill) => !matched.contains(skill)).toList(),
    );
  }

  static Future<String> aiReview(String cv, String requirements) async {
    if (!aiEnabled) throw StateError('AI review is not configured.');
    final response = await FirebaseFunctions.instance
        .httpsCallable('compareCvRequirements')
        .call({'cvText': cv, 'requirementsText': requirements});
    final data = response.data;
    if (data is! Map ||
        data['summary'] is! String ||
        (data['summary'] as String).trim().isEmpty) {
      throw StateError('AI review returned no usable result.');
    }
    return data['summary'] as String;
  }
}
