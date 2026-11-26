import 'package:flutter/material.dart';

/// A screen's large left-aligned title with optional lines around it and
/// controls beside it.
class ScreenHeaderWidget extends StatelessWidget {
  final String title;
  final String? overline;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  const ScreenHeaderWidget({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Lines shrink rather than break when text is large or space is short.
    Widget line(String text, TextStyle? style) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, style: style),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) line(overline!, textTheme.bodySmall),
                line(title, textTheme.headlineMedium),
                if (subtitle != null) line(subtitle!, textTheme.bodySmall),
              ],
            ),
          ),
          for (final (index, action) in actions.indexed) ...[
            SizedBox(width: index == 0 ? 8 : 12),
            action,
          ],
        ],
      ),
    );
  }
}
