import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/models/app_models.dart';
import 'package:unix_app/screens/recruiter/post_job_screen.dart';
import 'package:unix_app/screens/jobs/job_listing_card.dart';
import 'package:unix_app/screens/jobs/top_jobs_screen.dart';

void main() {
  testWidgets('Live vacancy stream updates the student job board', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final jobs = StreamController<List<JobItem>>();
    addTearDown(jobs.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopJobsScreen(onPrev: () {}, jobsStream: jobs.stream),
        ),
      ),
    );
    jobs.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No vacancies have been posted yet.'), findsOneWidget);
    jobs.add([
      JobItem(
        id: 'live-1',
        title: 'New recruiter vacancy',
        company: 'New company',
        location: 'Remote',
        type: 'Internship',
        matchPercentage: 0,
        logoUrl: '',
        requirements: 'Flutter and Dart',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('New recruiter vacancy'), findsOneWidget);
    expect(find.text('Flutter and Dart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  Future<void> openForm(
    WidgetTester tester,
    Future<void> Function(JobItem) publish,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => PostJobScreen(
                    recruiterId: 'hr-1',
                    contactEmail: 'hr@company.com',
                    onPublish: publish,
                  ),
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(WidgetTester tester) async {
    for (final entry in {
      'Job title': 'Flutter Developer',
      'Company': 'Example Company',
      'Location': 'Colombo / Hybrid',
      'Job description': 'Build mobile applications.',
      'Requirements': 'Dart, Flutter and two years of experience.',
    }.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, entry.key),
        entry.value,
      );
    }
  }

  testWidgets('Invalid vacancies stay on the form and are not published', (
    tester,
  ) async {
    var calls = 0;
    await openForm(tester, (_) async {
      calls++;
    });
    await tester.tap(find.text('Publish vacancy'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Enter Requirements.'), findsOneWidget);
    await fillForm(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Application email'),
      'invalid',
    );
    await tester.tap(find.text('Publish vacancy'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Enter a valid contact email.'), findsOneWidget);
  });

  testWidgets('Publish waits for persistence and prevents double submission', (
    tester,
  ) async {
    final pending = Completer<void>();
    final saved = <JobItem>[];
    await openForm(tester, (job) {
      saved.add(job);
      return pending.future;
    });
    await fillForm(tester);
    await tester.tap(find.text('Publish vacancy'));
    await tester.pump();
    expect(find.text('Publishing...'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(saved, hasLength(1));
    expect(saved.single.recruiterId, 'hr-1');
    expect(saved.single.requirements, contains('Dart, Flutter'));
    expect(saved.single.contactEmail, 'hr@company.com');
    expect(saved.single.company, 'Example Company');
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Open form'), findsOneWidget);
    expect(find.text('Post a vacancy'), findsNothing);
  });

  testWidgets('Failed saves keep entered requirements and allow retry', (
    tester,
  ) async {
    var calls = 0;
    await openForm(tester, (_) async {
      calls++;
      if (calls == 1) throw StateError('Permission denied');
    });
    await fillForm(tester);
    await tester.tap(find.text('Publish vacancy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not publish'), findsOneWidget);
    expect(
      find.text('Dart, Flutter and two years of experience.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Publish vacancy'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Open form'), findsOneWidget);
  });

  testWidgets('Vacancy details show full requirements on a small screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final job = JobItem(
      id: 'job-1',
      title: 'Developer',
      company: 'Company',
      location: 'Colombo',
      type: 'Internship',
      matchPercentage: 0,
      logoUrl: '',
      requirements: 'Flutter experience.\n' * 20,
      description: 'Build apps.',
      contactEmail: 'hr@company.com',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [JobListingCard(job: job)]),
        ),
      ),
    );
    await tester.tap(find.text('View requirements & apply'));
    await tester.pumpAndSettle();
    expect(find.text('Requirements'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('hr@company.com'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('hr@company.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
