import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../widgets/app_back_button.dart';
import '../../services/restaurant_catalog.dart';
import '../../services/restaurant_store.dart';
import 'add_restaurant_screen.dart';
import 'restaurant_detail_screen.dart';
import 'restaurant_widgets.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key, this.store});
  final RestaurantStore? store;

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  late final _store = widget.store ?? RestaurantStore();
  final _search = TextEditingController();
  List<Restaurant> _places = [];
  Set<String> _saved = {};
  String _filter = 'All';
  String _query = '';
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _store.loadAll();
      if (mounted) {
        setState(() {
          _places = result.places;
          _saved = result.saved;
          // Only the student's own additions and saved marks are missing;
          // the catalogue below is still complete, so this is a note rather
          // than a reason to show an empty screen.
          _failed = result.storageFailed;
        });
      }
    } catch (_) {
      // The catalogue is compiled into the app, so fall back to it rather
      // than leaving the student with nothing.
      if (mounted) {
        setState(() {
          _places = restaurantCatalog;
          _saved = <String>{};
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Restaurant place, {bool menu = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RestaurantDetailScreen(
          restaurant: place,
          store: _store,
          initiallySaved: _saved.contains(place.id),
          initialTab: menu ? 1 : 0,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _add() async {
    final added = await Navigator.push<Restaurant>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRestaurantScreen(onSave: _store.add),
      ),
    );
    if (!mounted || added == null) return;
    _search.clear();
    setState(() {
      _query = '';
      _filter = 'All';
    });
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${added.name} saved on this device.'),
          action: SnackBarAction(label: 'View', onPressed: () => _open(added)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _places
        .where(
          (place) =>
              place.matches(_query) &&
              (_filter == 'All' ||
                  (_filter == 'Canteens' && place.isCanteen) ||
                  (_filter == 'Restaurants' &&
                      place.category == 'Restaurant') ||
                  (_filter == 'Cafés' && place.category == 'Café') ||
                  (_filter == 'Saved' && _saved.contains(place.id))),
        )
        .toList();
    return Scaffold(
      backgroundColor: foodCanvas,
      // A pinned button, not one inline under the filter chips: on a phone
      // that one sat below the fold, so adding a place meant scrolling first.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: foodAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add Restaurant'),
      ),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Restaurants & Canteens'),
        backgroundColor: foodCanvas,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxWidth - 40;
                final cardWidth = available >= 760
                    ? (available - 16) / 2
                    : available;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: foodInk,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THE CAMPUS FOOD GUIDE',
                              style: TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 11,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Good food.\nClose to campus.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Local favourites, café breaks and your SLTC canteens.',
                              style: TextStyle(
                                color: Color(0xFFEBF0FF),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search restaurants, food or location',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final label in [
                              'All',
                              'Canteens',
                              'Restaurants',
                              'Cafés',
                              'Saved',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: _filter == label,
                                  showCheckmark: false,
                                  selectedColor: const Color(0xFFEBF0FF),
                                  onSelected: (_) =>
                                      setState(() => _filter = label),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_failed) ...[
                        const FoodNotice(
                          text:
                              'Could not load your saved restaurant list. Your data has not been replaced.',
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ] else ...[
                        Text(
                          '${places.length} places to explore',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: foodInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sample menus are labelled; confirm prices with the venue.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        if (places.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              _filter == 'Saved'
                                  ? 'No saved places match. Save a restaurant from its details page.'
                                  : 'No matching places. Try another search or add a restaurant.',
                            ),
                          ),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final place in places)
                              SizedBox(width: cardWidth, child: _card(place)),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Restaurant place) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _open(place),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 145,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RestaurantPhoto(photoBase64: place.photoBase64, height: 145),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: place.isCanteen ? foodInk : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      place.isCanteen ? 'SLTC · Canteen' : place.category,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: place.isCanteen ? Colors.white : foodInk,
                      ),
                    ),
                  ),
                ),
                if (_saved.contains(place.id))
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.bookmark, size: 18, color: foodAccent),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: foodInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  place.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (place.rating != null)
                  Text(
                    '★ ${place.rating!.toStringAsFixed(1)} (${place.reviewCount}) · Reference rating',
                    style: const TextStyle(
                      color: foodAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${place.menu.length} dishes · ${place.sampleMenu ? 'Sample menu' : 'Added menu'}',
                  style: const TextStyle(fontSize: 12, color: foodInk),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _open(place, menu: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: foodInk,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    icon: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text('View menu'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
