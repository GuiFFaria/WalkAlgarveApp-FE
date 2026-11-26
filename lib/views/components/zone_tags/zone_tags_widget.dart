import 'package:flutter/material.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/info_chip/info_chip_widget.dart';
import 'package:walk_algarve_app/views/helpers/zone_helper.dart';

/// A zone's municipality and whether the user owns it.
class ZoneTagsWidget extends StatelessWidget {
  final Map<String, dynamic> zone;

  const ZoneTagsWidget({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final municipality = ZoneHelper.municipality(zone);
    final unlocked = ZoneHelper.isUnlocked(zone);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (municipality.isNotEmpty)
          InfoChipWidget(
            icon: Icons.place_outlined,
            label: municipality,
            background: colors.surfaceContainerHighest,
            foreground: colors.onSurface,
          ),
        InfoChipWidget(
          icon: unlocked ? Icons.check : Icons.lock_outline,
          label: unlocked
              ? translations.zone_unlocked
              : translations.zone_locked,
          background:
              unlocked ? colors.tertiaryContainer : colors.secondaryContainer,
          foreground: unlocked
              ? colors.onTertiaryContainer
              : colors.onSecondaryContainer,
        ),
      ],
    );
  }
}
