import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/ticket_service.dart';
import '../../widgets/safe_network_image.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  bool _wallet = false;
  TicketEvent? _selectedEvent;
  late Stream<List<TicketEvent>> _events;

  @override
  void initState() {
    super.initState();
    _events = TicketService.watch();
  }

  Future<void> _addEvent() async {
    final published = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddTicketDialog(),
    );
    if (!mounted || published != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event added to Campus Tickets.')),
    );
  }

  void _retryLoading() {
    setState(() => _events = TicketService.watch());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: Text(_wallet ? 'My Ticket Wallet' : 'Campus Tickets'),
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => _wallet = !_wallet),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: Text(_wallet ? 'Browse' : 'Wallet'),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth > 1200
              ? 1200.0
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: contentWidth,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_wallet)
                    _ticketCard()
                  else ...[
                    _secureBanner(),
                    const SizedBox(height: 16),
                    if (AuthService.isCurrentUserAdmin()) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _addEvent,
                          icon: const Icon(Icons.add),
                          label: const Text('Add tickets'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Upcoming events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // The two events here used to be written into this file, so no
                    // admin could add one and none could ever be removed. They now
                    // come from Firestore, which is what lets an admin pull an event
                    // at any time from the Tickets tab of the admin panel.
                    StreamBuilder<List<TicketEvent>>(
                      stream: _events,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              _TicketsMessage(
                                icon: Icons.cloud_off_outlined,
                                text: _eventLoadError(snapshot.error),
                                action: FilledButton.icon(
                                  onPressed: _retryLoading,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ),
                              _sampleEventsPreview(),
                            ],
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final events = snapshot.data!;
                        if (events.isEmpty) {
                          return Column(
                            children: [
                              _TicketsMessage(
                                icon: Icons.confirmation_number_outlined,
                                text: AuthService.isCurrentUserAdmin()
                                    ? 'No live events yet. Add an event above to put tickets on sale.'
                                    : 'No live events are on sale right now.',
                              ),
                              _sampleEventsPreview(),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            for (final event in events) ...[
                              _eventCard(
                                event.title,
                                event.details,
                                event.price,
                                event.imageUrl,
                                onBuy: () => setState(() {
                                  _selectedEvent = event;
                                  _wallet = true;
                                }),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _secureBanner() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Icon(Icons.shield_outlined, color: AppColors.primary),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Verified university events • Secure payment protection',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  String _eventLoadError(Object? error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'You do not have permission to view events. Sign in with your campus account and try again.';
      }
      if (error.code == 'unavailable' ||
          error.code == 'network-request-failed') {
        return 'Tickets are temporarily unavailable. Check your connection and retry.';
      }
      return 'Could not load events (${error.code}). Retry or contact an administrator.';
    }
    return 'Could not load events. Retry or check your connection.';
  }

  Widget _sampleEventsPreview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          'Sample events',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      for (final event in TicketService.sampleEvents()) ...[
        _eventCard(
          event.title,
          event.details,
          event.price,
          event.imageUrl,
          sample: true,
        ),
        const SizedBox(height: 14),
      ],
    ],
  );

  Widget _eventCard(
    String title,
    String details,
    String price,
    String imageUrl,
    {bool sample = false, VoidCallback? onBuy},
  ) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeNetworkImage(
          url: imageUrl,
          height: 140,
          placeholderIcon: Icons.confirmation_number_outlined,
          placeholderLabel: title,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.success),
                  SizedBox(width: 6),
                  // Flexible so the label ellipsises instead of
                  // overflowing the card on a narrow phone.
                  Flexible(
                    child: Text(
                      'Verified Ticket',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (sample) ...[
                const SizedBox(height: 8),
                const Text(
                  'Preview only · sample event',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                details,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              // Wrap, not Row: the price and the button do not fit side
              // by side on a small phone and must be allowed to stack.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  FilledButton(
                    onPressed: sample ? null : onBuy,
                    child: Text(sample ? 'Preview only' : 'Buy ticket'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _ticketCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Text(
          _selectedEvent?.title ?? 'Select an event to view its ticket',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_selectedEvent != null) ...[
          const SizedBox(height: 8),
          Text(
            _selectedEvent!.details,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 18),
        const Icon(Icons.qr_code_2, color: Colors.white, size: 180),
        const SizedBox(height: 12),
        const Text(
          'Ticket preview · payment is not connected yet',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

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
  bool _saving = false;
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
      _saving = true;
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
              : error is FirebaseException
              ? 'Could not add event (${error.code}). Check Firebase access and retry.'
              : 'Could not add event. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add a campus event'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Event name'),
          ),
          TextField(
            controller: _details,
            decoration: const InputDecoration(labelText: 'Date and venue'),
          ),
          TextField(
            controller: _price,
            decoration: const InputDecoration(labelText: 'Price'),
          ),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              labelText: 'Image link (optional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
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
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Adding...' : 'Add event'),
      ),
    ],
  );
}

/// A centred icon and line, for the empty and error states.
class _TicketsMessage extends StatelessWidget {
  const _TicketsMessage({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: AppColors.textLight),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}
