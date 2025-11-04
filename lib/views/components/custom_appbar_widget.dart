import 'package:flutter/material.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onFilterPressed;

  const CustomAppBarWidget({
    Key? key,
    required this.title,
    this.onMenuPressed,
    this.onFilterPressed,
  });

  // Altura padrão da AppBar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:Color(0xFF1BA6A1),
      elevation: 2,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Usamos Builder para garantir que o context aqui tem acesso ao Scaffold
      leading: Builder(
        builder: (innerContext) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: onMenuPressed ??
                () {
                  // Abre o drawer do Scaffold pai
                  Scaffold.of(innerContext).openDrawer();
                },
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
          onPressed: onFilterPressed ?? () {},
        ),
      ],
      // Garantir ícones escuros no tema claro
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }
}
