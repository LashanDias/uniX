import 'package:flutter/material.dart';

/// Drawn stand-in artwork for a marketplace listing.
///
/// Used both for seeded preview listings and, via [kindFor], whenever a real
/// listing has no photo or its photo fails to load. A drawn card reads far
/// better in the grid than a bare grey "broken image" icon.
class MarketplacePreviewArt extends StatelessWidget {
  const MarketplacePreviewArt({super.key, required this.kind});
  final String kind;

  /// Title and category keywords mapped to the artwork they should use.
  ///
  /// Ordered most specific first: "calculator" must win before "book", and
  /// "physics" before the generic book art.
  static const _keywords = <String, List<String>>{
    'physics': ['physics'],
    'math': ['math', 'calculus', 'algebra', 'statistic'],
    'programming': ['program', 'coding', 'software', 'python', 'java', 'dart'],
    'calculator': ['calculator', 'casio'],
    'audio': ['earbud', 'earphone', 'headphone', 'airpod', 'speaker', 'audio'],
    'laptop': ['laptop', 'macbook', 'notebook computer'],
    'phone': ['phone', 'iphone', 'android', 'mobile'],
    'camera': ['camera', 'dslr', 'lens'],
    'lamp': ['lamp', 'light'],
    'bag': ['bag', 'backpack', 'luggage'],
    'painting': ['paint', 'art', 'canvas', 'drawing'],
    'flowers': ['flower', 'bouquet', 'floral'],
    'craft': ['craft', 'crochet', 'handmade', 'knit'],
    'book': ['book', 'textbook', 'novel', 'guide'],
  };

  /// Picks artwork for a listing from its [title] and [category].
  ///
  /// Falls back to stationery, which is deliberately generic.
  static String kindFor(String title, String category) {
    final haystack = '$title $category'.toLowerCase();
    for (final entry in _keywords.entries) {
      if (entry.value.any(haystack.contains)) return entry.key;
    }
    return 'stationery';
  }
  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (kind) {
      'math' => (
        Icons.functions,
        const Color(0xFF235B88),
        'ENGINEERING\nMATHEMATICS',
      ),
      'physics' => (
        Icons.science_outlined,
        const Color(0xFF644797),
        'FOUNDATIONS\nOF PHYSICS',
      ),
      'programming' => (
        Icons.code,
        const Color(0xFF23745D),
        'LEARN TO\nPROGRAM',
      ),
      'phone' => (Icons.smartphone, const Color(0xFF455A64), 'SMARTPHONE'),
      'camera' => (Icons.camera_alt, const Color(0xFF37474F), 'DSLR CAMERA'),
      'lamp' => (Icons.light_outlined, const Color(0xFFAF7A26), 'STUDY LAMP'),
      'painting' => (
        Icons.palette_outlined,
        const Color(0xFFB75470),
        'HANDMADE ART',
      ),
      'flowers' => (
        Icons.local_florist,
        const Color(0xFFCA658E),
        'FLOWER BOUQUET',
      ),
      'craft' => (Icons.interests, const Color(0xFFB4814F), 'CROCHET CRAFT'),
      'calculator' => (
        Icons.calculate_outlined,
        const Color(0xFF3E6B8A),
        'CALCULATOR',
      ),
      'audio' => (
        Icons.headphones_outlined,
        const Color(0xFF5B5470),
        'AUDIO GEAR',
      ),
      'laptop' => (
        Icons.laptop_mac_outlined,
        const Color(0xFF41566B),
        'LAPTOP',
      ),
      'bag' => (Icons.backpack_outlined, const Color(0xFF8A5A3B), 'BAG'),
      'book' => (Icons.menu_book, const Color(0xFF4A6FA5), 'TEXTBOOK'),
      _ => (Icons.edit_note, const Color(0xFF548578), 'STATIONERY'),
    };
    final book = ['math', 'physics', 'programming', 'book'].contains(kind);
    return Center(
      child: Container(
        width: book ? 80 : 116,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: book ? color : color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(book ? 3 : 16),
          border: book
              ? Border(
                  left: BorderSide(
                    color: Colors.black.withValues(alpha: .2),
                    width: 6,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: book ? 34 : 42,
              color: book ? Colors.white : color,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: book ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
