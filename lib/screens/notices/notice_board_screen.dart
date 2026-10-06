import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/event_date_parser.dart';
import '../../services/notice_board_service.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/safe_network_image.dart';

/// Campus notice board: announcements students should see.
///
/// Anyone signed in can read. Posting and removing is admin only, enforced in
/// firestore.rules as well as here.
class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key, this.noticesStream});

  /// Injectable for tests; defaults to the live Firestore stream.
  final Stream<List<Notice>>? noticesStream;

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'All';
  late final Stream<List<Notice>> _stream =
      widget.noticesStream ?? NoticeBoardService.watchNotices();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PostNoticeScreen()),
    );
    if (posted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice posted to the board.')),
      );
    }
  }

  Future<void> _remove(Notice notice) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this notice?'),
        content: Text('"${notice.title}" will disappear for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await NoticeBoardService.remove(notice.id);
      messenger.showSnackBar(const SnackBar(content: Text('Notice removed.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not remove this. Please retry.')),
      );
    }
  }

  List<Notice> _visible(List<Notice> notices) => notices
      .where((n) => _category == 'All' || n.category == _category)
      .where((n) => n.matches(_query))
      .toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Notice Board'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: StreamBuilder<List<Notice>>(
            stream: _stream,
            builder: (context, snapshot) {
              final failed = snapshot.hasError;
              final hasNoLiveNotices =
                  snapshot.hasData && snapshot.data!.isEmpty;
              final usingSamples =
                  failed || !snapshot.hasData || hasNoLiveNotices;
              // Keep the board useful before the first notice is published,
              // and if Firestore is temporarily unavailable.
              final notices = usingSamples
                  ? NoticeBoardService.sampleNotices()
                  : NoticeBoardService.sortForBoard(snapshot.data!);
              final visible = _visible(notices);

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                children: [
                  if (NoticeBoardService.canPost) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _compose,
                        icon: const Icon(Icons.add),
                        label: const Text('Add notice'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search notices...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final label in ['All', ...Notice.categories])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: _category == label,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _category = label),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (usingSamples)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        failed
                            ? 'Live notices could not load. Showing sample notices.'
                            : hasNoLiveNotices
                            ? 'No live notices yet. Showing sample notices.'
                            : 'Loading notices...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 40,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No notices match this filter.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final notice in visible)
                      _NoticeCard(
                        notice: notice,
                        canRemove: NoticeBoardService.canPost && !usingSamples,
                        onRemove: () => _remove(notice),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.canRemove,
    required this.onRemove,
  });

  final Notice notice;
  final bool canRemove;
  final VoidCallback onRemove;

  static const _categoryColours = {
    'Academic': Color(0xFFEAF1FF),
    'Events': Color(0xFFF3E8FF),
    'Facilities': Color(0xFFE0F2F1),
    'Exams': Color(0xFFFFF4E3),
    'General': AppColors.chipBg,
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: notice.pinned ? AppColors.primary : AppColors.border,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notice.hasImage) ...[
          SafeNetworkImage(
            url: notice.imageUrl,
            height: 170,
            placeholderIcon: Icons.campaign_outlined,
            placeholderLabel: notice.title,
          ),
          if (notice.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
              child: Text(
                notice.caption,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textLight,
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _categoryColours[notice.category] ?? AppColors.chipBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                notice.category,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (notice.whenLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      notice.urgency() == EventUrgency.today ||
                          notice.urgency() == EventUrgency.tomorrow
                      ? AppColors.badgeGreen
                      : AppColors.chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notice.whenLabel!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            if (notice.pinned)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Pinned',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            Text(
              notice.age,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          notice.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          notice.body,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: 14,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                notice.postedBy,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ),
            if (canRemove)
              IconButton(
                tooltip: 'Remove notice',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Admin form for posting a notice.
class PostNoticeScreen extends StatefulWidget {
  const PostNoticeScreen({super.key});

  @override
  State<PostNoticeScreen> createState() => _PostNoticeScreenState();
}

class _PostNoticeScreenState extends State<PostNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _imageUrl = TextEditingController();
  final _caption = TextEditingController();
  String _category = Notice.categories.last;
  bool _pinned = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _imageUrl.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await NoticeBoardService.post(
        title: _title.text,
        body: _body.text,
        category: _category,
        pinned: _pinned,
        imageUrl: _imageUrl.text,
        caption: _caption.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not post. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Post a notice'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Library open late during study week',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter a title.' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _body,
                  maxLines: 6,
                  maxLength: 1500,
                  decoration: const InputDecoration(
                    labelText: 'Notice',
                    alignLabelWithHint: true,
                    hintText: 'What do students need to know?',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter the notice text.'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _imageUrl,
                  maxLength: 500,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Flyer image link (optional)',
                    hintText: 'https://...',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final uri = Uri.tryParse(text);
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Enter a full link starting with https://';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _caption,
                  maxLength: 140,
                  decoration: const InputDecoration(
                    labelText: 'Caption under the flyer (optional)',
                    hintText: 'Hackathon flyer - teams of up to four',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in Notice.categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _pinned,
                  onChanged: (value) => setState(() => _pinned = value),
                  title: const Text('Pin to the top'),
                  subtitle: const Text(
                    'Use for notices everyone must see first.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: Text(_saving ? 'Posting...' : 'Post notice'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
