import 'dart:convert';
import 'dart:js_interop';

@JS('cvMatcherReady')
external JSPromise<JSAny?> get _cvMatcherReady;

@JS('matchCVJson')
external JSString _matchCVJson(JSString cvText, JSString requirementsJson);

@JS('addCvConceptJson')
external void _addCvConceptJson(JSString name, JSString wordsJson);

Future<void> initialize() async {
  await _cvMatcherReady.toDart;
}

Future<Map<String, dynamic>> matchCV(
  String cvText,
  List<Map<String, dynamic>> requirements,
) async {
  await initialize();
  final result = _matchCVJson(
    cvText.toJS,
    jsonEncode(requirements).toJS,
  ).toDart;
  return Map<String, dynamic>.from(jsonDecode(result) as Map);
}

Future<void> addConcept(String name, List<String> words) async {
  await initialize();
  _addCvConceptJson(name.toJS, jsonEncode(words).toJS);
}
