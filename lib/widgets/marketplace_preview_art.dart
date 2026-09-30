import 'package:flutter/material.dart';

class MarketplacePreviewArt extends StatelessWidget {
  const MarketplacePreviewArt({super.key, required this.kind});
  final String kind;
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
      _ => (Icons.edit_note, const Color(0xFF548578), 'STATIONERY'),
    };
    final book = ['math', 'physics', 'programming'].contains(kind);
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
