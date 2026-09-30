import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});
  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _reports = [];
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reports = (prefs.getStringList('lostFound.reports.v1') ?? [])
        .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
        .toList();
    if (mounted) setState(() => _reports = reports);
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
    final reports = _tab == 2 ? <Map<String, dynamic>>[] : _reports;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Lost & Found')),
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
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  itemCount: reports.length + visible.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index < reports.length) {
                      final report = reports[index];
                      final images = List<String>.from(
                        report['images'] as List,
                      );
                      return ListTile(
                        leading: images.isEmpty
                            ? const Icon(Icons.image_outlined)
                            : Image.memory(
                                base64Decode(images.first),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                        title: Text(report['title'] as String),
                        subtitle: Text(
                          "${report['location']} — Saved on this device",
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: Text(report['title'] as String),
                              ),
                              body: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        for (final photo in images)
                                          Image.memory(
                                            base64Decode(photo),
                                            width: 190,
                                            height: 190,
                                            fit: BoxFit.cover,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text(report['location'] as String),
                                    Text(report['description'] as String),
                                    const Text('Saved on this device'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return _itemCard(context, visible[index - reports.length]);
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

class LostItemDetailScreen extends StatelessWidget {
  const LostItemDetailScreen({super.key, required this.title});
  final String title;
  String get imageAsset => switch (title.toLowerCase()) {
    'black wallet' => 'assets/images/lost_wallet.png',
    'keys' => 'assets/images/lost_keys.png',
    'id card' => 'assets/images/lost_student_card.png',
    _ => 'assets/images/earbuds.jfif',
  };
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
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  semanticLabel: 'Example image of $title',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Example item image',
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Lost my ${title.toLowerCase()} near library',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Library second floor',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'May 2nd 2026',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/find_item'),
              child: const Text('Contact owner'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key, this.pickImages});
  final Future<List<XFile>> Function()? pickImages;
  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  String _category = 'Wallet';
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
                maxWidth: 1000,
                maxHeight: 1000,
                imageQuality: 75,
              ));
      for (final file in files) {
        if (_images.length >= 3) {
          if (mounted) {
            setState(() => _error = 'You can attach up to 3 images.');
          }
          break;
        }
        final bytes = await file.readAsBytes();
        if (bytes.length > 1024 * 1024) {
          throw StateError('Choose photos smaller than 1 MB each.');
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

  Future<void> _save() async {
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
      final report = jsonEncode({
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'description': _description.text.trim(),
        'category': _category,
        'images': _images.map(base64Encode).toList(),
      });
      final reports = prefs.getStringList('lostFound.reports.v1') ?? [];
      if (!await prefs.setStringList('lostFound.reports.v1', [
        report,
        ...reports,
      ])) {
        throw StateError('Save failed');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report and images saved on this device.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save. Your photos are still here; please retry.',
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
            const Text('Up to 3 photos, 1 MB each.'),
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
              'Reports are saved on this device, not published to other users.',
            ),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save Report'),
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
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Find')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 14, backgroundColor: Color(0xFFFF8990)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'We found a possible match for your lost item: “Black Wallet” posted in the library.\nDid you get item?',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Yes, I got it',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text(
                      'No, not yet',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 13, backgroundColor: Color(0xFFFF8990)),
                  SizedBox(width: 12),
                  Text(
                    'Okay, we remind you again tomorrow',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    onPressed: null,
                    icon: Icon(Icons.send, color: Colors.white, size: 19),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
