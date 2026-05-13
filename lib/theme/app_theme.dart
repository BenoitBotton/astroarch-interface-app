import 'package:flutter/material.dart';

/// Theme dell'app - Pro (ambra) o Notte (rosso) per non disturbare l'adattamento al buio.
class AppTheme {
  // Colori Pro
  static const Color proBg = Color(0xFF0A0D12);
  static const Color proPanel = Color(0xFF121821);
  static const Color proPanel2 = Color(0xFF1A212D);
  static const Color proLine = Color(0xFF222B3A);
  static const Color proText = Color(0xFFE6EAF2);
  static const Color proMuted = Color(0xFF8A93A6);
  static const Color proAccent = Color(0xFFF5A623);
  static const Color proAccent2 = Color(0xFF5FB7FF);
  static const Color proOk = Color(0xFF3ED598);
  static const Color proWarn = Color(0xFFFFB454);
  static const Color proErr = Color(0xFFFF5B6E);

  // Colori Night (red light)
  static const Color nightBg = Color(0xFF080404);
  static const Color nightPanel = Color(0xFF160808);
  static const Color nightPanel2 = Color(0xFF1F0A0A);
  static const Color nightLine = Color(0xFF3A1414);
  static const Color nightText = Color(0xFFFFB0B0);
  static const Color nightMuted = Color(0xFFA05858);
  static const Color nightAccent = Color(0xFFFF3B3B);
  static const Color nightAccent2 = Color(0xFFFF6B6B);
  static const Color nightOk = Color(0xFFFF8A8A);
  static const Color nightErr = Color(0xFFFF5B5B);

  static ThemeData buildPro() => _build(
        bg: proBg, panel: proPanel, panel2: proPanel2, line: proLine,
        text: proText, muted: proMuted, accent: proAccent, accent2: proAccent2,
        ok: proOk, err: proErr,
      );

  static ThemeData buildNight() => _build(
        bg: nightBg, panel: nightPanel, panel2: nightPanel2, line: nightLine,
        text: nightText, muted: nightMuted, accent: nightAccent, accent2: nightAccent2,
        ok: nightOk, err: nightErr,
      );

  static ThemeData _build({
    required Color bg, required Color panel, required Color panel2,
    required Color line, required Color text, required Color muted,
    required Color accent, required Color accent2,
    required Color ok, required Color err,
  }) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        surface: bg,
        primary: accent,
        secondary: accent2,
        error: err,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
      ).copyWith(
        surfaceContainerHighest: panel,
        surfaceContainer: panel,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: text, fontWeight: FontWeight.w600, fontSize: 17,
        ),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: line),
          borderRadius: BorderRadius.circular(14),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: line,
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent),
        ),
        labelStyle: TextStyle(color: muted, fontSize: 12, letterSpacing: 1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: line),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: muted, size: 22)),
        height: 64,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: panel),
      listTileTheme: ListTileThemeData(textColor: text, iconColor: muted),
      iconTheme: IconThemeData(color: muted),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panel2,
        contentTextStyle: TextStyle(color: text),
        actionTextColor: accent,
      ),
    );
  }
}

/// Token semantici accessibili in tutta l'app.
class T {
  static Color text(BuildContext c) => Theme.of(c).colorScheme.onSurface;
  static Color muted(BuildContext c) =>
      Theme.of(c).inputDecorationTheme.labelStyle?.color ?? Colors.grey;
  static Color panel(BuildContext c) => Theme.of(c).colorScheme.surfaceContainer;
  static Color line(BuildContext c) => Theme.of(c).dividerColor;
  static Color accent(BuildContext c) => Theme.of(c).colorScheme.primary;
  static Color accent2(BuildContext c) => Theme.of(c).colorScheme.secondary;
  static Color ok(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? const Color(0xFF3ED598) : const Color(0xFF1F8B62);
  static Color err(BuildContext c) => Theme.of(c).colorScheme.error;
  static Color warn(BuildContext c) => const Color(0xFFFFB454);
}
