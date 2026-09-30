import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Blue hero banner with the AI robot, used at the top of the AI screens.
///
/// The robot is never hidden. On a wide screen it sits beside the copy; on a
/// phone it moves above the copy instead, which keeps the artwork visible
/// without squeezing the heading into a column of single words.
class AiHeroBanner extends StatelessWidget {
  const AiHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.image = 'assets/images/ai_bot.png',
  });

  final String title;
  final String subtitle;
  final String image;

  /// Below this width the robot stacks above the copy instead of beside it.
  static const stackBelowWidth = 420.0;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < stackBelowWidth;
        final copy = Column(
          crossAxisAlignment: stacked
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: stacked ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: stacked ? 21 : 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: stacked ? TextAlign.center : TextAlign.start,
              style: const TextStyle(color: Colors.white, height: 1.45),
            ),
          ],
        );
        final robot = Image.asset(
          image,
          width: stacked ? 92 : 96,
          height: stacked ? 92 : 96,
          fit: BoxFit.contain,
          // A missing asset must not break the banner.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [robot, const SizedBox(height: 12), copy],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: copy),
            const SizedBox(width: 12),
            robot,
          ],
        );
      },
    ),
  );
}
