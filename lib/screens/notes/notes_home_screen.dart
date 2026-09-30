import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../services/mock_data_service.dart';
import '../../services/notes_service.dart';
import '../../services/notes_catalog.dart';
import '../../widgets/app_back_button.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key, this.notesStream});
  final Stream<List<NoteItem>>? notesStream;
  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  late final _stream =
      widget.notesStream ??
      (Firebase.apps.isEmpty
          ? Stream<List<NoteItem>>.value([])
          : NotesService.watchNotes());
  String? _subject, _degree, _topic;
  String _query = '';
  void _back() => setState(() {
    if (_topic != null) {
      _topic = null;
    } else if (_degree != null) {
      _degree = null;
    } else {
      _subject = null;
    }
    _query = '';
  });
  Widget _tile(String title, String subtitle, VoidCallback onTap) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: const Icon(Icons.folder_outlined, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _subject == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_topic ?? _degree ?? _subject ?? 'Notes'),
        leading: _subject == null
            ? const AppBackButton()
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
              ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: StreamBuilder<List<NoteItem>>(
        stream: _stream,
        builder: (context, snapshot) {
          final sample = !snapshot.hasData || snapshot.data!.isEmpty;
          final notes = sample ? MockDataService.getNotes() : snapshot.data!;
          final visible = notes
              .where(
                (note) =>
                    (_subject == null ||
                        NotesCatalog.matches(
                          note,
                          _subject!,
                          _degree,
                          _topic,
                        )) &&
                    '${note.title} ${note.subject} ${NotesCatalog.topic(note)}'
                        .toLowerCase()
                        .contains(_query.toLowerCase()),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                key: ValueKey('$_subject/$_degree/$_topic'),
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              if (sample)
                Text(
                  snapshot.hasError
                      ? 'Live notes could not load. Showing sample notes.'
                      : 'Sample notes — upload notes to build your library.',
                ),
              const SizedBox(height: 12),
              if (_query.isEmpty && _subject == null) ...[
                const Text(
                  'Subjects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final subject in [
                  'ICT',
                  'English',
                  'Mathematics',
                  'Science',
                ])
                  _tile(
                    subject,
                    subject == 'ICT'
                        ? 'Degree categories and common subjects'
                        : 'Browse subjects and notes',
                    () => setState(() => _subject = subject),
                  ),
              ] else if (_query.isEmpty &&
                  _subject == 'ICT' &&
                  _degree == null) ...[
                const Text(
                  'Choose a degree category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text('Common subjects are shared across IT degrees.'),
                const SizedBox(height: 12),
                for (final degree in NotesCatalog.ict.keys)
                  _tile(
                    degree,
                    degree == 'Common'
                        ? 'Statistics, mathematics, English and programming'
                        : '${NotesCatalog.ict[degree]!.length} subject groups',
                    () => setState(() => _degree = degree),
                  ),
              ] else if (_query.isEmpty &&
                  _topic == null &&
                  _subject != null) ...[
                for (final topic in {
                  ...(_subject == 'ICT'
                      ? NotesCatalog.ict[_degree]!
                      : NotesCatalog.subjects[_subject]!),
                  ...visible.map(NotesCatalog.topic),
                })
                  _tile(
                    topic,
                    '${notes.where((note) => NotesCatalog.matches(note, _subject!, _degree, topic)).length} notes',
                    () => setState(() => _topic = topic),
                  ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/upload_notes'),
                icon: const Icon(Icons.add),
                label: const Text('Add Note'),
              ),
              const SizedBox(height: 24),
              Text(
                _subject == null ? 'Recent Notes' : 'Notes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Text(
                  'No notes in this category yet. Add a note to get started.',
                ),
              for (final note in visible)
                _tile(
                  note.title,
                  '${note.subject} • ${note.uploadedDate}',
                  () => Navigator.pushNamed(
                    context,
                    '/note_detail',
                    arguments: note,
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
