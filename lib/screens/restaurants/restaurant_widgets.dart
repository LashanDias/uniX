import 'dart:convert';
import 'package:flutter/material.dart';

const foodAccent = Color(0xFFB64E23);
const foodInk = Color(0xFF233A32);
const foodCanvas = Color(0xFFFAF8F4);

class RestaurantPhoto extends StatelessWidget {
  const RestaurantPhoto({super.key, this.photoBase64 = '', this.height = 180});
  final String photoBase64;
  final double height;

  @override
  Widget build(BuildContext context) {
    ImageProvider image = const AssetImage(
      'assets/images/sri_lankan_restaurant.png',
    );
    var illustrative = true;
    if (photoBase64.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photoBase64));
        illustrative = false;
      } catch (_) {
        /* Keep the labelled illustration if a saved photo is invalid. */
      }
    }
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: image,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFFE8EDE3),
              child: Center(
                child: Icon(Icons.restaurant, size: 44, color: foodInk),
              ),
            ),
          ),
          if (illustrative)
            Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  child: Text(
                    'Illustration',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FoodNotice extends StatelessWidget {
  const FoodNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0DD),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: foodAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, height: 1.5, color: foodInk),
          ),
        ),
      ],
    ),
  );
}
