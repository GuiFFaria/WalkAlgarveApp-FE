import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/photo_placeholder/photo_placeholder_widget.dart';
import 'package:walk_algarve_app/views/components/zone_tags/zone_tags_widget.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/zone_helper.dart';
import 'package:walk_algarve_app/views/screens/zone_details/zone_details_screen.dart';

class ZoneCardWidget extends StatelessWidget {
  final Map<String, dynamic> zone;

  const ZoneCardWidget(this.zone, {super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final theme = Theme.of(context);
    final photo = ZoneHelper.photo(zone);
    final unlocked = ZoneHelper.isUnlocked(zone);
    final placeholder = PhotoPlaceholderWidget(
      icon: unlocked ? Icons.image_outlined : Icons.lock_outline,
      caption: AppLocalizations.of(context)!.zone_photo,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ZoneDetailsScreen(zone: zone)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: unlocked ? 200 : 150,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ZoneHelper.name(zone, locale),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ZoneTagsWidget(zone: zone),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
