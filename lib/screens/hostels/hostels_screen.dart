import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'girls_hostel_screen.dart';
import '../../widgets/app_back_button.dart';

class HostelItem {
  const HostelItem({
    required this.name,
    required this.gender,
    required this.rooms,
    required this.imageUrl,
    required this.highlights,
    required this.price,
  });

  final String name;
  final String gender;
  final int rooms;
  final String imageUrl;
  final List<String> highlights;
  final int price;
}

class HostelsScreen extends StatelessWidget {
  const HostelsScreen({super.key});

  static const hostels = [
    HostelItem(
      name: 'Boys Hostel A',
      gender: 'Boys',
      rooms: 80,
      imageUrl:
          'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=900&q=80',
      highlights: ['4 Sharing room', '2 Beds available', '3 Beds available'],
      price: 9500,
    ),
    HostelItem(
      name: 'Boys Hostel B',
      gender: 'Boys',
      rooms: 60,
      imageUrl:
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
      highlights: ['4 Sharing room', '2 Beds available', '3 Beds available'],
      price: 10500,
    ),
    HostelItem(
      name: 'Girls Hostel A',
      gender: 'Girls',
      rooms: 80,
      imageUrl:
          'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=900&q=80',
      highlights: ['4 Sharing room', '2 Beds available', '3 Beds available'],
      price: 10000,
    ),
    HostelItem(
      name: 'Girls Hostel B',
      gender: 'Girls',
      rooms: 80,
      imageUrl:
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=900&q=80',
      highlights: ['4 Sharing room', '2 Beds available', '3 Beds available'],
      price: 11000,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Choose Accommodation'),
      centerTitle: true,
    ),
    body: SafeArea(child: _GenderChoiceBody()),
  );
}

class _GenderChoiceBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
    children: [
      const Text(
        'Where would you like to stay?',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Choose a hostel, boarding room, or annex house.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 24),
      _GenderCard(
        title: 'Boys Hostel',
        subtitle: 'Pending — details will be available later',
        icon: Icons.man_outlined,
        color: const Color(0xFFE7F0FF),
        onTap: () => _openHostels(context, 'Boys'),
      ),
      const SizedBox(height: 16),
      _GenderCard(
        title: 'Girls Hostel',
        subtitle: 'Safe and comfortable rooms for female students',
        icon: Icons.woman_outlined,
        color: const Color(0xFFFFEAF1),
        onTap: () => _openHostels(context, 'Girls'),
      ),
      const SizedBox(height: 16),
      _GenderCard(
        title: 'Boarding',
        subtitle: 'Student boarding rooms',
        icon: Icons.bed_outlined,
        color: const Color(0xFFEAF8F0),
        onTap: () => _openAccommodation(context, 'Boarding'),
      ),
      const SizedBox(height: 16),
      _GenderCard(
        title: 'Annex Houses',
        subtitle: 'Independent spaces for students',
        icon: Icons.house_outlined,
        color: const Color(0xFFFFF2DF),
        onTap: () => _openAccommodation(context, 'Annex Houses'),
      ),
    ],
  );

  void _openAccommodation(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(leading: const AppBackButton(), title: Text(type)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == 'Boarding'
                        ? Icons.bed_outlined
                        : Icons.house_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$type listings coming soon',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No listings have been added yet.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openHostels(BuildContext context, String gender) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HostelListScreen(gender: gender)),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    ),
  );
}

class HostelListScreen extends StatelessWidget {
  const HostelListScreen({super.key, required this.gender});
  final String gender;

