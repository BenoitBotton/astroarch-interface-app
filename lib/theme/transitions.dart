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

  /// Teletrasporto Star Trek: fade + maschera a banda luminosa che scorre
  /// verticalmente (materializzazione). Gli stop del gradient restano sempre
  /// non-decrescenti (clamp di una sequenza crescente) → niente errori.
  static Widget _transporter(Widget child, Animation<double> a) {
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, ch) {
        final v = a.value;
        return Opacity(
          opacity: v,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              // banda visibile che "rivela" dall'alto al basso
              final s0 = (v * 1.6 - 0.6).clamp(0.0, 1.0);
              final s1 = (v * 1.6 - 0.3).clamp(0.0, 1.0);
              final s2 = (v * 1.6).clamp(0.0, 1.0);
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.white, Colors.white,
                  Color(0xCCFFFFFF), Color(0x00FFFFFF),
                ],
                stops: [0.0, s0, s1, s2],
              ).createShader(rect);
            },
            child: ch,
          ),
        );
      },
    );
  }

  /// Risucchio Gargantua: l'entrante emerge ingrandendosi e raddrizzandosi;
  /// l'uscente (animation in reverse) si rimpicciolisce e ruota → risucchio.
  static Widget _blackHole(Widget child, Animation<double> a) {
    final curved = CurvedAnimation(parent: a, curve: Curves.easeInOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.82, end: 1.0).animate(curved),
        child: RotationTransition(
          turns: Tween(begin: -0.035, end: 0.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
