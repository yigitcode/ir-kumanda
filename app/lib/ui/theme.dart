import 'package:flutter/material.dart';

abstract final class RemoteColors {
  static const background = Color(0xFF0D1015);
  static const surface = Color(0xFF151920);
  static const key = Color(0xFF222832);
  static const keyBorder = Color(0xFF2D3440);
  static const text = Color(0xFFE8EBF0);
  static const muted = Color(0xFF8B94A3);
  static const accent = Color(0xFF4C8DFF);
  static const power = Color(0xFFE5484D);
  static const warning = Color(0xFFF5B547);

  static const netflix = Color(0xFFE50914);
  static const youtube = Color(0xFFFF3B30);
  static const primeVideo = Color(0xFF1FA3E0);

  static const red = Color(0xFFE5484D);
  static const green = Color(0xFF30A46C);
  static const yellow = Color(0xFFF2C230);
  static const blue = Color(0xFF3E7BFA);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: RemoteColors.accent,
    brightness: Brightness.dark,
  ).copyWith(surface: RemoteColors.surface, primary: RemoteColors.accent);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: RemoteColors.background,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: RemoteColors.surface,
      indicatorColor: RemoteColors.accent.withValues(alpha: 0.22),
      height: 68,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, color: RemoteColors.text)),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? RemoteColors.text : RemoteColors.muted,
        ),
      ),
    ),
  );
}
