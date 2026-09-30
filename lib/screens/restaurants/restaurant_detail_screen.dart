import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant.dart';
import '../../widgets/app_back_button.dart';
import '../../services/restaurant_store.dart';
import 'restaurant_widgets.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    required this.store,
    this.initiallySaved = false,
    this.initialTab = 0,
  });
  final Restaurant restaurant;
  final RestaurantStore store;
  final bool initiallySaved;
  final int initialTab;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late int _tab = widget.initialTab;
  String _meal = 'All';
  late bool _saved = widget.initiallySaved;
  bool _saving = false;
  Restaurant get place => widget.restaurant;

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _open(Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _message('Could not open this link. You can copy the details below.');
      }
    } catch (_) {
      _message('Could not open this link. You can copy the details below.');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.store.setSaved(place.id, !_saved);
      if (mounted) setState(() => _saved = !_saved);
    } catch (_) {
      _message('Could not update saved restaurants. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text:
              '${place.name}\n${place.address}\n${place.phone}\n${place.mapsUrl}',
        ),
      );
      _message('Restaurant details copied. Paste them to share.');
    } catch (_) {
      _message('Clipboard unavailable. Select and copy the address below.');
    }
  }

  Widget _action(IconData icon, String label, VoidCallback? action) =>
      OutlinedButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          foregroundColor: foodInk,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: foodCanvas,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Restaurant details'),
      backgroundColor: foodCanvas,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: foodAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: foodInk,
                  ),
                ),
                const SizedBox(height: 8),
                if (place.rating != null)
                  Text(
                    '★ ${place.rating!.toStringAsFixed(1)} · ${place.reviewCount} reviews in shared listing',
                    style: const TextStyle(color: foodAccent, fontSize: 13),
                  ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: RestaurantPhoto(
                    photoBase64: place.photoBase64,
                    height: 220,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _action(
                      Icons.directions_outlined,
                      'Directions',
                      () => _open(place.directionsUrl),
                    ),
                    _action(
                      Icons.call_outlined,
                      'Call',
                      place.phone.isEmpty ? null : () => _open(place.phoneUrl),
                    ),
                    _action(
                      _saved ? Icons.bookmark : Icons.bookmark_border,
                      _saved ? 'Saved' : 'Save',
                      _saving ? null : _save,
                    ),
                    _action(Icons.share_outlined, 'Share', _share),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (index, label) in [
                        'Overview',
                        'Menu',
                        'Reviews',
                        'Photos',
                      ].indexed)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _tab == index,
                            showCheckmark: false,
                            selectedColor: const Color(0xFFEBF0FF),
                            onSelected: (_) => setState(() => _tab = index),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (_tab == 0) ..._overview(),
                if (_tab == 1) ..._menu(),
                if (_tab == 2) ..._reviews(),
                if (_tab == 3) ...[
                  Text(
                    place.photoBase64.isEmpty
                        ? 'Food inspiration'
                        : 'Restaurant photo',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: foodInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (place.photoBase64.isEmpty)
                    const FoodNotice(
                      text:
                          'This is an illustrative food image, not a verified photo of this venue.',
                    ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: RestaurantPhoto(
                      photoBase64: place.photoBase64,
                      height: 340,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _overview() => [
    Text(
      place.description,
      style: const TextStyle(height: 1.6, color: foodInk),
    ),
    const SizedBox(height: 18),
    _fact(Icons.location_on_outlined, 'Address', place.address),
    _fact(
      Icons.schedule,
      'Hours',
      place.hours.isEmpty
          ? 'Not confirmed — check with the venue.'
          : place.hours,
    ),
    _fact(
      Icons.phone_outlined,
      'Phone',
      place.phone.isEmpty ? 'Phone number not available.' : place.phone,
    ),
    if (place.reference)
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: FoodNotice(
          text:
              'Reference listing. Confirm current hours, ratings and contact details with the venue.',
        ),
      ),
    const SizedBox(height: 24),
    const Text(
      'Menu highlights',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: foodInk,
      ),
    ),
    const SizedBox(height: 12),
    if (place.sampleMenu)
      const FoodNotice(
        text:
            'Sample menu · estimated prices. These are suggested dishes, not a confirmed menu.',
      ),
    const SizedBox(height: 12),
    for (final food in place.menu.take(3)) _food(food),
    TextButton.icon(
      onPressed: () => setState(() => _tab = 1),
      icon: const Icon(Icons.restaurant_menu),
      label: const Text('View full menu'),
    ),
  ];

  Widget _fact(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: foodAccent, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: const TextStyle(color: foodInk, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  List<Widget> _menu() {
    final groups = ['All', ...place.menu.map((food) => food.category).toSet()];
    final foods = place.menu.where(
      (food) => _meal == 'All' || food.category == _meal,
    );
    return [
      const Text(
        'What’s on the menu',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: foodInk,
        ),
      ),
      const SizedBox(height: 12),
      FoodNotice(
        text: place.sampleMenu
            ? 'Sample menu · estimated LKR prices. Created for this app because a readable menu was not available. Confirm dishes and prices with the venue.'
            : 'Menu added by a user. Confirm current prices and availability with the venue.',
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final group in groups)
            ChoiceChip(
              label: Text(group),
              selected: _meal == group,
              onSelected: (_) => setState(() => _meal = group),
            ),
        ],
      ),
      const SizedBox(height: 16),
      for (final food in foods) _food(food),
    ];
  }

  Widget _food(RestaurantFood food) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          food.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: foodInk,
          ),
        ),
        if (food.description.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            food.description,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              '${place.sampleMenu ? 'Est. ' : ''}Rs. ${food.price.toStringAsFixed(food.price % 1 == 0 ? 0 : 2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: foodAccent,
              ),
            ),
            Text(
              food.category,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (food.vegetarian)
              const Text(
                'Vegetarian',
                style: TextStyle(fontSize: 12, color: Color(0xFF33724B)),
              ),
          ],
        ),
      ],
    ),
  );

  List<Widget> _reviews() => [
    const Text(
      'Reviews',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: foodInk,
      ),
    ),
    const SizedBox(height: 16),
    if (place.rating != null) ...[
      Text(
        '${place.rating!.toStringAsFixed(1)} / 5',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: foodInk,
        ),
      ),
      Text('${place.reviewCount} reviews in your shared listing'),
      const SizedBox(height: 12),
      const FoodNotice(
        text:
            'This is a reference rating, not a live Google review feed. Individual reviews and rating breakdowns are not available in the supplied listing.',
      ),
    ] else
      const FoodNotice(
        text:
            'No verified reviews are available in the app for this venue yet.',
      ),
    const SizedBox(height: 16),
    _action(
      Icons.open_in_new,
      'View on Google Maps',
      () => _open(place.mapsUrl),
    ),
  ];
}
