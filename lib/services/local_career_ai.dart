import 'dart:convert';
import 'package:http/http.dart' as http;
import 'career_analysis.dart';

class CareerReply {
  const CareerReply(this.text, this.source);
  final String text, source;
}

class LocalCareerAi {
  static const enabled = bool.fromEnvironment('LOCAL_CAREER_AI');
  static const endpoint = String.fromEnvironment(
    'LOCAL_CAREER_AI_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );

  static Future<CareerReply> ask(
    CareerMatch match,
    String question, {
    http.Client? client,
    bool useModel = enabled,
  }) async {
    if (useModel) {
      final connection = client ?? http.Client();
      try {
        final response = await connection
            .post(
              Uri.parse('$endpoint/career/chat'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'question': question,
                // Do not send names, contact details or the full CV to the model.
                'context': {
                  'jobTitle': match.job['title'],
                  'requirements': match.job['text'],
                  'coverage': match.score,
                  'matchedSkills': match.skills.matchedSkills,
                  'missingSkills': match.skills.missingSkills,
                  'breakdown': match.breakdown,
                },
              }),
            )
            .timeout(const Duration(seconds: 65));
        if (response.statusCode != 200) throw StateError('Model unavailable');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answer = data['answer'];
        if (answer is! String || answer.trim().isEmpty) {
          throw StateError('Empty answer');
        }
        return CareerReply(answer, 'Local AI · ${data['model'] ?? 'Ollama'}');
      } catch (_) {
        return CareerReply(
          CareerAnalysis.advice(match, question),
          'Offline guidance · local AI model unavailable',
        );
      } finally {
        if (client == null) connection.close();
      }
    }
    return CareerReply(
      CareerAnalysis.advice(match, question),
      'Offline guidance · no language model',
    );
  }
}
