import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';

/// The PT/EN flags; the active language is drawn larger.
class LanguageSwitchWidget extends StatelessWidget {
  const LanguageSwitchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isPT = Localizations.localeOf(context).languageCode == "pt";

    const double activeSize = 24;
    const double inactiveSize = 18;

    return GestureDetector(
      onTap: () => context.read<LocaleProvider>().toggleLocale(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "assets/images/pt-flag.png",
            height: isPT ? activeSize : inactiveSize,
          ),
          const Text(
            " / ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Image.asset(
            "assets/images/en-flag.png",
            height: !isPT ? activeSize : inactiveSize,
          ),
        ],
      ),
    );
  }
}
