import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../services/notes_service.dart';
import 'short_notes_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final NoteItem note;

  const NoteDetailScreen({super.key, required this.note});


  /// Opens the note's file so the browser or OS can save it.
  ///
  /// This used to show "Downloading note..." and do nothing at all. A note
  /// with no file attached now says so instead of pretending.
  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = note.fileUrl.trim();
    if (url.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'This note has no file attached, only the description below.',
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('The file link on this note is not valid.'),
        ),
      );
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the file.')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the file.')),
      );
    }
  }

  /// Copies the note to the clipboard.
  ///
  /// The old version claimed "Share link copied!" while copying nothing.
  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = note.fileUrl.trim();
    final text = url.isEmpty
        ? '${note.title}\nSubject: ${note.subject}\n\n${note.description}'
        : '${note.title}\nSubject: ${note.subject}\n$url';
    try {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            url.isEmpty
                ? 'Note details copied. It has no file link to share.'
                : 'Note link copied.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Clipboard unavailable on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // PDF Document preview card matching Figma iPhone 16 & 17 Pro Max - 2
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.class_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Subject : ${note.subject}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Uploaded on : ${note.uploadedDate}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _download(context),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text(
                              'Download',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _share(context),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text(
                              'Share',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description Container matching Figma
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Condense this note's own text into revision notes.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShortNotesScreen(
                        initialText: note.description,
                        initialTitle: note.title,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: const Text('Generate short notes'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                ),
              ),
              if (NotesService.canManageNote(note)) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await NotesService.deleteNote(note.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Note deleted successfully.'),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete note'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
