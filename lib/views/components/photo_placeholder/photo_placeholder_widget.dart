import 'package:flutter/material.dart';

/// Shown where a zone or trail has no photo, or it cannot be loaded.
class PhotoPlaceholderWidget extends StatelessWidget {
  /// Darkens the picture so white text drawn over it stays readable.
  final bool dimmed;

  const PhotoPlaceholderWidget({super.key, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    // Shown whole so its caption is not cut off, on its own background color.
    final picture = ColoredBox(
      color: const Color(0xFFF2F2F2),
      child: Image.asset(
        'assets/images/default.jpg',
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
    if (!dimmed) return picture;

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0x99000000), BlendMode.srcATop),
      child: picture,
    );
  }
}
