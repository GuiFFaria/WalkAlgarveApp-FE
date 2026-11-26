import 'package:flutter/material.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

class AppTabBarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppTabBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    const corners = BorderRadius.vertical(top: Radius.circular(24));

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: corners,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: corners,
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              label: translations.explore,
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_border),
              label: translations.favorites,
            ),
            NavigationDestination(
              icon: const Icon(Icons.history),
              label: translations.history,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              label: translations.profile,
            ),
          ],
        ),
      ),
    );
  }
}
