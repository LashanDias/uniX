import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:unix_app/services/cv_comparison_service.dart';
import 'package:unix_app/services/recruitment_documents.dart';
import 'package:unix_app/services/recruitment_store.dart';
import 'package:unix_app/screens/jobs/recruitment_workspace_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('PDF import extracts the actual document text', () async {
    Pdfrx.cacheDirectoryPath = Directory.systemTemp.path;
    const stream = 'BT /F1 12 Tf 72 720 Td (Flutter Dart SQL) Tj ET';
    final objects = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
    ];
    final pdf = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(pdf.length);
      pdf.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }
    final xref = pdf.length;
    pdf.write('xref\n0 6\n0000000000 65535 f \n');
    for (final offset in offsets) { pdf.write('${offset.toString().padLeft(10, '0')} 00000 n \n'); }
    pdf.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF');
    final text = await RecruitmentDocuments.extract('cv.pdf', Uint8List.fromList(ascii.encode(pdf.toString())));
    expect(text, contains('Flutter Dart SQL'));
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Comparison uses actual document skills and does not match Java to JavaScript',
    () {
      final result = CvComparisonService.compare(
        'Flutter, Dart and JavaScript projects',
        'Flutter, Dart, Java and SQL',
      );
      expect(result.matchedSkills, ['Flutter', 'Dart']);
      expect(result.missingSkills, ['Java', 'SQL']);
      expect(result.coverage, 50);
      expect(
        CvComparisonService.compare('Artist', 'Portrait painting').coverage,
        isNull,
      );
      expect(
        () => CvComparisonService.compare('', 'Flutter'),
        throwsFormatException,
      );
    },
  );
  test(
    'Text and DOCX imports preserve text and reject empty documents',
    () async {
      expect(
        await RecruitmentDocuments.extract(
          'cv.txt',
          Uint8List.fromList(utf8.encode('Flutter and Dart')),
        ),
        'Flutter and Dart',
      );
      final xml = utf8.encode(
        '<w:document xmlns:w="urn:word"><w:body><w:p><w:r><w:t>Python</w:t></w:r></w:p><w:p><w:r><w:t>SQL</w:t></w:r></w:p></w:body></w:document>',
      );
      final archive = Archive()
        ..addFile(ArchiveFile('word/document.xml', xml.length, xml));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
      expect(
        await RecruitmentDocuments.extract('cv.docx', bytes),
        'Python\nSQL',
      );
      await expectLater(
        RecruitmentDocuments.extract('empty.txt', Uint8List(0)),
        throwsFormatException,
      );
    },
  );
  test('CV drafts are account scoped and removable', () async {
    final store = RecruitmentStore();
    await store.saveCv('student-a', 'CV.txt', 'Flutter');
    expect((await store.loadCv('student-a'))['text'], 'Flutter');
    expect(await store.loadCv('student-b'), isEmpty);
    await store.removeCv('student-a');
    expect(await store.loadCv('student-a'), isEmpty);
  });
  testWidgets(
    'HR upload interface accepts requirements and compares pasted student CV',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: RecruitmentWorkspaceScreen(
            accountId: 'hr',
            recruiterMode: true,
            profileName: 'HR Manager',
            profileEmail: 'hr@company.com',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('View / edit my profile'), findsOneWidget);
      // The hero banner carries artwork now, so this button can sit below the
      // fold on a short screen; scroll to it as a user would.
      await tester.ensureVisible(find.text('Upload HR requirements'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload HR requirements'));
      await tester.pumpAndSettle();
      for (final entry in {
        'Job title': 'Developer',
        'Company': 'Example',
        'HR requirements text': 'Flutter, Dart, SQL',
      }.entries) {
        final field = find.widgetWithText(TextField, entry.key);
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Save HR requirements'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save HR requirements'));
      await tester.pumpAndSettle();
      expect(
        (await RecruitmentStore().requirements()).single['text'],
        'Flutter, Dart, SQL',
      );
      await tester.ensureVisible(find.text('Next: compare student CV'));
      await tester.tap(find.text('Next: compare student CV'));
      await tester.pumpAndSettle();
      final cv = find.widgetWithText(TextField, 'CV text');
      await tester.ensureVisible(cv);
      await tester.enterText(cv, 'Flutter and Dart mobile development.');
      await tester.ensureVisible(find.text('Compare CV with requirements'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compare CV with requirements'));
      await tester.pumpAndSettle();
      expect(find.text('67% listed-skill coverage'), findsOneWidget);
      expect(find.text('SQL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