  @override
  Widget build(BuildContext context) {
    if (gender == 'Girls') return const GirlsHostelScreen();
    if (gender == 'Boys') {
      return Scaffold(
        appBar: AppBar(title: const Text('Boys Hostels')),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 52,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Pending',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Boys hostel details are not available yet.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final hostels = HostelsScreen.hostels
        .where((h) => h.gender == gender)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text('$gender Hostels'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            '$gender hostels only',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose one hostel to view rooms and prices.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          ...hostels.map(
            (hostel) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _HostelTile(hostel: hostel),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostelTile extends StatelessWidget {
  const _HostelTile({required this.hostel});
  final HostelItem hostel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary, width: 1.2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                hostel.imageUrl,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 62,
                  height: 62,
                  color: AppColors.primaryLight,
                  child: const Icon(
                    Icons.home_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hostel.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${hostel.rooms} Rooms Available',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'View rooms',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HostelDetailsScreen(hostel: hostel),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_ios, size: 17),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: hostel.highlights
              .map(
                (highlight) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    highlight,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class HostelDetailsScreen extends StatelessWidget {
  const HostelDetailsScreen({super.key, required this.hostel});
  final HostelItem hostel;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(hostel.name), centerTitle: true),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(hostel.imageUrl, height: 190, fit: BoxFit.cover),
        ),
        const SizedBox(height: 18),
        Text(
          hostel.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${hostel.rooms} rooms available  •  ${hostel.gender} students',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 22),
        const Text(
          'Choose your room',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _RoomCard(
          hostel: hostel,
          title: '2-sharing room',
          beds: '2 beds available',
          price: hostel.price + 2500,
        ),
        _RoomCard(
          hostel: hostel,
          title: '4-sharing room',
          beds: '3 beds available',
          price: hostel.price,
        ),
        _RoomCard(
          hostel: hostel,
          title: '6-sharing room',
          beds: '2 beds available',
          price: hostel.price - 1500,
        ),
      ],
    ),
  );
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.hostel,
    required this.title,
    required this.beds,
    required this.price,
  });
  final HostelItem hostel;
  final String title;
  final String beds;
  final int price;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const CircleAvatar(child: Icon(Icons.bed_outlined)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$beds\nLKR $price / month'),
      isThreeLine: true,
      trailing: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PaymentScreen(hostel: hostel, roomType: title, price: price),
          ),
        ),
        child: const Text('Book'),
      ),
    ),
  );
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.hostel,
    required this.roomType,
    required this.price,
  });
  final HostelItem hostel;
  final String roomType;
  final int price;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment'), centerTitle: true),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text(
          'Confirm your booking',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _SummaryRow(label: 'Hostel', value: widget.hostel.name),
        _SummaryRow(label: 'Room', value: widget.roomType),
        _SummaryRow(label: 'Monthly price', value: 'LKR ${widget.price}'),
        const SizedBox(height: 20),
        const Text(
          'Email for booking confirmation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'yourname@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 26),
        ElevatedButton.icon(
          onPressed: () {
            final email = _emailController.text.trim().isEmpty
                ? 'your email address'
                : _emailController.text.trim();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BookingConfirmationScreen(
                  hostel: widget.hostel,
                  roomType: widget.roomType,
                  email: email,
                ),
              ),
            );
          },
          icon: const Icon(Icons.credit_card),
          label: const Text('Pay and confirm booking'),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.hostel,
    required this.roomType,
    required this.email,
  });
  final HostelItem hostel;
  final String roomType;
  final String email;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking confirmed'), centerTitle: true),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFDDF7E8),
              child: Icon(Icons.check, size: 44, color: Colors.green),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your room is booked!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking details were sent to $email',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.primary),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Hostel', value: hostel.name),
                    _SummaryRow(label: 'Room type', value: roomType),
                    const _SummaryRow(label: 'Status', value: 'Confirmed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to home'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ApplyHostelScreen extends StatefulWidget {
  const ApplyHostelScreen({super.key, this.initialHostel});
  final String? initialHostel;

  @override
  State<ApplyHostelScreen> createState() => _ApplyHostelScreenState();
}

class _ApplyHostelScreenState extends State<ApplyHostelScreen> {
  late String _hostel = widget.initialHostel ?? 'Boys Hostel A';
  String _roomType = '4 Sharing room';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Apply for Hostel')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Full Name'),
            const TextField(
              decoration: InputDecoration(hintText: 'Enter your full name'),
            ),
            _gap(),
            _label('Hostel'),
            DropdownButtonFormField<String>(
              initialValue: _hostel,
              items: HostelsScreen.hostels
                  .map(
                    (h) => DropdownMenuItem(value: h.name, child: Text(h.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _hostel = v!),
            ),
            _gap(),
            _label('Location'),
            const TextField(
              decoration: InputDecoration(hintText: 'Enter your location'),
            ),
            _gap(),
            _label('Room Type'),
            DropdownButtonFormField<String>(
              initialValue: _roomType,
              items: const [
                '4 Sharing room',
                '2 Beds available',
                '3 Beds available',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _roomType = v!),
            ),
            _gap(),
            _label('Reason'),
            const TextField(
              maxLines: 5,
              decoration: InputDecoration(hintText: 'Type reason...'),
            ),
            const SizedBox(height: 72),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hostel application submitted')),
                );
                Navigator.pop(context);
              },
              child: const Text('Submit Application'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );

  Widget _gap() => const SizedBox(height: 14);
}
