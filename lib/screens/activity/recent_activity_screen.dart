import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/activity_service.dart';
import '../../widgets/app_back_button.dart';

/// What has actually happened in the app recently.
class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key, this.loader});

  /// Injectable for tests; defaults to the live Firestore query.
  final Future<List<ActivityEvent>> Function()? loader;

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  late Future<List<ActivityEvent>> _future = _load();

  Future<List<ActivityEvent>> _load() =>
      (widget.loader ?? ActivityService.recent)();

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
        child: FutureBuilder<List<ActivityEvent>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final events = snapshot.data ?? const <ActivityEvent>[];
            if (events.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(28),
                children: const [
                  SizedBox(height: 60),
                  Icon(
                    Icons.history_outlined,
                    size: 44,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Nothing has happened yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Upload a note, post an item, add a vacancy or publish an '
                    'event and it will show up here. Pull down to refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ActivityTile(event: events[index]),
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
