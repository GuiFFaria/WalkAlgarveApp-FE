import 'package:flutter/material.dart';
import 'package:walk_algarve_app/views/components/language_switch/language_switch_widget.dart';

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
    return AppBar(
      centerTitle: true,
      title: Text(title),
      actions: const [
        LanguageSwitchWidget(),
        SizedBox(width: 8),
      ],
    );
  }
}
