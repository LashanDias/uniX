import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Somewhere the dashboard search can send you.
///
/// A destination is either a bottom-tab index or a named route, never both.
class SearchDestination {
  const SearchDestination({
    required this.label,
    required this.icon,
    required this.keywords,
    this.tabIndex,
    this.route,
  }) : assert(
         (tabIndex == null) != (route == null),
         'A destination needs exactly one of tabIndex or route',
       );

  final String label;
  final IconData icon;

  /// Extra words that should find this destination, beyond its label.
  final List<String> keywords;

  final int? tabIndex;
  final String? route;

  bool matches(String term) {
    final needle = term.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return label.toLowerCase().contains(needle) ||
        keywords.any((keyword) => keyword.contains(needle));
  }
}

/// Everything reachable from the dashboard search.
///
/// Tab indexes follow MainLayout's screen list: 0 Home, 1 Notes, 2 Market,
/// 3 Jobs, 4 Profile.
const kSearchDestinations = <SearchDestination>[
  SearchDestination(
    label: 'Notes',
    icon: Icons.menu_book_outlined,
    keywords: ['note', 'notes', 'study', 'lecture', 'pdf', 'subject'],
    tabIndex: 1,
  ),
  SearchDestination(
    label: 'Short notes from a PDF',
    icon: Icons.auto_awesome_outlined,
    keywords: ['short', 'summary', 'summarise', 'summarize', 'revision'],
    route: '/short_notes',
  ),
  SearchDestination(
    label: 'Formula sheets',
    icon: Icons.functions,
    keywords: ['formula', 'statistics', 'variance', 'probability', 'maths',
      'math', 'equation', 'reference', 'revision'],
    route: '/formula_sheets',
  ),
  SearchDestination(
    label: 'Marketplace',
    icon: Icons.shopping_cart_outlined,
    keywords: ['market', 'buy', 'sell', 'gear', 'shop', 'item', 'product'],
    tabIndex: 2,
  ),
  SearchDestination(
    label: 'Jobs',
    icon: Icons.work_outline,
    keywords: ['job', 'vacancy', 'career', 'internship', 'cv', 'work'],
    tabIndex: 3,
  ),
  SearchDestination(
    label: 'Micro gigs',
    icon: Icons.bolt_outlined,
    keywords: ['gig', 'gigs', 'freelance', 'part time', 'micro'],
    route: '/micro_gigs',
  ),
  SearchDestination(
    label: 'Career passport',
    icon: Icons.badge_outlined,
    keywords: ['passport', 'skills', 'profile', 'certificate'],
    route: '/career_passport',
  ),
  SearchDestination(
    label: 'Hostels',
    icon: Icons.apartment_outlined,
    keywords: ['hostel', 'room', 'accommodation', 'boarding', 'stay'],
    route: '/hostels',
  ),
  SearchDestination(
    label: 'Restaurants',
    icon: Icons.restaurant_outlined,
    keywords: ['restaurant', 'food', 'canteen', 'cafe', 'eat', 'menu'],
    route: '/restaurants',
  ),
  SearchDestination(
    label: 'Lost & Found',
    icon: Icons.search_outlined,
    keywords: ['lost', 'found', 'missing', 'wallet', 'keys'],
    route: '/lost_found',
  ),
  SearchDestination(
    label: 'Notice Board',
    icon: Icons.campaign_outlined,
    keywords: ['notice', 'notices', 'board', 'announcement', 'flyer',
      'event', 'agm', 'club'],
    route: '/notice_board',
  ),
  SearchDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    keywords: ['setting', 'settings', 'notification', 'preferences'],
    route: '/settings',
  ),
  SearchDestination(
    label: 'Tickets',
    icon: Icons.confirmation_number_outlined,
    keywords: ['ticket', 'tickets', 'event', 'booking'],
    route: '/tickets',
  ),
  SearchDestination(
    label: 'Notifications',
    icon: Icons.notifications_none_outlined,
    keywords: ['notification', 'alerts', 'updates'],
    route: '/notifications',
  ),
  SearchDestination(
    label: 'My profile',
    icon: Icons.person_outline,
    keywords: ['profile', 'account', 'me', 'settings'],
    tabIndex: 4,
  ),
];

/// Returns the destinations matching [term], best first.
///
/// A label that starts with the term ranks above one that merely contains it,
/// so typing "note" offers Notes before Short notes.
List<SearchDestination> searchDestinations(
  String term, {
  List<SearchDestination> from = kSearchDestinations,
}) {
  final needle = term.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  final matches = from.where((d) => d.matches(needle)).toList();
  matches.sort((a, b) {
    final aStarts = a.label.toLowerCase().startsWith(needle) ? 0 : 1;
    final bStarts = b.label.toLowerCase().startsWith(needle) ? 0 : 1;
    return aStarts != bStarts
        ? aStarts.compareTo(bStarts)
        : a.label.compareTo(b.label);
  });
  return matches;
}

/// The dashboard search field, with live suggestions underneath.
///
/// The field used to be decoration only: no controller and no callbacks, so
/// typing in it did nothing at all.
class DashboardSearch extends StatefulWidget {
  const DashboardSearch({super.key, required this.onNavigateTab});

  final void Function(int index) onNavigateTab;

  @override
  State<DashboardSearch> createState() => _DashboardSearchState();
}

class _DashboardSearchState extends State<DashboardSearch> {
  final _controller = TextEditingController();
  List<SearchDestination> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) =>
      setState(() => _results = searchDestinations(value));

  void _open(SearchDestination destination) {
    _controller.clear();
    setState(() => _results = const []);
    FocusScope.of(context).unfocus();
    final route = destination.route;
    if (route != null) {
      Navigator.pushNamed(context, route);
    } else {
      widget.onNavigateTab(destination.tabIndex!);
    }
  }

  void _onSubmitted(String value) {
    if (_results.isNotEmpty) _open(_results.first);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: _controller,
        onChanged: _onChanged,
        onSubmitted: _onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search notes, hostels, tickets, or gear...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                ),
          fillColor: const Color(0xFFF4F6F8),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      if (_controller.text.trim().isNotEmpty) ...[
        const SizedBox(height: 8),
        // Material, not a plain Container: the suggestions are ListTiles, and
        // they paint their ink splash on the nearest Material ancestor.
        Material(
          color: AppColors.cardBg,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: _results.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Nothing matches that. Try "notes", "hostel", "food" '
                    'or "jobs".',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final destination in _results.take(6))
                      ListTile(
                        dense: true,
                        leading: Icon(
                          destination.icon,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          destination.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () => _open(destination),
                      ),
                  ],
                ),
        ),
      ],
    ],
  );
}
