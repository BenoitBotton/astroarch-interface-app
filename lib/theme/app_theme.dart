import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// I temi dell'app:
///  - pro          : ambra/blu, default operativo, alta leggibilità
///  - night        : red-light, NON disturba l'adattamento al buio degli occhi
///  - deepSpace    : blu/viola nebulosa, con campo stellato a tema astronomia
///  - interstellar : sobrio cinematografico, blu-ghiaccio, font Exo 2, animato*
///  - starTrek     : console LCARS, pannelli arancio/viola, font Oswald, animato*
/// (* temi "scenici": animazioni → maggior consumo batteria/CPU)
enum AppThemeMode { pro, night, deepSpace, interstellar, starTrek }

extension AppThemeModeX on AppThemeMode {
  String get id => switch (this) {
        AppThemeMode.pro => 'pro',
        AppThemeMode.night => 'night',
        AppThemeMode.deepSpace => 'deep_space',
        AppThemeMode.interstellar => 'interstellar',
        AppThemeMode.starTrek => 'star_trek',
      };
  static AppThemeMode fromId(String? s) => switch (s) {
        'night' => AppThemeMode.night,
        'deep_space' => AppThemeMode.deepSpace,
        'interstellar' => AppThemeMode.interstellar,
        'star_trek' => AppThemeMode.starTrek,
        _ => AppThemeMode.pro,
      };
  /// Temi "scenici" con animazioni (consumo maggiore).
  bool get isScenic => this == AppThemeMode.deepSpace ||
      this == AppThemeMode.interstellar || this == AppThemeMode.starTrek;
  /// Animazioni marcate (interstellar/starTrek). DeepSpace è statico.
  bool get isAnimated => this == AppThemeMode.interstellar ||
      this == AppThemeMode.starTrek;
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

  // Colori Interstellar (sobrio, cinematografico: blu-ghiaccio + ambra)
  static const Color isBg = Color(0xFF02040A);
  static const Color isPanel = Color(0xFF0A0F18);
  static const Color isPanel2 = Color(0xFF111824);
  static const Color isLine = Color(0xFF1E2A3A);
  static const Color isText = Color(0xFFDCE6F0);
  static const Color isMuted = Color(0xFF6E7E92);
  static const Color isAccent = Color(0xFF9FC3E0);   // blu ghiaccio
  static const Color isAccent2 = Color(0xFFE0A85C);  // ambra (Endurance)
  static const Color isOk = Color(0xFF7FD0C0);
  static const Color isErr = Color(0xFFE06B6B);

  // Colori Star Trek / LCARS (pannelli arancio/viola/azzurro su nero)
  static const Color stBg = Color(0xFF000000);
  static const Color stPanel = Color(0xFF1A1326);
  static const Color stPanel2 = Color(0xFF241A33);
  static const Color stLine = Color(0xFF3A2A4E);
  static const Color stText = Color(0xFFFFF0D8);
  static const Color stMuted = Color(0xFF9C88C0);
  static const Color stAccent = Color(0xFFFF9C00);   // LCARS orange
  static const Color stAccent2 = Color(0xFF9C9CFF);  // LCARS periwinkle
  static const Color stOk = Color(0xFFCC99CC);
  static const Color stErr = Color(0xFFFF5555);

