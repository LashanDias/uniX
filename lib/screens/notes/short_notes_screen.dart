import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../services/note_summarizer.dart';
import '../../services/recruitment_documents.dart';
import '../../widgets/app_back_button.dart';

/// Turns a PDF, DOCX or TXT into short revision notes.
///
/// The notes are rendered on a ruled page in a handwriting-style face, because
/// these are meant to read as the notes a student would write out by hand
/// while revising, not as another copy of the document.
class ShortNotesScreen extends StatefulWidget {
  const ShortNotesScreen({super.key, this.initialText, this.initialTitle});

  /// Text to summarise straight away, e.g. a note's description.
  final String? initialText;
  final String? initialTitle;

  @override
  State<ShortNotesScreen> createState() => _ShortNotesScreenState();
}

class _ShortNotesScreenState extends State<ShortNotesScreen> {
  ShortNotes? _notes;
  bool _busy = false;
  String? _error;
  String? _sourceName;
  final _pasted = TextEditingController();

  @override
  void initState() {
    super.initState();
    final text = widget.initialText;
    if (text != null && text.trim().isNotEmpty) {
      _notes = NoteSummarizer.generate(
        text,
        title: widget.initialTitle ?? 'Short notes',
      );
      _sourceName = widget.initialTitle;
    }
  }

  @override
  void dispose() {
    _pasted.dispose();
    super.dispose();
  }

  /// Condenses text the student pasted, with no file reading involved.
  void _summarisePasted() {
    final text = _pasted.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Paste some text first, then tap Make notes.');
      return;
    }
    setState(() {
      _error = null;
      _sourceName = 'Pasted text';
      _notes = NoteSummarizer.generate(text, title: 'Short notes');
    });
  }

  Future<void> _pickAndSummarise() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final document = await RecruitmentDocuments.pick();
      if (document == null) return; // Cancelled.
      if (document.text.trim().isEmpty) {
        setState(
          () => _error =
              'No readable text in that file. A scanned PDF holds pictures '
              'of text, which cannot be summarised.',
        );
        return;
      }
      setState(() {
        _sourceName = document.name;
        _notes = NoteSummarizer.generate(document.text, title: document.name);
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      // Naming the failure matters: PDF text extraction needs a rendering
      // engine that is not always available in a browser, and a generic
      // message left no way to tell that apart from a bad file.
      setState(
        () => _error =
            'Could not read that file ($error). '
            'A DOCX or TXT usually works, or paste the text below.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final notes = _notes;
    if (notes == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: notes.toPlainText()));
      messenger.showSnackBar(
        const SnackBar(content: Text('Short notes copied.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Clipboard unavailable on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _notes;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Short notes'),
        actions: [
          if (notes != null && !notes.isEmpty)
            IconButton(
              tooltip: 'Copy notes',
              onPressed: _copy,
              icon: const Icon(Icons.copy_all_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _IntroCard(
                  busy: _busy,
                  sourceName: _sourceName,
                  onPick: _busy ? null : _pickAndSummarise,
                ),
                const SizedBox(height: 14),
                _PasteCard(
                  controller: _pasted,
                  onGenerate: _summarisePasted,
                  busy: _busy,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (notes != null && !notes.isEmpty) ...[
                  const SizedBox(height: 18),
                  _ReductionBadge(notes: notes),
                  const SizedBox(height: 12),
                  _HandwrittenPage(notes: notes),
                ] else if (notes != null && notes.isEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'There was not enough text in that document to make '
                    'short notes from.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.busy,
    required this.sourceName,
    required this.onPick,
  });

  final bool busy;
  final String? sourceName;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Make short notes from a document',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pick a lecture PDF, DOCX or TXT and this pulls out the sentences '
          'worth revising, the definitions and the key terms. Everything is '
          'taken from your document, so nothing is made up.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPick,
            icon: busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(busy ? 'Reading document...' : 'Choose a document'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          ),
        ),
        if (sourceName != null) ...[
          const SizedBox(height: 10),
          Text(
            'From: $sourceName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ],
    ),
  );
}

class _ReductionBadge extends StatelessWidget {
  const _ReductionBadge({required this.notes});

  final ShortNotes notes;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _pill(
        '${notes.reductionPercent}% shorter',
        AppColors.badgeGreen,
        AppColors.badgeGreenText,
      ),
      _pill(
        '${notes.sourceWordCount} words in',
        AppColors.chipBg,
        AppColors.textSecondary,
      ),
      _pill(
        '${notes.shortWordCount} words out',
        AppColors.chipBg,
        AppColors.textSecondary,
      ),
    ],
  );

  Widget _pill(String text, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: foreground,
      ),
    ),
  );
}

/// The notes themselves, drawn as a ruled notebook page.
class _HandwrittenPage extends StatelessWidget {
  const _HandwrittenPage({required this.notes});

  final ShortNotes notes;

  /// Cursive-ish faces, with fallbacks so it degrades to the system font
  /// rather than to squares on a device that has none of them.
  static const _handwriting = [
    'Segoe Script',
    'Bradley Hand',
    'Comic Sans MS',
    'cursive',
  ];

  static const _ink = Color(0xFF1A3A6B);

  TextStyle get _hand => const TextStyle(
    fontFamily: 'Segoe Script',
    fontFamilyFallback: _handwriting,
    color: _ink,
    fontSize: 16,
    height: 1.7,
  );

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE6DFC8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notes.title,
          style: _hand.copyWith(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const Divider(color: Color(0xFFE6DFC8), height: 22),
        if (notes.summary.isNotEmpty) ...[
          _heading('Summary'),
          Text(notes.summary, style: _hand),
          const SizedBox(height: 16),
        ],
        if (notes.keyPoints.isNotEmpty) ...[
          _heading('Key points'),
          for (final point in notes.keyPoints) _bullet(point),
          const SizedBox(height: 16),
        ],
        if (notes.definitions.isNotEmpty) ...[
          _heading('Definitions'),
          for (final entry in notes.definitions.entries)
            _bullet('${entry.key} — ${entry.value}'),
          const SizedBox(height: 16),
        ],
        if (notes.keyTerms.isNotEmpty) ...[
          _heading('Key terms'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in notes.keyTerms)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(term, style: _hand.copyWith(fontSize: 13)),
                ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: _hand),
        Expanded(child: Text(text, style: _hand)),
      ],
    ),
  );
}

/// Paste-text alternative to picking a file.
///
/// Reading a PDF needs a rendering engine that is not always available in a
/// browser, so this path always works: it goes straight to the summariser.
class _PasteCard extends StatelessWidget {
  const _PasteCard({
    required this.controller,
    required this.onGenerate,
    required this.busy,
  });

  final TextEditingController controller;
  final VoidCallback onGenerate;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Or paste your lecture text',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Copy from a slide, a PDF or a webpage and paste it here. This '
          'always works, even when a file cannot be read.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste the lecture notes here...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onGenerate,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('Make notes from pasted text'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
          ),
        ),
      ],
    ),
  );
}
