import 'package:flutter/material.dart';

/// The row of equally wide tiles that summarises a trail.
class TrailFactTiles extends StatelessWidget {
  final List<(IconData, String)> facts;

  const TrailFactTiles({super.key, required this.facts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tiles stay equally tall when a long value is shrunk to fit.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, (icon, value)) in facts.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        // Measured as one line, or the tiles grow too tall.
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
