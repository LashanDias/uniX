import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/career_ai_service.dart';

void main() {
  test('returns a friendly local fallback response without placeholder wording', () async {
    final result = await CareerAiService.analyze('hello');

    expect(result, contains('I reviewed your message'));
    expect(result, contains('Priority focus: hello'));
    expect(result, isNot(contains('Local career assistant analyzed')));
    expect(result, isNot(contains('Connect a hosted AI endpoint')));
  });
}
