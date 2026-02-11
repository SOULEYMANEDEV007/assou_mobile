import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue.shade400,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
