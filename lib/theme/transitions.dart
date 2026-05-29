import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Transizioni a tema per il cambio di tab/pagina (v0.2.46).
///
/// - starTrek     : "teletrasporto" — dissolve a bande luminose verticali
///                  (ShaderMask) + fade. Effetto materializzazione.
/// - interstellar : "risucchio Gargantua" — scale + rotazione + fade.
///                  L'uscente si rimpicciolisce/ruota verso il centro.
/// - deepSpace    : fade morbido.
/// - pro / night  : nessuna transizione (cambio istantaneo, massima reattività
///                  per l'uso operativo).
///
/// Durata breve (~450ms) per non rallentare la navigazione notturna.
class ThemedTransitions {
  static Duration durationFor(AppThemeMode m) => switch (m) {
        AppThemeMode.starTrek => const Duration(milliseconds: 480),
        AppThemeMode.interstellar => const Duration(milliseconds: 520),
        AppThemeMode.deepSpace => const Duration(milliseconds: 300),
        _ => Duration.zero, // pro/night: istantaneo
      };

  /// transitionBuilder per AnimatedSwitcher.
  static Widget build(
      AppThemeMode mode, Widget child, Animation<double> animation) {
    switch (mode) {
      case AppThemeMode.starTrek:
        return _transporter(child, animation);
      case AppThemeMode.interstellar:
        return _blackHole(child, animation);
      case AppThemeMode.deepSpace:
        return FadeTransition(opacity: animation, child: child);
      default:
        return child; // nessun effetto
    }
  }

  /// Teletrasporto Star Trek: fade + maschera a banda luminosa verticale
  /// (materializzazione) + SCIAME DI PARTICELLE dorate che sfavillano durante
  /// la transizione. Gli stop del gradient restano non-decrescenti (clamp di
  /// una sequenza crescente) → niente errori.
  static Widget _transporter(Widget child, Animation<double> a) {
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, ch) {
        final v = a.value;
        return Stack(fit: StackFit.expand, children: [
          Opacity(
            opacity: v,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) {
                final s0 = (v * 1.6 - 0.6).clamp(0.0, 1.0);
                final s1 = (v * 1.6 - 0.3).clamp(0.0, 1.0);
                final s2 = (v * 1.6).clamp(0.0, 1.0);
                return LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: const [
                    Colors.white, Colors.white,
                    Color(0xCCFFFFFF), Color(0x00FFFFFF),
                  ],
                  stops: [0.0, s0, s1, s2],
                ).createShader(rect);
              },
              child: ch,
            ),
          ),
          // particelle dorate: intense a metà transizione, svaniscono a fine
          IgnorePointer(child: CustomPaint(painter: _TransporterParticles(v))),
        ]);
      },
    );
  }

  /// Risucchio Gargantua: l'entrante emerge ingrandendosi e raddrizzandosi;
  /// l'uscente (animation in reverse) si rimpicciolisce e ruota → risucchio.
  /// Più intenso della v0.2.46: scala più ampia + rotazione marcata.
  static Widget _blackHole(Widget child, Animation<double> a) {
    final curved = CurvedAnimation(parent: a, curve: Curves.easeInOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.65, end: 1.0).animate(curved),
        child: RotationTransition(
          turns: Tween(begin: -0.08, end: 0.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

/// Particelle dorate del teletrasporto. Deterministiche (seed fisso). La
/// luminosità segue una campana centrata a metà transizione (v=0.5).
class _TransporterParticles extends CustomPainter {
  final double v; // 0..1
  _TransporterParticles(this.v);

  static final List<_P> _ps = _gen();
  static List<_P> _gen() {
    final r = math.Random(70707);
    return List.generate(60, (_) => _P(
      r.nextDouble(), r.nextDouble(),
      r.nextDouble() * 1.6 + 0.6,
      r.nextDouble(),
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // intensità a campana: 0 ai bordi, max a metà transizione
    final intensity = math.sin(v * math.pi); // 0→1→0
    if (intensity < 0.02) return;
    for (final p in _ps) {
      // le particelle "salgono" leggermente e sfarfallano
      final phase = (v * 2 + p.seed) % 1.0;
      final flick = 0.4 + 0.6 * math.sin((v * 8 + p.seed * 6) * math.pi).abs();
      final y = (p.y - phase * 0.15) % 1.0;
      final a = (intensity * flick * 0.9).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFFFFD27F).withValues(alpha: a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(
          Offset(p.x * size.width, y * size.height), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TransporterParticles old) => old.v != v;
}

class _P {
  final double x, y, r, seed;
  const _P(this.x, this.y, this.r, this.seed);
}
