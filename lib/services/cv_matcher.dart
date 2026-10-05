import 'cv_matcher_stub.dart'
    if (dart.library.js_interop) 'cv_matcher_web.dart'
    as implementation;

Future<void> initializeCvMatcher() => implementation.initialize();

Future<Map<String, dynamic>> matchCV(
  String cvText,
  List<Map<String, dynamic>> requirements,
) => implementation.matchCV(cvText, requirements);

Future<void> addCvConcept(String name, List<String> words) =>
    implementation.addConcept(name, words);