  /// Ritorna il ThemeData per il modo richiesto.
  static ThemeData forMode(AppThemeMode m) => switch (m) {
        AppThemeMode.night => buildNight(),
        AppThemeMode.deepSpace => buildDeepSpace(),
        AppThemeMode.interstellar => buildInterstellar(),
        AppThemeMode.starTrek => buildStarTrek(),
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

  // Font tematici (Google Fonts, licenza Open Font — fetch+cache a runtime).
  static TextTheme _interstellarFont(TextTheme base) =>
      GoogleFonts.exo2TextTheme(base);
  static TextTheme _starTrekFont(TextTheme base) =>
      GoogleFonts.oswaldTextTheme(base);

  static ThemeData buildInterstellar() => _build(
        bg: isBg, panel: isPanel, panel2: isPanel2, line: isLine,
        text: isText, muted: isMuted, accent: isAccent, accent2: isAccent2,
        ok: isOk, err: isErr, fontBuilder: _interstellarFont,
      );

  static ThemeData buildStarTrek() => _build(
        bg: stBg, panel: stPanel, panel2: stPanel2, line: stLine,
        text: stText, muted: stMuted, accent: stAccent, accent2: stAccent2,
        ok: stOk, err: stErr, fontBuilder: _starTrekFont,
        cardRadius: 18, // pannelli LCARS più arrotondati
      );

  static ThemeData _build({
    required Color bg, required Color panel, required Color panel2,
    required Color line, required Color text, required Color muted,
    required Color accent, required Color accent2,
    required Color ok, required Color err,
    TextTheme Function(TextTheme)? fontBuilder,
    double cardRadius = 14,
  }) {
    final base = ThemeData.dark(useMaterial3: true);
    // Font tematico (se fornito) applicato al textTheme, con fallback sicuro.
    TextTheme themedText = base.textTheme;
    if (fontBuilder != null) {
      try { themedText = fontBuilder(base.textTheme); } catch (_) {}
    }
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
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: line,
      textTheme: themedText.apply(bodyColor: text, displayColor: text),
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

/// Sfondo a tema dietro al contenuto. Stile e animazione dipendono dal
/// tema attivo:
///  - deepSpace    : campo stellato + nebulosa, STATICO (no batteria extra)
///  - interstellar : stelle in drift lento + aloni che pulsano (animato)
///  - starTrek     : scan-line LCARS che scorre + stelle (animato)
///  - altri temi   : trasparente (no-op)
/// Deterministico (seed fisso) → niente sfarfallio. Animazione solo per i
/// temi scenici animati.
class StarfieldBackground extends StatefulWidget {
  final Widget child;
  final AppThemeMode mode;
  const StarfieldBackground({super.key, required this.child, required this.mode});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    _setupAnim();
  }

  void _setupAnim() {
    _ctrl?.dispose();
    _ctrl = null;
    if (widget.mode.isAnimated) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 18), // lento → poco consumo
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(StarfieldBackground old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) _setupAnim();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.mode.isScenic) return widget.child;
    if (_ctrl == null) {
      // statico (deepSpace)
      return Stack(children: [
        Positioned.fill(child: IgnorePointer(
            child: CustomPaint(painter: _StarfieldPainter(widget.mode, 0)))),
        widget.child,
      ]);
    }
    return Stack(children: [
      Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(
        animation: _ctrl!,
        builder: (_, __) => CustomPaint(
            painter: _StarfieldPainter(widget.mode, _ctrl!.value)),
      ))),
      widget.child,
    ]);
  }
}

class _StarfieldPainter extends CustomPainter {
  final AppThemeMode mode;
  final double t; // 0..1 fase animazione
  _StarfieldPainter(this.mode, this.t);

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
    switch (mode) {
      case AppThemeMode.deepSpace:
        _paintNebula(canvas, size, const Color(0x228B7CFF), const Color(0x1842E8E0));
        _paintStars(canvas, size, 0);
        break;
      case AppThemeMode.interstellar:
        // drift orizzontale lento + aloni pulsanti blu-ghiaccio/ambra
        final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
        _paintNebula(canvas, size,
            Color.fromRGBO(159, 195, 224, 0.10 + 0.05 * pulse),
            Color.fromRGBO(224, 168, 92, 0.06 + 0.04 * (1 - pulse)));
        _paintStars(canvas, size, t * 0.04); // drift molto lento
        break;
      case AppThemeMode.starTrek:
        // sfondo nero + qualche stella + scan-line LCARS arancione
        _paintStars(canvas, size, 0);
        final y = (t * size.height) % size.height;
        final scan = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: const [Color(0x00FF9C00), Color(0x33FF9C00), Color(0x00FF9C00)],
          ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80));
        canvas.drawRect(Rect.fromLTWH(0, y - 40, size.width, 80), scan);
        break;
      default:
        break;
    }
  }

  void _paintNebula(Canvas canvas, Size size, Color c1, Color c2) {
    final p1 = Paint()..shader = RadialGradient(colors: [c1, const Color(0x00000000)])
        .createShader(Rect.fromCircle(
            center: Offset(size.width * 0.25, size.height * 0.28),
            radius: size.width * 0.5));
    canvas.drawRect(Offset.zero & size, p1);
    final p2 = Paint()..shader = RadialGradient(colors: [c2, const Color(0x00000000)])
        .createShader(Rect.fromCircle(
            center: Offset(size.width * 0.8, size.height * 0.7),
            radius: size.width * 0.45));
    canvas.drawRect(Offset.zero & size, p2);
  }

  void _paintStars(Canvas canvas, Size size, double driftX) {
    for (final s in _stars) {
      final x = ((s.x + driftX) % 1.0) * size.width;
      final p = Paint()..color = Colors.white.withValues(alpha: s.alpha);
      canvas.drawCircle(Offset(x, s.y * size.height), s.r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) =>
      old.t != t || old.mode != mode;
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
