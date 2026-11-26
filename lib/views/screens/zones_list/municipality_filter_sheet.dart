import 'package:flutter/material.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

/// Asks which municipality to show. [onSelected] receives null for all of them;
/// it is not called when the sheet is closed without a choice.
Future<void> showMunicipalityFilterSheet(
  BuildContext context, {
  required List<String> municipalities,
  required String? selected,
  required ValueChanged<String?> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final translations = AppLocalizations.of(sheetContext)!;
      final theme = Theme.of(sheetContext);
      final colors = theme.colorScheme;

      Widget option(String label, String? value) => ListTile(
            title: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            selected: selected == value,
            trailing: selected == value
                ? Icon(Icons.check, color: colors.primary)
                : null,
            onTap: () {
              Navigator.pop(sheetContext);
              onSelected(value);
            },
          );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                translations.select_municipality,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: Material(
                  color: colors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: colors.outlineVariant),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      option(translations.show_all, null),
                      for (final municipality in municipalities) ...[
                        const Divider(height: 1),
                        option(municipality, municipality),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                ),
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(translations.close),
              ),
            ],
          ),
        ),
      );
    },
  );
}
