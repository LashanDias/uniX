import '../models/app_models.dart';

class NotesCatalog {
  static const ict = <String, List<String>>{
    'Common': [
      'Statistics',
      'Mathematics for IT',
      'Academic English',
      'Programming Fundamentals',
      'General ICT',
    ],
    'Data Science': [
      'Data Analytics',
      'Machine Learning',
      'Data Visualisation',
    ],
    'Software Engineering': [
      'Data Structures & Algorithms',
      'Software Design',
      'Software Testing',
    ],
    'Computer Science': [
      'Algorithms',
      'Operating Systems',
      'Computer Architecture',
    ],
    'Information Technology': [
      'Databases',
      'Web Development',
      'Information Systems',
    ],
    'Cyber Security': ['Network Security', 'Cryptography', 'Digital Forensics'],
    'Networking': [
      'Communication Networks',
      'Cloud Computing',
      'Network Administration',
    ],
  };
  static const subjects = <String, List<String>>{
    'English': ['Academic Writing', 'Grammar', 'Communication'],
    'Mathematics': ['Statistics', 'Linear Algebra', 'Calculus'],
    'Science': ['Physics', 'Chemistry', 'Biology'],
  };
  static String degree(NoteItem note) => note.degree.isNotEmpty
      ? note.degree
      : note.title.contains('Networks')
      ? 'Networking'
      : note.title.contains('Data Structures')
      ? 'Software Engineering'
      : 'Common';
  static String topic(NoteItem note) {
    if (note.topic.isNotEmpty) return note.topic;
    if (note.title.contains('Networks')) return 'Communication Networks';
    if (note.title.contains('Data Structures')) {
      return 'Data Structures & Algorithms';
    }
    if (note.title.contains('Grammar')) return 'Grammar';
    if (note.title.contains('Linear Algebra')) return 'Linear Algebra';
    return note.subject == 'ICT' ? 'General ICT' : 'General';
  }

  static bool matches(
    NoteItem note,
    String subject,
    String? category,
    String? selectedTopic,
  ) {
    final shared =
        subject == 'ICT' &&
        category == 'Common' &&
        ((note.subject == 'Mathematics' && topic(note) == 'Statistics') ||
            (note.subject == 'English' && topic(note) == 'Academic Writing'));
    if (!shared && note.subject != subject) return false;
    if (!shared && category != null && degree(note) != category) return false;
    return selectedTopic == null ||
        topic(note) == selectedTopic ||
        (selectedTopic == 'Academic English' &&
            shared &&
            note.subject == 'English');
  }
}
