import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Design tokens meniru referensi (Breaking News / Discover / Detail).
class NewsColors {
  static const Color primary = Color(0xFF1877F2);
  static const Color primaryDark = Color(0xFF0F5FCC);
  static const Color ink = Color(0xFF111214);
  static const Color subtitle = Color(0xFF8E8E93);
  static const Color muted = Color(0xFF9AA0A6);
  static const Color searchBg = Color(0xFFF1F2F4);
  static const Color circleBtnBg = Color(0xFFF5F5F6);
  static const Color cardShadow = Color(0x1A000000);
  static const Color badgeBlue = Color(0xFF1E88FF);

  static const List<Color> avatarPalette = [
    Color(0xFF1877F2),
    Color(0xFF7C4DFF),
    Color(0xFF00BFA5),
    Color(0xFFFF7043),
    Color(0xFFEC407A),
    Color(0xFF5C6BC0),
  ];
}

/// Breakpoint responsif: mobile < 600, tablet 600-1023, desktop >= 1024.
enum AppDevice { mobile, tablet, desktop }

AppDevice deviceForWidth(double width) {
  if (width >= 1024) return AppDevice.desktop;
  if (width >= 600) return AppDevice.tablet;
  return AppDevice.mobile;
}

double contentMaxWidth(double width, {double desktop = 1150}) {
  final device = deviceForWidth(width);
  switch (device) {
    case AppDevice.mobile:
      return double.infinity;
    case AppDevice.tablet:
      return 720;
    case AppDevice.desktop:
      return desktop;
  }
}

int gridColumnsForWidth(double width, {int mobile = 1, int tablet = 2, int desktop = 3}) {
  final device = deviceForWidth(width);
  switch (device) {
    case AppDevice.mobile:
      return mobile;
    case AppDevice.tablet:
      return tablet;
    case AppDevice.desktop:
      return desktop;
  }
}

String relativeTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final now = DateTime.now();
  final diff = now.difference(parsed);
  if (diff.isNegative) return DateFormat('d MMM yyyy', 'id').format(parsed);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return DateFormat('MMM d, yyyy').format(parsed);
}

Color avatarColorFor(String name) {
  if (name.isEmpty) return NewsColors.avatarPalette.first;
  var hash = 0;
  for (var i = 0; i < name.length; i++) {
    hash = (hash * 31 + name.codeUnitAt(i)) & 0x7fffffff;
  }
  return NewsColors.avatarPalette[hash % NewsColors.avatarPalette.length];
}

String initialFor(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return 'N';
  final parts = clean.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
