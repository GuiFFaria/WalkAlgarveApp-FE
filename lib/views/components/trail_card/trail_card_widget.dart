import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/info_chip/info_chip_widget.dart';
import 'package:walk_algarve_app/views/components/photo_placeholder/photo_placeholder_widget.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/trail_helper.dart';
import 'package:walk_algarve_app/views/helpers/translations_helper.dart';
import 'package:walk_algarve_app/views/screens/trail_details/trail_details_screen.dart';

class TrailCardWidget extends StatelessWidget {
  final Map<String, dynamic> trail;
  final VoidCallback? onFavoritePressed;

  const TrailCardWidget(
    this.trail, {
    super.key,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final isFavorite = TrailHelper.isFavorite(trail);
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final title = TranslationHelper.getValue(
      trail,
      locale,
      "name",
      fallback: translations.untitled_trail,
    );
    final photo = TrailHelper.photo(trail);
    final placeholder =
        PhotoPlaceholderWidget(caption: translations.trail_photo);
    final difficulty = TrailHelper.difficulty(trail, translations);
    final facts = [
      TrailHelper.distance(trail, locale),
      TrailHelper.duration(trail, locale),
      TrailHelper.type(trail),
    ].nonNulls;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrailDetailsScreen(trail: trail),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 220,
                  child: photo.isEmpty
                      ? placeholder
                      : CachedNetworkImage(
                          imageUrl: photo,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => placeholder,
                        ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final fact in facts)
                            InfoChipWidget(
                              label: fact,
                              background: colors.surfaceContainerHighest,
                              foreground: colors.onSurface,
                            ),
                          if (difficulty != null)
                            InfoChipWidget(
                              label: difficulty,
                              background: colors.primaryContainer,
                              foreground: colors.onPrimaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              tooltip: isFavorite
                  ? translations.favorite_remove
                  : translations.favorite_add,
              onPressed: onFavoritePressed,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: isFavorite ? colors.error : colors.onSurface,
                fixedSize: const Size(44, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
