import 'cv_comparison_service.dart';

/// Local, evidence-based matching. Scores describe document coverage, not
/// hiring probability. Missing requirements are excluded, never invented.
class CareerProfile {
  CareerProfile(this.text, this.sections);
  final String text;
  final Map<String, List<String>> sections;

  static CareerProfile parse(String text) {
    if (text.trim().isEmpty) throw const FormatException('Add your CV first.');
    final sections = <String, List<String>>{
      'Education': [],
      'Certifications': [],
      'Projects': [],
      'Experience': [],
      'Skills': [],
      'Other details': [],
    };
    var current = 'Other details';
    final headings = <String, String>{
      'education': 'Education',
      'academic qualifications': 'Education',
      'qualifications': 'Education',
      'certifications': 'Certifications',
      'certificates': 'Certifications',
      'certification': 'Certifications',
      'projects': 'Projects',
      'project': 'Projects',
      'personal projects': 'Projects',
      'experience': 'Experience',
      'work experience': 'Experience',
      'professional experience': 'Experience',
      'employment': 'Experience',
      'skills': 'Skills',
      'technical skills': 'Skills',
      'summary': 'Other details',
      'profile': 'Other details',
      'contact': 'Other details',
      'references': 'Other details',
    };
    for (final raw in text.split(RegExp(r'[\r\n]+'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final colon = line.indexOf(':');
      final heading = (colon < 0 ? line : line.substring(0, colon))
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z ]'), '')
          .trim();
      if (headings.containsKey(heading)) {
        current = headings[heading]!;
        if (colon >= 0 && line.substring(colon + 1).trim().isNotEmpty) {
          sections[current]!.add(line.substring(colon + 1).trim());
        }
      } else {
        sections[current]!.add(line);
      }
    }
    return CareerProfile(text.trim(), sections);
  }
}

class CareerMatch {
  CareerMatch(this.job, this.skills, this.breakdown);
  final Map<String, dynamic> job;
  final CvComparison skills;
  final Map<String, int?> breakdown;
  String get id => job['id'] as String;
  int? get score {
    const weights = {
      'Skills': 70,
      'Education': 10,
      'Experience': 10,
      'Location': 10,
    };
    var sum = 0, total = 0;
    for (final entry in breakdown.entries) {
      if (entry.value == null) continue;
      sum += entry.value! * weights[entry.key]!;
      total += weights[entry.key]!;
    }
    return total == 0 ? null : (sum / total).round();
  }
}

class CareerAnalysis {
  static CareerMatch compare(CareerProfile cv, Map<String, dynamic> job) {
    final requirements = '${job['text'] ?? ''}'.trim();
    final skills = requirements.isEmpty
        ? const CvComparison([], [], [])
        : CvComparisonService.compare(cv.text, requirements);
    final degree = '${job['education'] ?? ''}'.trim();
    final years = job['minimumYears'] as int?;
    final location = '${job['location'] ?? ''}'.trim();
    final yearsInCv = RegExp(r'(\d+)\+?\s*years?\b', caseSensitive: false)
        .allMatches(cv.sections['Experience']!.join(' '))
        .map((m) => int.parse(m[1]!))
        .fold(0, (a, b) => a > b ? a : b);
    final education = cv.sections['Education']!.join(' ').toLowerCase();
    return CareerMatch(job, skills, {
      'Skills': skills.coverage,
      'Education': degree.isEmpty
          ? null
          : (degree == 'Bachelor'
                ? RegExp(r'\b(bsc|beng|bachelor|btech)\b').hasMatch(education)
                : education.contains(degree.toLowerCase()))
          ? 100
          : 0,
      'Experience': years == null
          ? null
          : (years == 0 || yearsInCv >= years ? 100 : 0),
      'Location': location.isEmpty
          ? null
          : (location.toLowerCase() == 'remote' ||
                    cv.text.toLowerCase().contains(location.toLowerCase())
                ? 100
                : 0),
    });
  }

  static List<CareerMatch> rank(
    CareerProfile cv,
    List<Map<String, dynamic>> jobs,
  ) {
    final matches = jobs.map((job) => compare(cv, job)).toList();
    matches.sort((a, b) {
      final score = (b.score ?? -1).compareTo(a.score ?? -1);
      return score == 0 ? a.id.compareTo(b.id) : score;
    });
    return matches;
  }

