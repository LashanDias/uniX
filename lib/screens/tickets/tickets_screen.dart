import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

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
            _eventCard(
              'Talent Night 2026 - Early Bird Access',
              'Sep 18 • Main Auditorium',
              'LKR 750',
            ),
            const SizedBox(height: 14),
            _eventCard(
              'Tech Expo & Career Fair',
              'Sep 23 • Innovation Centre',
              'Free',
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
  Widget _eventCard(String title, String details, String price) => Card(
    child: Padding(
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
                child: Text('Verified Ticket', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(details, style: const TextStyle(color: AppColors.textSecondary)),
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
