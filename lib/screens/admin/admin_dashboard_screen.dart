import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/admin_service.dart';
import '../../services/app_access_service.dart';
import '../../services/ticket_service.dart';
import '../../widgets/app_back_button.dart';

/// Admin control panel: live platform stats, user management and moderation.
///
/// Reachable only from the admin card on the dashboard, which itself renders
/// only for an approved admin email. Firestore rules enforce the same
/// restriction server-side, because a client check alone can be bypassed.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdminService.isAdmin) return const _AccessDenied();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Moderation'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [_OverviewTab(), _UsersTab(), _ModerationTab()],
          ),
        ),
      ),
    );
  }
}

/// Shown if a non-admin reaches this route directly.
class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Admin Panel'),
    ),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 46, color: AppColors.textLight),
            SizedBox(height: 14),
            Text(
              'Admins only',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Sign in with an approved admin account to open this panel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- Overview --

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  /// Collections surfaced as live counters, with their labels and icons.
  static const _stats = [
    (AdminService.usersCollection, 'Registered users', Icons.people_outline),
    (
      AdminService.productsCollection,
      'Marketplace items',
      Icons.storefront_outlined,
    ),
    (AdminService.notesCollection, 'Shared notes', Icons.description_outlined),
    (AdminService.jobsCollection, 'Open vacancies', Icons.work_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF101828),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Signed in as $email',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Live platform activity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'These update by themselves as students use the app.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        // Two tiles per row on a phone, four when the window is wide.
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            crossAxisCount: constraints.maxWidth > 620 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              for (final (collection, label, icon) in _stats)
                _StatTile(collection: collection, label: label, icon: icon),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Approved admin accounts',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Only these emails can open this panel. The same list is enforced '
          'in firestore.rules.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        for (final adminEmail in AppAccessService.adminEmails)
          _AdminEmailTile(
            email: adminEmail,
            isCurrentUser: adminEmail == email,
          ),
      ],
    );
  }
}

/// One live-updating count tile.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.collection,
    required this.label,
    required this.icon,
  });

  final String collection;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        StreamBuilder<int>(
          stream: AdminService.watchCount(collection),
          builder: (context, snapshot) => Text(
            snapshot.hasError ? '--' : (snapshot.data?.toString() ?? '...'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _AdminEmailTile extends StatelessWidget {
  const _AdminEmailTile({required this.email, required this.isCurrentUser});

  final String email;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryLight,
          child: Icon(
            Icons.admin_panel_settings,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            email,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isCurrentUser) const _Chip(label: 'You', highlight: true),
      ],
    ),
  );
}

// ------------------------------------------------------------------- Users --

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchController = TextEditingController();
  String _term = '';
  String? _busyUid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleBlock(AdminUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyUid = user.uid);
    try {
      await AdminService.setBlocked(user, !user.blocked);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            user.blocked
                ? '${user.displayName} can sign in again.'
                : '${user.displayName} is blocked from signing in.',
          ),
        ),
      );
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not update this account. Please retry.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyUid = null);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _term = value),
          decoration: InputDecoration(
            hintText: 'Search by name, email or role',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<List<AdminUser>>(
          stream: AdminService.watchUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _TabMessage(
                icon: Icons.cloud_off_outlined,
                text:
                    'Could not load accounts. Check your connection, and that '
                    'firestore.rules lets admins read the users collection.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data!
                .where((user) => user.matches(_term))
                .toList();
            if (users.isEmpty) {
              return const _TabMessage(
                icon: Icons.person_search_outlined,
                text: 'No accounts match this search.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: users.length,
              itemBuilder: (context, index) => _UserTile(
                user: users[index],
                busy: _busyUid == users[index].uid,
                onToggleBlock: () => _toggleBlock(users[index]),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.busy,
    required this.onToggleBlock,
  });

  final AdminUser user;
  final bool busy;
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: user.blocked ? AppColors.error : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            user.initial,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(label: user.role),
                  if (user.isAdmin)
                    const _Chip(label: 'Admin', highlight: true),
                  if (user.blocked) const _Chip(label: 'Blocked', danger: true),
                ],
              ),
            ],
          ),
        ),
        if (busy)
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (!user.isAdmin)
          IconButton(
            tooltip: user.blocked ? 'Unblock account' : 'Block account',
            onPressed: onToggleBlock,
            icon: Icon(
              user.blocked ? Icons.lock_open_outlined : Icons.block_outlined,
              color: user.blocked ? AppColors.success : AppColors.error,
            ),
          ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.highlight = false,
    this.danger = false,
  });

  final String label;
  final bool highlight;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final background = danger
        ? const Color(0xFFFEE2E2)
        : highlight
        ? AppColors.primaryLight
        : AppColors.chipBg;
    final foreground = danger
        ? AppColors.error
        : highlight
        ? AppColors.primary
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Moderation --

