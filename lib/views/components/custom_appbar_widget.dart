import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;

  const CustomAppBarWidget({
    Key? key,
    required this.title,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode.toUpperCase();

    return AppBar(
      backgroundColor: const Color(0xFF1BA6A1),
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
        // 🔄 Botão de troca de idioma
        TextButton(
          onPressed: () => context.read<LocaleProvider>().toggleLocale(),
          child: Text(
            currentLocale,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
