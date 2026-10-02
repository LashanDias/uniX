import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/ticket_service.dart';
import '../../widgets/safe_network_image.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  bool _wallet = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
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
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_wallet)
            _ticketCard()
          else ...[
            _secureBanner(),
            const SizedBox(height: 16),
            // The two events here used to be written into this file, so no
            // admin could add one and none could ever be removed. They now
            // come from Firestore, which is what lets an admin pull an event
            // at any time from the Tickets tab of the admin panel.
            StreamBuilder<List<TicketEvent>>(
              stream: TicketService.watch(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _TicketsMessage(
                    icon: Icons.cloud_off_outlined,
                    text: 'Could not load events. Check your connection.',
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
                  return const _TicketsMessage(
                    icon: Icons.confirmation_number_outlined,
                    text: 'No events on sale right now. Check back soon.',
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
  Widget _eventCard(
    String title,
    String details,
    String price,
    String imageUrl,
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
                    onPressed: () => setState(() => _wallet = true),
                    child: const Text('Buy ticket'),
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
    child: const Column(
      children: [
        Text(
          'TALENT NIGHT 2026',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 18),
        Icon(Icons.qr_code_2, color: Colors.white, size: 180),
        SizedBox(height: 12),
        Text('Scan QR to Enter', style: TextStyle(color: Colors.white70)),
      ],
    ),
  );
}

/// A centred icon and line, for the empty and error states.
class _TicketsMessage extends StatelessWidget {
  const _TicketsMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
    child: Column(
      children: [
        Icon(icon, size: 44, color: AppColors.textLight),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
