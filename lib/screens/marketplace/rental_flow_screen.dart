import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RentalFlowScreen extends StatefulWidget {
  const RentalFlowScreen({super.key});
  @override
  State<RentalFlowScreen> createState() => _RentalFlowScreenState();
}

class _RentalFlowScreenState extends State<RentalFlowScreen> {
  int step = 0;
  DateTimeRange dates = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 3)),
  );
  Future<void> pickDates() async {
    final value = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: dates,
    );
    if (value != null) setState(() => dates = value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        [
          'Rent equipment',
          'ESP32 Dev Board',
          'Secure checkout',
          'Payment successful',
        ][step],
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: switch (step) {
        0 => _browse(),
        1 => _detail(),
        2 => _checkout(),
        _ => _success(),
      },
    ),
  );
  Widget _browse() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'Buy', label: Text('Buy')),
          ButtonSegment(value: 'Sell', label: Text('Sell')),
          ButtonSegment(value: 'Rent', label: Text('Rent')),
        ],
        selected: {'Rent'},
      ),
      const SizedBox(height: 20),
      Card(
        child: ListTile(
          onTap: () => setState(() => step = 1),
          leading: const Icon(Icons.memory, size: 42, color: AppColors.primary),
          title: const Text('ESP32 Dev Board Kit - Rs. 150/day'),
          subtitle: const Text('Electronics • ★ 4.9 • Verified SLTC Student'),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    ],
  );
  Widget _detail() => ListView(
    children: [
      Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.memory, size: 100, color: AppColors.primary),
      ),
      const SizedBox(height: 18),
      const Text(
        'ESP32 Dev Board Kit',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Rs. 150/day • Rs. 800/week',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 14),
      const ListTile(
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text('Nimal Perera • Verified SLTC Student'),
        subtitle: Text('★ 4.9 (28 reviews) • Reliable handoffs'),
      ),
      OutlinedButton.icon(
        onPressed: pickDates,
        icon: const Icon(Icons.calendar_month),
        label: Text(
          '${dates.start.day}/${dates.start.month} – ${dates.end.day}/${dates.end.month}',
        ),
      ),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: () => setState(() => step = 2),
        child: const Text('Request to Rent'),
      ),
    ],
  );
  Widget _checkout() {
    final days = dates.duration.inDays + 1;
    final total = days * 150;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rental summary',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text('ESP32 Dev Board Kit • $days days'),
        Text('Rental: Rs. $total'),
        Text('UniTrade secure payment fee (4%): Rs. ${(total * .04).round()}'),
        const Divider(height: 30),
        Text(
          'Total: Rs. ${(total * 1.04).round()}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => setState(() => step = 3),
          icon: const Icon(Icons.lock_outline),
          label: const Text('Confirm Secure Payment'),
        ),
      ],
    );
  }

  Widget _success() => Column(
    children: [
      const Spacer(),
      const Icon(Icons.check_circle, color: AppColors.success, size: 84),
      const SizedBox(height: 16),
      const Text(
        'Payment Successful',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text('Your rental request is confirmed.'),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Nimal: Hi! Payment received. Can we meet near the main library at 2 PM for the handoff?',
        ),
      ),
      const Spacer(),
      ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.chat_outlined),
        label: const Text('Open coordination chat'),
      ),
    ],
  );
}
