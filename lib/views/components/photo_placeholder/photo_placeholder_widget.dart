import 'package:flutter/material.dart';

/// Shown where a zone or trail has no photo, or it cannot be loaded.
class PhotoPlaceholderWidget extends StatelessWidget {
  final IconData icon;
  final String? caption;

  /// A plain dark fill, for places that draw white text over the photo.
  final bool dimmed;

  const PhotoPlaceholderWidget({
    super.key,
    this.icon = Icons.image_outlined,
    this.caption,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dimmed) {
      return const ColoredBox(
        color: Color(0xFF616161),
        child: SizedBox.expand(),
      );
    }

    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(
                caption!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
