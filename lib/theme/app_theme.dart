import 'dart:math' as math;
import 'package:flutter/material.dart';

/// I tre temi dell'app:
///  - pro       : ambra/blu, default operativo, alta leggibilità
///  - night     : red-light, NON disturba l'adattamento al buio degli occhi
///  - deepSpace : blu/viola nebulosa, con campo stellato a tema astronomia
enum AppThemeMode { pro, night, deepSpace }

extension AppThemeModeX on AppThemeMode {
  String get id => switch (this) {
        AppThemeMode.pro => 'pro',
        AppThemeMode.night => 'night',
        AppThemeMode.deepSpace => 'deep_space',
      };
  static AppThemeMode fromId(String? s) => switch (s) {
        'night' => AppThemeMode.night,
        'deep_space' => AppThemeMode.deepSpace,
        _ => AppThemeMode.pro,
      };
}

/// Theme dell'app - Pro (ambra), Notte (rosso), Deep Space (nebulosa).
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

  // Colori Deep Space (nebulosa: blu profondo, accenti viola/ciano)
  static const Color dsBg = Color(0xFF05060F);
  static const Color dsPanel = Color(0xFF0C1024);
  static const Color dsPanel2 = Color(0xFF141A38);
  static const Color dsLine = Color(0xFF26305C);
  static const Color dsText = Color(0xFFE8ECFF);
  static const Color dsMuted = Color(0xFF8A93C0);
  static const Color dsAccent = Color(0xFF8B7CFF);   // viola nebulosa
  static const Color dsAccent2 = Color(0xFF42E8E0);  // ciano
  static const Color dsOk = Color(0xFF3EE0A0);
  static const Color dsErr = Color(0xFFFF5B7E);

  /// Ritorna il ThemeData per il modo richiesto.
  static ThemeData forMode(AppThemeMode m) => switch (m) {
        AppThemeMode.night => buildNight(),
        AppThemeMode.deepSpace => buildDeepSpace(),
        AppThemeMode.pro => buildPro(),
      };

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

  static ThemeData buildDeepSpace() => _build(
        bg: dsBg, panel: dsPanel, panel2: dsPanel2, line: dsLine,
        text: dsText, muted: dsMuted, accent: dsAccent, accent2: dsAccent2,
        ok: dsOk, err: dsErr,
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

/// Sfondo campo stellato per il tema Deep Space.
/// Dipinge stelle + un alone di nebulosa molto sottili dietro al contenuto.
/// Deterministico (seed fisso) → non "sfarfalla" ad ogni rebuild.
/// In tema non-deepSpace è completamente trasparente (no-op visivo).
class StarfieldBackground extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const StarfieldBackground({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Stack(children: [
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _StarfieldPainter()),
        ),
      ),
      child,
    ]);
  }
}

class _StarfieldPainter extends CustomPainter {
  // seed fisso → posizioni stabili tra repaint
  static final List<_Star> _stars = _gen();
  static List<_Star> _gen() {
    final r = math.Random(20260527);
    return List.generate(140, (_) => _Star(
      r.nextDouble(), r.nextDouble(),
      r.nextDouble() * 1.3 + 0.3,
      r.nextDouble() * 0.6 + 0.2,
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Aloni di nebulosa (2 macchie morbide viola/ciano molto tenui)
    final neb1 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0x228B7CFF), const Color(0x00000000),
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.25, size.height * 0.28),
          radius: size.width * 0.5));
    canvas.drawRect(Offset.zero & size, neb1);
    final neb2 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0x1842E8E0), const Color(0x00000000),
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.7),
          radius: size.width * 0.45));
    canvas.drawRect(Offset.zero & size, neb2);
    // Stelle
    for (final s in _stars) {
      final p = Paint()..color = Colors.white.withValues(alpha: s.alpha);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => false;
}

class _Star {
  final double x, y, r, alpha;
  const _Star(this.x, this.y, this.r, this.alpha);
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
