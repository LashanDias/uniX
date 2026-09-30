import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../services/boarding_store.dart';
import '../../services/girls_hostel_inventory.dart';
import 'boarding_screen.dart';
import 'girls_hostel_screen.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/safe_network_image.dart';

class HostelItem {
  const HostelItem({
    required this.name,
    required this.gender,
    required this.rooms,
    required this.imageUrl,
    required this.highlights,
    required this.price,
    this.phone = HostelsScreen.wardenPhone,
    this.address = HostelsScreen.campusAddress,
  });

  final String name;
  final String gender;
  final int rooms;
  final String imageUrl;
  final List<String> highlights;
  final int price;

  /// Warden hotline students should call about this hostel.
  final String phone;

  /// Street address used for the map link and the contact card.
  final String address;

  /// Google Maps link for this hostel.
  ///
  /// Uses the campus coordinates rather than a name search, because
  /// searching "Girls Hostel A, SLTC" finds nothing and drops the pin
  /// somewhere unhelpful.
  Uri get mapsUrl => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query':
        '${HostelsScreen.campusLatitude},${HostelsScreen.campusLongitude}',
  });

  /// `tel:` link for [phone], with spaces stripped so dialers accept it.
  Uri get phoneUrl => Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
}

class HostelsScreen extends StatelessWidget {
  const HostelsScreen({super.key});

  /// Single hotline for all campus hostels.
  static const wardenPhone = '0112 100 5000';

  /// SLTC Research University on Google Maps, as coordinates.
  ///
  /// A name search can land on the wrong place; these are the campus's own
  /// coordinates, so the pin is always right.
  static const campusLatitude = 6.8539907;
  static const campusLongitude = 80.0929173;

  /// Campus address shared by every hostel block.
  static const campusAddress =
      'SLTC Research University, Ingiriya Road, Padukka, Sri Lanka';

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
        // Boarding has real listings now; Annex Houses does not yet.
        builder: (_) => type == 'Boarding'
            ? const BoardingScreen()
            : type == 'Annex Houses'
            ? const BoardingScreen(category: BoardingCategory.annex)
            : Scaffold(
                appBar: AppBar(
                  leading: const AppBackButton(),
                  title: Text(type),
                ),
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

  /// Viewport heights below this drop decoration in favour of content.
  ///
  /// Real phones are far taller; this only trips on a resized desktop window
  /// or a split-screen view, where a 190px photo would hide the warden's
  /// number and the room list entirely.
  static const compactHeightBreakpoint = 420.0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(hostel.name), centerTitle: true),
    // LayoutBuilder, not MediaQuery: we need the height actually granted to
    // the body, which is the window minus the app bar and any system insets.
    body: LayoutBuilder(
      builder: (context, constraints) =>
          _body(compact: constraints.maxHeight < compactHeightBreakpoint),
    ),
  );

  Widget _body({required bool compact}) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    children: [
      // The hero photo is decoration; on a very short viewport the
      // contact details and room list matter more.
      if (!compact) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SafeNetworkImage(
            url: hostel.imageUrl,
            height: 190,
            placeholderIcon: Icons.apartment_outlined,
            placeholderLabel: hostel.name,
          ),
        ),
        const SizedBox(height: 18),
        // The AppBar already shows the name, so repeat it only when
        // there is room to spare.
        Text(
          hostel.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
      ],
      Text(
        '${hostel.rooms} rooms available  •  ${hostel.gender} students',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 14),
      _HostelContactCard(hostel: hostel),
      const SizedBox(height: 22),
      const Text(
        'Choose your room',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      // Rates come from the shared inventory rather than arithmetic on a
      // per-hostel figure, which produced prices contradicting the published
      // ones and offered a 2-sharing room the halls do not have.
      _RoomCard(
        hostel: hostel,
        title: '4-sharing room',
        beds: '4 students per room',
        price: GirlsHostelInventory.monthlyPrice(4),
      ),
      _RoomCard(
        hostel: hostel,
        title: '6-sharing room',
        beds: '6 students per room',
        price: GirlsHostelInventory.monthlyPrice(6),
      ),
    ],
  );
}

/// Warden hotline, address and map link for a hostel.
///
/// Students repeatedly needed a way to reach the warden and find the block
/// before booking, so this sits at the bottom of every hostel detail page.
class _HostelContactCard extends StatelessWidget {
  const _HostelContactCard({required this.hostel});

  final HostelItem hostel;

  Future<void> _open(BuildContext context, Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not open this. Details: ${hostel.phone}'),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open this. Details: ${hostel.phone}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Us',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Call the warden with any question before you book.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => _open(context, hostel.phoneUrl),
          child: Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                hostel.phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hostel.address,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _open(context, hostel.mapsUrl),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('View on Google Maps'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
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
