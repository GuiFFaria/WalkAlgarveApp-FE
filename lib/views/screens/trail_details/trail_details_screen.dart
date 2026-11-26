import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/info_chip/info_chip_widget.dart';
import 'package:walk_algarve_app/views/components/photo_placeholder/photo_placeholder_widget.dart';
import 'package:walk_algarve_app/views/components/square_icon_button/square_icon_button_widget.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/trail_helper.dart';
import 'package:walk_algarve_app/views/helpers/translations_helper.dart';
import 'package:walk_algarve_app/views/screens/trail_details/trail_fact_tiles.dart';
import 'package:walk_algarve_app/views/screens/trail_map/trail_map_screen.dart';

class TrailDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> trail;

  const TrailDetailsScreen({super.key, required this.trail});

  static const _photoHeight = 300.0;

  /// How far the details panel covers the bottom of the photo.
  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _photoHeight,
            child: _buildPhoto(context),
          ),
          // Only the panel scrolls, so text never runs under the status bar.
          Positioned.fill(
            top: _photoHeight - _overlap,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_overlap),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: _buildDetails(context),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: SquareIconButtonWidget(
                  icon: Icons.chevron_left,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TrailMapScreen(trail: trail)),
            ),
            icon: const Icon(Icons.map_outlined),
            label: Text(translations.view_map),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    final photo = TrailHelper.photo(trail);
    final placeholder = PhotoPlaceholderWidget(
      caption: AppLocalizations.of(context)!.trail_photo,
    );
    if (photo.isEmpty) return placeholder;

    return Image.network(
      photo,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _buildDetails(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final distance = TrailHelper.distance(trail, locale);
    final duration = TrailHelper.duration(trail, locale);
    final type = TrailHelper.type(trail);
    final difficulty = TrailHelper.difficulty(trail, translations);
    final bikeFriendly = TrailHelper.bikeFriendly(trail);

    final facts = [
      if (distance != null) (Icons.route, distance),
      if (duration != null) (Icons.schedule, duration),
      if (type != null)
        (
          TrailHelper.isCircular(trail) ? Icons.loop : Icons.arrow_forward,
          type,
        ),
      if (difficulty != null) (Icons.terrain, difficulty),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.getValue(
            trail,
            locale,
            "name",
            fallback: translations.untitled_trail,
          ),
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 14),
        if (facts.isNotEmpty) ...[
          TrailFactTiles(facts: facts),
          const SizedBox(height: 14),
        ],
        if (bikeFriendly != null) ...[
          InfoChipWidget(
            icon: bikeFriendly ? Icons.pedal_bike : Icons.block,
            label: bikeFriendly
                ? translations.bike_friendly
                : translations.no_bikes,
            background: bikeFriendly
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            foreground: bikeFriendly
                ? colors.onPrimaryContainer
                : colors.onSurface,
          ),
          const SizedBox(height: 14),
        ],
        Text(translations.description, style: theme.textTheme.titleMedium),
        const SizedBox(height: 14),
        Text(
          TranslationHelper.getValue(
            trail,
            locale,
            "description",
            fallback: trail["description"]?.toString() ??
                translations.no_description,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
