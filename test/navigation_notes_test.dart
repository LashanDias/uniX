import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/main.dart';
import 'package:unix_app/models/app_models.dart';
import 'package:unix_app/screens/notes/notes_home_screen.dart';
import 'package:unix_app/services/notes_catalog.dart';

void main() {
 testWidgets('View All destination resolves to Recent Activity', (tester) async {
   await tester.pumpWidget(const UnixApp());
   final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
   final route = app.onGenerateRoute!(const RouteSettings(name:'/recent_activity')) as MaterialPageRoute;
   await tester.pumpWidget(MaterialApp(home: Builder(builder: route.builder)));
   expect(find.text('Recent Activity'), findsOneWidget);
 });
 testWidgets('ICT opens degree groups then common statistics notes', (tester) async {
   final note = NoteItem(id:'stats', title:'Probability basics', subject:'ICT', degree:'Common', topic:'Statistics', fileType:'PDF', uploadedDate:'Today', description:'Probability notes');
   await tester.pumpWidget(MaterialApp(home:NotesHomeScreen(notesStream:Stream.value([note]))));
   await tester.pumpAndSettle();
   await tester.tap(find.text('ICT').first); await tester.pumpAndSettle();
   expect(find.text('Data Science'),findsOneWidget);
   await tester.tap(find.text('Common').first); await tester.pumpAndSettle();
   await tester.tap(find.text('Statistics').first); await tester.pumpAndSettle();
   expect(find.text('Probability basics'),findsOneWidget);
   expect(find.text('Statistics'),findsOneWidget);
   expect(tester.takeException(),isNull);
 });
 test('shared statistics is accessible through ICT Common', () {
   final note=NoteItem(id:'stats',title:'Stats',subject:'Mathematics',topic:'Statistics',fileType:'PDF',uploadedDate:'Today',description:'');
   expect(NotesCatalog.matches(note,'ICT','Common','Statistics'),true);
   expect(NotesCatalog.matches(note,'ICT','Data Science','Statistics'),false);
 });
}
