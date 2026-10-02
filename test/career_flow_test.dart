import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_app/screens/jobs/career_flow_screen.dart';
import 'package:unix_app/services/career_analysis.dart';
import 'package:unix_app/services/local_career_ai.dart';
import 'package:unix_app/services/recruitment_documents.dart';
import 'package:unix_app/services/recruitment_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Extracts actual CV sections, including inline headings; leaves missing sections empty',
    () {
      final profile = CareerProfile.parse(
        'Jane\nEDUCATION: BSc Computing\nSKILLS\nFlutter, Dart\nPROJECTS\nStudent app',
      );
      expect(profile.sections['Education'], ['BSc Computing']);
      expect(profile.sections['Projects'], ['Student app']);
      expect(profile.sections['Experience'], isEmpty);
      expect(profile.sections['Other details'], ['Jane']);
      expect(() => CareerProfile.parse('  '), throwsFormatException);
    },
  );

  test(
    'Scores/ranking change with actual CV and ignore unspecified criteria',
    () {
      final data = CareerAnalysis.rank(
        CareerProfile.parse(sampleCareerCv),
        sampleCareerRequirements,
      );
      expect(data.first.id, 'sample-data-intern');
      expect(data.first.score, 100);
      final developer = CareerAnalysis.rank(
        CareerProfile.parse('Skills: Flutter Dart Git SQL Communication'),
        sampleCareerRequirements,
      );
      expect(developer.first.id, 'sample-flutter-intern');
      expect(developer.first.skills.missingSkills, isEmpty);
      final unrelated = CareerAnalysis.compare(
        CareerProfile.parse('Portrait artist'),
        {'id': 'art', 'text': 'Portrait painting'},
      );
      expect(unrelated.score, isNull);
      expect(unrelated.breakdown.values, everyElement(isNull));
      final uploaded = CareerAnalysis.compare(
        CareerProfile.parse('Skills: Flutter'),
        {'id': 'hr', 'text': 'Flutter, Dart'},
      );
      expect(uploaded.score, 50);
      expect(uploaded.breakdown['Education'], isNull);
    },
  );

  test(
    'Sample requirements are idempotent and preserve existing recruiter posts',
    () async {
      final store = RecruitmentStore();
      await store.saveRequirements({
        'id': 'real-hr',
        'ownerId': 'hr',
        'title': 'Designer',
        'company': 'Studio',
        'text': 'Figma',
      });
      await store.addSampleRequirements();
      await store.addSampleRequirements();
      final jobs = await store.requirements();
      expect(jobs, hasLength(5));
      expect(jobs.where((j) => j['id'] == 'real-hr').single['text'], 'Figma');
      expect(jobs.where((j) => j['sample'] == true), hasLength(4));
    },
  );

  test(
    'Local model receives evidence; unavailable/malformed models fall back honestly',
    () async {
      final match = CareerAnalysis.compare(
        CareerProfile.parse(sampleCareerCv),
        sampleCareerRequirements.first,
      );
      final client = MockClient((request) async {
        final data = jsonDecode(request.body) as Map;
        expect(data['context']['matchedSkills'], contains('Python'));
        expect(request.body, isNot(contains('2021–2025')));
        return http.Response(
          jsonEncode({
            'answer': 'Practise a SQL project.',
            'model': 'test-local',
          }),
          200,
        );
      });
      final answer = await LocalCareerAi.ask(
        match,
        'What should I learn?',
        client: client,
        useModel: true,
      );
      expect(answer.source, 'Local AI · test-local');
      expect(answer.text, contains('SQL project'));
      for (final response in [
        http.Response('unavailable', 503),
        http.Response('{}', 200),
      ]) {
        final fallback = await LocalCareerAi.ask(
          match,
          'Why this score?',
          client: MockClient((_) async => response),
          useModel: true,
        );
        expect(fallback.source, contains('unavailable'));
        expect(fallback.text, contains('6 of 6'));
      }
    },
  );

  testWidgets(
    'Upload, extracted sections, match, jobs, filters and assistant work on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CareerFlowScreen(
            accountId: 'student',
            pickDocument: () async =>
                const RecruitmentDocument('student.txt', sampleCareerCv),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tapText(String text) async {
        final finder = find.text(text);
        await tester.scrollUntilVisible(
          finder,
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tapText('Analyse my CV');
      expect(
        find.text('Upload or paste a CV with 1–100,000 characters.'),
        findsOneWidget,
      );
      await tapText('Click to browse your CV');
      await tapText('Analyse my CV');
      expect(find.text('CV Analysis'), findsOneWidget);
      expect(find.text('BSc in Data Science, SLTC, 2021–2025'), findsOneWidget);
      await tapText('Continue to skill match');
      expect(find.text('Skill Match Analysis'), findsOneWidget);
      expect(find.text('100%\nMatch'), findsOneWidget);
      await tapText('See matching jobs');
      expect(find.text('Top jobs for you'), findsOneWidget);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full-time').last);
      await tester.pumpAndSettle();
      expect(find.text('Junior Data Analyst'), findsOneWidget);
      expect(find.text('Data Analyst Intern'), findsNothing);
      await tapText('Ask AI');
      await tester.tap(find.text('Why this score?'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('6 of 6 recognised required skills'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(
        (await RecruitmentStore().loadCv('student'))['name'],
        'student.txt',
      );
    },
  );
}
