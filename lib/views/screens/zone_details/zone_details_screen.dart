import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/photo_placeholder/photo_placeholder_widget.dart';
import 'package:walk_algarve_app/views/components/square_icon_button/square_icon_button_widget.dart';
import 'package:walk_algarve_app/views/components/zone_tags/zone_tags_widget.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/zone_helper.dart';
import 'package:walk_algarve_app/views/screens/trails_list/trails_list_screen.dart';

class ZoneDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> zone;

  const ZoneDetailsScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 320, child: _buildPhoto(context)),
              // Only the text scrolls, so it never runs under the status bar.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ZoneHelper.name(zone, locale),
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      ZoneTagsWidget(zone: zone),
                      const SizedBox(height: 22),
                      Text(
                        translations.aboutZone,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        ZoneHelper.description(
                          zone,
                          locale,
                          fallback: translations.no_description,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: SquareIconButtonWidget(
                icon: Icons.chevron_left,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: _buildAction(context),
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    final photo = ZoneHelper.photo(zone);
    final placeholder = PhotoPlaceholderWidget(
      icon: ZoneHelper.isUnlocked(zone)
          ? Icons.image_outlined
          : Icons.lock_outline,
      caption: AppLocalizations.of(context)!.zone_photo,
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

  Widget _buildAction(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    if (ZoneHelper.isUnlocked(zone)) {
      return FilledButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrailsListScreen(zone: zone),
          ),
        ),
        child: Text(translations.viewTrails),
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: colors.secondary,
        foregroundColor: colors.onSecondary,
      ),
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translations.redirecting_purchase),
          duration: const Duration(seconds: 2),
        ),
      ),
      icon: const Icon(Icons.lock_outline),
      label: Text(translations.unlockZone),
    );
  }
}
