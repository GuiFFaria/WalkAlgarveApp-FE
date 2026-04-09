import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;

  const CustomAppBarWidget({
    Key? key,
    required this.title,
    this.onMenuPressed,
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
      backgroundColor: const Color(0xFF1BA6A1),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1BA6A1),
        statusBarIconBrightness: Brightness.light,
      ),
      elevation: 2,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Builder(
        builder: (innerContext) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: onMenuPressed ?? () => Scaffold.of(innerContext).openDrawer(),
          );
        },
      ),
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
