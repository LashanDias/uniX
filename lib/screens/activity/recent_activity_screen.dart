import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/activity_service.dart';
import '../../widgets/app_back_button.dart';

/// What has actually happened in the app recently.
class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key, this.loader});

  /// Injectable for tests; defaults to the live Firestore query.
  final Future<ActivityFeed> Function()? loader;

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  late Future<ActivityFeed> _future = _load();

  Future<ActivityFeed> _load() => (widget.loader ?? ActivityService.load)();

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Recent Activity'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<ActivityFeed>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // An exception thrown outside the per-source handling, and a feed
            // where every source failed, are the same thing to a student:
            // the app could not look, so it must not claim nothing happened.
            if (snapshot.hasError) {
              return const _FeedMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load activity',
                body: 'Check your connection and pull down to try again.',
              );
            }
            final feed = snapshot.data!;
            if (feed.failedEntirely) {
              return const _FeedMessage(
                icon: Icons.lock_outline,
                title: 'Could not load activity',
                body: 'You may need to sign in again, or your connection '
                    'dropped. Pull down to try again.',
              );
            }
            if (feed.events.isEmpty) {
              return const _FeedMessage(
                icon: Icons.history_outlined,
                title: 'Nothing has happened yet',
                body: 'Upload a note, post an item, add a vacancy or publish '
                    'an event and it will show up here. Pull down to refresh.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              // One extra row when some sources loaded and others did not, so
              // a partial feed does not quietly pass as the whole picture.
              itemCount: feed.events.length + (feed.unreadable.isEmpty ? 0 : 1),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => index < feed.events.length
                  ? _ActivityTile(event: feed.events[index])
                  : const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Some activity could not be loaded. Pull down to try '
                        'again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(event.icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        event.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        event.age(),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      onTap: () => Navigator.pushNamed(context, event.route),
    ),
  );
}

/// A centred icon, heading and line, scrollable so pull-to-refresh still works.
class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      const SizedBox(height: 60),
      Icon(icon, size: 44, color: AppColors.textLight),
      const SizedBox(height: 14),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    ],
  );
}
