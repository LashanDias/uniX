import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../services/lost_found_service.dart';
import 'cloud_reports.dart';
import 'followup_card.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});
  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

/// Reads back the day a report was saved on this device.
///
/// Reports saved before this field existed have no date, so they say where
/// they live instead of showing a wrong one.
String _savedDate(String? iso) {
  final saved = iso == null ? null : DateTime.tryParse(iso);
  if (saved == null) return 'Saved on this device';
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[saved.month - 1]} ${saved.day}, ${saved.year}';
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _reports = [];
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  /// True when this device's storage could not be read.
  String? _storageError;

  Future<void> _loadReports() async {
    // This had no error handling, so a failed read left the list empty with
    // no sign anything had gone wrong: a report you had just saved simply
    // vanished on reload and looked like it had never been stored.
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = (prefs.getStringList('lostFound.reports.v1') ?? [])
          .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
          .toList();
      if (mounted) {
        setState(() {
          _reports = reports;
          _storageError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _reports = const [];
          _storageError = 'Your saved reports could not be read ($error).';
        });
      }
    }
  }

  static const _items = [
    ('Keys', 'Lost', 'Near Library', '2h ago', 'assets/images/lost_keys.png'),
    (
      'Black wallet',
      'Lost',
      'Near Library',
      '2h ago',
      'assets/images/lost_wallet.png',
    ),
    (
      'ID Card',
      'Found',
      'Near canteen',
      '5h ago',
      'assets/images/lost_student_card.png',
    ),
    (
      'Headphones',
      'Lost',
      'In RB-GF-03',
      '1d ago',
      'assets/images/earbuds.jfif',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where((e) => _tab == 0 || e.$2 == (_tab == 1 ? 'Lost' : 'Found'))
        .toList();
    final reports = _reports
        .where(
          (r) =>
              _tab == 0 ||
              (r['type'] ?? 'lost') == (_tab == 1 ? 'lost' : 'found'),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            tooltip: 'My report history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  appBar: null,
                  body: SafeArea(child: LostFoundCloudReports(history: true)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tab == i
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          const ['All', 'Lost', 'Found'][i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _tab == i
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: _tab == i
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_storageError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _storageError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadReports,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  itemCount: reports.length + visible.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          const LostFoundFollowups(),
                          LostFoundCloudReports(
                            type: _tab == 0
                                ? null
                                : (_tab == 1 ? 'lost' : 'found'),
                          ),
                        ],
                      );
                    }
                    index -= 1;
                    if (index < reports.length) {
                      final report = reports[index];
                      final images = List<String>.from(
                        report['images'] as List,
                      );
                      // Matches the example cards below rather than a bare
                      // ListTile, so a student's own report does not look
                      // like a lesser thing than the samples.
                      return InkWell(
                        // Opens the same page the sample items use. It used to
                        // open a bare, unstyled list of the raw fields, which
                        // made a student's own report look like a lesser thing
                        // than the samples sitting right below it.
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => LostItemDetailScreen(
                              title: report['title'] as String,
                              description: report['description'] as String,
                              location: report['location'] as String,
                              date: _savedDate(report['savedAt'] as String?),
                              type: (report['type'] as String?) ?? 'lost',
                              photos: images,
                              isMine: true,
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: images.isEmpty
                                    ? Container(
                                        width: 70,
                                        height: 70,
                                        color: AppColors.primaryLight,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Image.memory(
                                        base64Decode(images.first),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Text(
                                            'Yours',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${report['type'] == 'found' ? 'Found' : 'Lost'} : ${report['title']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report['location'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Saved on this device',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == reports.length)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Example reports'),
                          ),
                        _itemCard(context, visible[index - reports.length]),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/report_item');
                    if (mounted) await _loadReports();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Report Lost / Found Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(
    BuildContext context,
    (String, String, String, String, String) item,
  ) => InkWell(
    onTap: () =>
        Navigator.pushNamed(context, '/lost_item_detail', arguments: item.$1),
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              item.$5,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 70,
                height: 70,
                color: AppColors.primaryLight,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.$2} : ${item.$1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.$3,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.$4,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: AppColors.primary,
              size: 19,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The full page for one Lost & Found item.
///
/// This used to take nothing but a title and invent the rest: every item,
/// whatever it was, claimed it had been lost "near library" on "May 2nd 2026".
/// A student's own report could not use it at all and opened a bare,
/// unstyled page instead. It now carries the real report, so a report you
/// just filed looks exactly like the samples beside it.
class LostItemDetailScreen extends StatelessWidget {
  const LostItemDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.type,
    this.photos = const [],
    this.imageAsset,
    this.isMine = false,
  });

  /// One of the built-in sample items on the list.
  ///
  /// The wording says plainly that it is a sample, so nobody waits for a
  /// reply to a report that no student ever filed.
  LostItemDetailScreen.example({super.key, required this.title})
    : description = 'Sample report, so you can see how a real one looks.',
      location = 'Library second floor',
      date = 'Example item',
      type = 'lost',
      photos = const [],
      isMine = false,
      imageAsset = switch (title.toLowerCase()) {
        'black wallet' => 'assets/images/lost_wallet.png',
        'keys' => 'assets/images/lost_keys.png',
        'id card' => 'assets/images/lost_student_card.png',
        _ => 'assets/images/earbuds.jfif',
      };

  final String title;
  final String description;
  final String location;
  final String date;
  final String type;

  /// Photos the student attached, base64 encoded as they are stored.
  final List<String> photos;

  /// Stand-in artwork, used only by the sample items.
  final String? imageAsset;

  /// Whether the signed-in student filed this report.
  final bool isMine;

  bool get _isExample => imageAsset != null;

  /// Copies the report so it can be pasted into a batch or hostel group.
  ///
  /// A report stores no phone number or email -- only the reporter's user id
  /// -- so there is nothing to dial, and the old "Contact owner" button went
  /// to the follow-ups page instead, which contacted nobody. Sharing the
  /// details is the thing that can actually be done with what is stored.
  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final text =
        '''
${type == 'found' ? 'Found' : 'Lost'}: $title
Where: $location
When: $date

$description'''
            .trim();
    try {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(
        const SnackBar(content: Text('Details copied. Paste them anywhere.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Clipboard unavailable on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Lost & Found')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8DA),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: photos.isNotEmpty
                    ? Image.memory(
                        base64Decode(photos.first),
                        fit: BoxFit.cover,
                        semanticLabel: 'Photo of $title',
                      )
                    : imageAsset != null
                    ? Image.asset(
                        imageAsset!,
                        fit: BoxFit.cover,
                        semanticLabel: 'Example image of $title',
                      )
                    : const Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _isExample
                    ? 'Example item image'
                    : photos.isEmpty
                    ? 'No photo attached'
                    : 'Photo you attached',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final photo in photos.skip(1))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(photo),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isMine)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Yours',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              description.isEmpty ? 'No description given.' : description,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              location.isEmpty ? 'Not given.' : location,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(date, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 232,
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _copy(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(232, 36),
                    maximumSize: const Size(232, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Copy details to share'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isMine
                  ? 'This is your report. Share it in your batch group.'
                  : 'No contact details are shared. Copy this report to share '
                        'it in your batch or hostel group.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key, this.pickImages, this.onSave});
  final Future<void> Function(Map<String, dynamic>)? onSave;
  final Future<List<XFile>> Function()? pickImages;
  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  String _category = 'Wallet';
  String _type = 'lost';
  String? _itemId;
  final String _draftId = DateTime.now().microsecondsSinceEpoch.toString();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final List<Uint8List> _images = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files =
          await (widget.pickImages?.call() ??
              ImagePicker().pickMultiImage(
                maxWidth: 800,
                maxHeight: 800,
                imageQuality: 65,
              ));
      for (final file in files) {
        if (_images.length >= 3) {
          if (mounted) {
            setState(() => _error = 'You can attach up to 3 images.');
          }
          break;
        }
        final bytes = await file.readAsBytes();
        if (_images.fold<int>(0, (sum, image) => sum + image.length) +
                bytes.length >
            600000) {
          throw StateError('Choose smaller photos: the total limit is 600 KB.');
        }
        final codec = await ui.instantiateImageCodec(bytes);
        codec.dispose();
        if (!mounted) return;
        setState(() => _images.add(bytes));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not open this photo. Please try another image.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_busy) return;
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) {
      setState(() => _error = 'Enter a title and location.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final drafts = (prefs.getStringList('lostFound.reports.v1') ?? [])
          .where((entry) => (jsonDecode(entry) as Map)['draftId'] != _draftId)
          .toList();
      final report = jsonEncode({
        'draftId': _draftId,
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'description': _description.text.trim(),
        'category': _category,
        'type': _type,
        'images': _images.map(base64Encode).toList(),
        // Without this the detail page had no date to show, so a report a
        // student saved looked less complete than the samples beside it.
        'savedAt': DateTime.now().toIso8601String(),
      });
      // Photos are held as base64 inside the entry, so a few large ones can
      // exceed the browser's storage quota. Say that, rather than "could not
      // save", which gives the student nothing to act on.
      if (!await prefs.setStringList('lostFound.reports.v1', [
        report,
        ...drafts,
      ])) {
        throw StateError(
          _images.isEmpty
              ? 'Could not save this report on your device.'
              : 'Could not save this report. Your photos may be too large '
                    'for this device to store. Try fewer or smaller photos.',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Draft saved on this device. Publish a report to start automatic follow-ups.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not save this draft. Your photos are still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) {
      setState(() => _error = 'Enter a title and location.');
      return;
    }
    if (_title.text.trim().length > 150 ||
        _location.text.trim().length > 250 ||
        _description.text.trim().length > 3000) {
      setState(
        () => _error =
            'Title: maximum 150 characters; location: 250; description: 3000.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.onSave == null && LostFoundService.userId == null) {
        throw StateError('Please sign in to publish a report.');
      }
      _itemId ??= widget.onSave != null
          ? 'test-report'
          : LostFoundService.newId();
      final report = <String, dynamic>{
        'itemId': _itemId,
        'type': _type,
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'description': _description.text.trim(),
        'category': _category,
        'images': _images.map(base64Encode).toList(),
      };
      await (widget.onSave ?? LostFoundService.create)(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report published. Your first follow-up is in 2 days.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not publish. Check your connection or backend setup and retry. Your photos are still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Find an Item')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Report type'),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: const [
                DropdownMenuItem(value: 'lost', child: Text('Lost Item')),
                DropdownMenuItem(value: 'found', child: Text('Found Item')),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Title'),
            TextField(
              controller: _title,
              decoration: InputDecoration(hintText: 'Enter item title'),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Category'),
            DropdownButtonFormField(
              initialValue: _category,
              items: const [
                'Wallet',
                'Electronics',
                'Keys',
                'ID Card',
                'Other',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Location'),
            TextField(
              controller: _location,
              decoration: InputDecoration(hintText: 'Enter location'),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Images'),
            OutlinedButton.icon(
              onPressed: _busy || _images.length >= 3 ? null : _pickImages,
              icon: const Icon(Icons.add),
              label: Text(_busy ? 'Please wait...' : 'Add Images'),
            ),
            const Text('Up to 3 PNG, JPEG or WebP photos, 600 KB total.'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _images.length; i++)
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.memory(_images[i], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton.filled(
                            tooltip: 'Remove image ${i + 1}',
                            onPressed: _busy
                                ? null
                                : () => setState(() => _images.removeAt(i)),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 14),
            _fieldLabel('Description'),
            TextField(
              controller: _description,
              maxLines: 4,
              decoration: InputDecoration(hintText: 'Write description...'),
            ),
            const SizedBox(height: 52),
            const Text(
              'Follow-ups repeat after 2, 4 and 8 days until this report is resolved.',
            ),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: const Text('Publish Report'),
            ),
            TextButton(
              onPressed: _busy ? null : _saveDraft,
              child: const Text('Save draft on this device'),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _fieldLabel(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(s, style: const TextStyle(fontSize: 12)),
  );
}

class FindItemScreen extends StatelessWidget {
  const FindItemScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lost & Found follow-ups')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your due follow-ups appear here and in Notifications.'),
          SizedBox(height: 16),
          LostFoundFollowups(),
        ],
      ),
    ),
  );
}
