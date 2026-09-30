import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A [Image.network] replacement that never lets a broken or slow URL break
/// the screen around it.
///
/// A bare `Image.network` throws when the device is offline or the host returns
/// an error, which surfaces as a red error box mid-layout. This widget shows a
/// spinner while loading and a muted placeholder if the image cannot be
/// fetched, so the surrounding layout keeps its shape either way.
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_not_supported_outlined,
    this.placeholderLabel,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final IconData placeholderIcon;

  /// Optional caption shown under the icon when the image cannot load.
  final String? placeholderLabel;

  Widget _placeholder({Widget? child}) => Container(
    height: height,
    width: width,
    color: AppColors.primaryLight,
    alignment: Alignment.center,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _fallback();
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : _placeholder(
              child: const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => _placeholder(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(placeholderIcon, color: AppColors.primary, size: 28),
        if (placeholderLabel != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              placeholderLabel!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
