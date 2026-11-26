import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBarWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final bool isPT = locale == "pt";

    const double activeSize = 24;
    const double inactiveSize = 18;

    return AppBar(
      centerTitle: true,
      title: Text(title),
      actions: [
        GestureDetector(
          onTap: () => context.read<LocaleProvider>().toggleLocale(),
          child: Row(
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
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