  static String advice(CareerMatch match, String question) {
    final missing = match.skills.missingSkills;
    final matched = match.skills.matchedSkills;
    final q = question.toLowerCase();
    if (q.contains('interview')) {
      return 'For ${match.job['title']}, prepare a project example explaining ${matched.isEmpty ? 'your relevant skills' : matched.take(3).join(', ')}. '
          'Describe the problem, your contribution and a measurable result. '
          '${missing.isEmpty ? 'Be ready to demonstrate the skills listed in your CV.' : 'Practise questions about ${missing.take(3).join(', ')}; these requirements were not found in your CV.'}';
    }
    if (q.contains('why') || q.contains('score') || q.contains('match')) {
      return '${match.job['title']}: ${match.skills.matchedSkills.length} of ${match.skills.requiredSkills.length} recognised required skills appear in your CV. '
          'Matched: ${matched.isEmpty ? 'none detected' : matched.join(', ')}. '
          'Not found: ${missing.isEmpty ? 'none' : missing.join(', ')}. '
          'The overall score weights skills 70%, and explicit education, experience and location criteria 10% each. Unspecified criteria are excluded. This is document coverage, not a hiring prediction.';
    }
    if (q.contains('learn') ||
        q.contains('improve') ||
        q.contains('plan') ||
        q.contains('skill')) {
      return missing.isEmpty
          ? 'All recognised skills for this role appear in your CV. Add concise project evidence and measurable outcomes to show how you used them.'
          : 'Start with ${missing.first}. Learn the fundamentals, complete a small project, and add the resulting evidence to your CV only once you have done the work. '
                'Then practise ${missing.skip(1).isEmpty ? missing.first : missing.skip(1).take(3).join(', ')}. Re-analyse your updated CV to check coverage.';
    }
    return 'I can explain your match for ${match.job['title']}, suggest skills to practise, or help prepare for an interview. '
        'Try “Why this score?”, “What should I learn?” or “Help me prepare for an interview”. '
        'This offline assistant uses your CV and the selected requirements; it is not a general-purpose language model.';
  }
}

const sampleCareerCv = '''Sample student • Colombo
Education
BSc in Data Science, SLTC, 2021–2025
Certifications
Google Data Analytics certificate
Projects
Sales dashboard using Power BI and SQL
Customer segmentation with Python and Pandas
Experience
Data Analyst Intern — student placement, 1 year
Skills
Python, SQL, Power BI, Pandas, Excel, Data analysis, Communication, Problem solving
''';

const sampleCareerRequirements = <Map<String, dynamic>>[
  {
    'id': 'sample-data-intern',
    'ownerId': 'sample-hr',
    'sample': true,
    'title': 'Data Analyst Intern',
    'company': 'Campus Analytics (sample)',
    'contactName': 'Sample HR Manager',
    'fileName': 'data-analyst-intern.txt',
    'type': 'Internship',
    'location': 'Colombo',
    'workMode': 'Hybrid',
    'education': 'Bachelor',
    'minimumYears': 0,
    'text':
        'Python, SQL, Excel, Power BI, Data analysis, Communication. Bachelor degree or undergraduate. No prior professional experience required. Colombo, hybrid.',
  },
  {
    'id': 'sample-junior-analyst',
    'ownerId': 'sample-hr',
    'sample': true,
    'title': 'Junior Data Analyst',
    'company': 'Island Software (sample)',
    'contactName': 'Sample HR Manager',
    'fileName': 'junior-data-analyst.txt',
    'type': 'Full-time',
    'location': 'Colombo',
    'workMode': 'On-site',
    'education': 'Bachelor',
    'minimumYears': 1,
    'text':
        'Python, SQL, Pandas, Tableau, Statistics, Communication. Bachelor degree. At least 1 year experience. Colombo.',
  },
  {
    'id': 'sample-bi-intern',
    'ownerId': 'sample-hr',
    'sample': true,
    'title': 'Business Intelligence Intern',
    'company': 'Lanka Insights (sample)',
    'contactName': 'Sample HR Manager',
    'fileName': 'bi-intern.txt',
    'type': 'Internship',
    'location': 'Remote',
    'workMode': 'Remote',
    'education': 'Bachelor',
    'minimumYears': 0,
    'text':
        'SQL, Power BI, Excel, Azure, Data visualization, Problem solving. Bachelor degree or undergraduate. No experience required. Remote.',
  },
  {
    'id': 'sample-flutter-intern',
    'ownerId': 'sample-hr',
    'sample': true,
    'title': 'Mobile Developer Intern',
    'company': 'Uni Apps Studio (sample)',
    'contactName': 'Sample HR Manager',
    'fileName': 'mobile-developer.txt',
    'type': 'Internship',
    'location': 'Remote',
    'workMode': 'Remote',
    'minimumYears': 0,
    'text':
        'Flutter, Dart, Git, SQL, Communication. Build and test student mobile applications. Remote internship, no prior professional experience required.',
  },
];