class _ModerationTab extends StatelessWidget {
  const _ModerationTab();

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Column(
      children: [
        const Material(
          color: AppColors.background,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Items'),
              Tab(text: 'Notes'),
              Tab(text: 'Jobs'),
              Tab(text: 'Tickets'),
              Tab(text: 'Feedback'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _ModerationList(
                stream: AdminService.watchProducts,
                emptyText: 'No marketplace listings yet.',
                icon: Icons.storefront_outlined,
              ),
              _ModerationList(
                stream: AdminService.watchNotes,
                emptyText: 'No notes uploaded yet.',
                icon: Icons.description_outlined,
              ),
              _ModerationList(
                stream: AdminService.watchJobs,
                emptyText: 'No vacancies posted yet.',
                icon: Icons.work_outline,
              ),
              const _TicketsModeration(),
              _ModerationList(
                stream: AdminService.watchFeedback,
                emptyText: 'No feedback has been submitted yet.',
                icon: Icons.feedback_outlined,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Publish and remove campus event tickets.
///
/// Delete sits on the same list as every other moderated collection, and the
/// rules put no window on it: an event can be pulled at any time, including
/// after its date has passed. Publishing lives here too, because before this
/// the two events on the Tickets screen were written into the source code and
/// there was nothing an admin could remove.
class _TicketsModeration extends StatelessWidget {
  const _TicketsModeration();

  Future<void> _addEvent(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddTicketDialog(),
    );
    if (created != true) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Event published to the Tickets screen.')),
    );
  }

  @override
  Widget build(BuildContext context) => _ModerationList(
    stream: AdminService.watchTickets,
    emptyText: 'No events published yet. Add one to get started.',
    icon: Icons.confirmation_number_outlined,
    header: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _addEvent(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add event'),
        ),
      ),
    ),
  );
}

/// The form for publishing one event.
class _AddTicketDialog extends StatefulWidget {
  const _AddTicketDialog();

  @override
  State<_AddTicketDialog> createState() => _AddTicketDialogState();
}

class _AddTicketDialogState extends State<_AddTicketDialog> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _price = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _price.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Checked here as well as in the rules so a typo comes back as a sentence
    // rather than a raw permission-denied error.
    final problem = TicketService.validationError(
      title: _title.text,
      details: _details.text,
      price: _price.text,
      imageUrl: _imageUrl.text,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await TicketService.create(
        title: _title.text,
        details: _details.text,
        price: _price.text,
        imageUrl: _imageUrl.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not publish this event. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add an event'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Event name',
              hintText: 'Talent Night 2026',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _details,
            decoration: const InputDecoration(
              labelText: 'Date and venue',
              hintText: 'Sep 18 • Main Auditorium',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _price,
            decoration: const InputDecoration(
              labelText: 'Price',
              hintText: 'LKR 750, or Free',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              labelText: 'Image link (optional)',
              hintText: 'https://...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Publishing...' : 'Publish'),
      ),
    ],
  );
}

class _ModerationList extends StatelessWidget {
  const _ModerationList({
    required this.stream,
    required this.emptyText,
    required this.icon,
    this.header,
  });

  final Stream<List<ModeratedItem>> Function() stream;
  final String emptyText;
  final IconData icon;

  /// Pinned above the list, for a tab that can also add rows.
  final Widget? header;

  Future<void> _confirmDelete(BuildContext context, ModeratedItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this permanently?'),
        content: Text(
          '"${item.title}" will be removed for everyone. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminService.remove(item);
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted "${item.title}".')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete this. Please retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ?header,
      Expanded(
        child: StreamBuilder<List<ModeratedItem>>(
          stream: stream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _TabMessage(
                icon: Icons.cloud_off_outlined,
                text: 'Could not load this list. Check your connection.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!;
            if (items.isEmpty) return _TabMessage(icon: icon, text: emptyText);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: items.length,
              itemBuilder: (context, index) => _ModerationRow(
                item: items[index],
                icon: icon,
                onDelete: _confirmDelete,
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _ModerationRow extends StatelessWidget {
  const _ModerationRow({
    required this.item,
    required this.icon,
    required this.onDelete,
  });

  final ModeratedItem item;
  final IconData icon;
  final Future<void> Function(BuildContext, ModeratedItem) onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: item.collection == AdminService.feedbackCollection
                    ? 4
                    : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (item.ownerLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.ownerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () => onDelete(context, item),
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
      ],
    ),
  );
}

/// Centred icon and message used for empty and error states.
class _TabMessage extends StatelessWidget {
  const _TabMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
