import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/lost_found_service.dart';

class LostFoundFollowups extends StatelessWidget {
  const LostFoundFollowups({super.key});
  @override
  Widget build(BuildContext context) {
    if (LostFoundService.userId == null) return const SizedBox.shrink();
    return StreamBuilder<List<Map<String, dynamic>>>(stream: LostFoundService.reminders(), builder: (context, snapshot) {
      if (snapshot.hasError) return const Text('Unable to load Lost & Found follow-ups. Please try again later.');
      return Column(children: [for (final reminder in snapshot.data ?? []) LostFoundFollowupCard(reminder: reminder)]);
    });
  }
}

class LostFoundFollowupCard extends StatefulWidget {
  const LostFoundFollowupCard({super.key, required this.reminder});
  final Map<String, dynamic> reminder;
  @override
  State<LostFoundFollowupCard> createState() => _LostFoundFollowupCardState();
}
class _LostFoundFollowupCardState extends State<LostFoundFollowupCard> {
  bool _busy = false;
  String? _error;
  Future<void> _answer(String action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await LostFoundService.respond(widget.reminder['itemId'] as String, action, checkToken: widget.reminder['checkToken'] as String);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(action == 'yes' ? 'Great! This item has been marked as resolved.' : 'Your report is still active. We will check again later.')));
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not update this follow-up. It may already have been answered. Please refresh or retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: LostFoundService.watch(widget.reminder['itemId'] as String),
    builder: (context, snapshot) {
      // Check the live post before showing any prompt, including deleted/stale reminders.
      final post = snapshot.data?.data();
      if (snapshot.hasError || post == null || post['status'] != 'active' || post['deletedAt'] != null || post['userId'] != LostFoundService.userId || post['awaitingResponse'] != true || post['checkToken'] != widget.reminder['checkToken']) return const SizedBox.shrink();
      final found = post['type'] == 'found';
      return Card(color: AppColors.primaryLight, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(found ? 'Has the owner collected your ‘${post['title']}’?' : 'Still looking for your ‘${post['title']}’?\nYou reported this item as lost. Have you found it?', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton(onPressed: _busy ? null : () => _answer('yes'), child: Text(found ? '✓ Yes, returned to owner' : '✓ Yes, I found it')),
          OutlinedButton(onPressed: _busy ? null : () => _answer('no'), child: Text(found ? '✕ No, still waiting' : '✕ No, still looking')),
        ]),
        if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.error)),
      ])));
    },
  );
}
