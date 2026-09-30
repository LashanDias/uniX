import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_app/screens/lost_found/lost_found_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('picker previews and removes images, cancellation is harmless', (
    tester,
  ) async {
    var calls = 0;
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1sAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReportItemScreen(
          pickImages: () async {
            calls++;
            return calls == 1 ? [XFile.fromData(bytes, name: 'photo.png')] : [];
          },
        ),
      ),
    );
    await tester.tap(find.text('Add Images'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byTooltip('Remove image 1'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('Add Images'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('report retains the selected photo in storage', (tester) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1sAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReportItemScreen(
          pickImages: () async => [XFile.fromData(bytes, name: 'photo.png')],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'Wallet');
    await tester.enterText(find.byType(TextField).at(1), 'Library');
    await tester.tap(find.text('Add Images'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Report'));
    await tester.tap(find.text('Save Report'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(
      prefs.getStringList('lostFound.reports.v1')!.single,
    );
    expect(saved['title'], 'Wallet');
    expect(saved['images'], [base64Encode(bytes)]);
  });
}
