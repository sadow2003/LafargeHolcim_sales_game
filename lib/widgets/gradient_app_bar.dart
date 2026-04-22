import 'package:flutter/material.dart';
import '../main.dart'; 


//PreferredSizeWidget tells Flutter that this widget can be used as an appBar
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final List<Widget>? actions;

  const GradientAppBar({
    super.key,
    required this.title,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.actions,
  });

//Tell exacly how tall is the appbar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      // Transparent so the flexibleSpace gradient shows through.
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          // Gradient mirrors the logo: dark navy → cyan → brand green
          gradient: LinearGradient(
            colors: [kPrimaryColor, kCyanColor, kSecondaryColor],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}
