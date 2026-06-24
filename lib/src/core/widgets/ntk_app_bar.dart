import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';

String localizeLocationName(BuildContext context, String name) {
  final isTamil = Localizations.localeOf(context).languageCode == 'ta';
  if (name == 'Tamil Nadu' || name == 'தமிழ்நாடு') {
    return isTamil ? 'தமிழ்நாடு' : 'Tamil Nadu';
  }
  return name;
}

class NTKAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final Widget? subtitleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showNotification;
  final PreferredSizeWidget? bottom;

  const NTKAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.actions,
    this.showNotification = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: NTKColors.primary,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: leading ??
          (Scaffold.maybeOf(context)?.hasDrawer ?? false
              ? IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
              : null), // Will fallback to back button if canPop
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitleWidget ??
              Text(
                localizeLocationName(context, subtitle),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ],
      ),
      actions: actions ??
          (showNotification
              ? [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  const SizedBox(width: 8),
                ]
              : null),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
