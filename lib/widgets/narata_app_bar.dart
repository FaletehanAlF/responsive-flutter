import 'package:flutter/material.dart';

import '../pages/notification_page.dart';
import '../pages/profile_page.dart';

class NarataAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showNotification;
  final bool showProfile;

  const NarataAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.showNotification = true,
    this.showProfile = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: true,
      leading: showBack
          ? (onBack == null
              ? null
              : IconButton(
                  tooltip: 'Kembali',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ))
          : (showNotification
              ? IconButton(
                  tooltip: 'Notifikasi',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () =>
                      _open(context, const NotificationPage()),
                )
              : null),
      title: title,
      actions: [
        if (showBack && showNotification)
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _open(context, const NotificationPage()),
          ),
        if (showProfile)
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => _open(context, const ProfilePage()),
          ),
      ],
    );
  }
}
