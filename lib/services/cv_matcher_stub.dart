Future<void> initialize() async {}

Future<Map<String, dynamic>> matchCV(
  String cvText,
  List<Map<String, dynamic>> requirements,
) async => {
  'total': 0,
  'items': requirements
      .map(
        (requirement) => {
          'requirement': '${requirement['text'] ?? ''}',
          'score': 0,
          'label': 'Gap',
          'evidence': '',
        },
      )
      .toList(),
};

Future<void> addConcept(String name, List<String> words) async {}
