import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'services/notifications.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/connections_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.loadPrefs();
  // v0.2.44: inizializza le notifiche locali + applica il toggle utente.
  await Notifs.init();
  Notifs.enabled = state.notificationsEnabled;
  await Notifs.requestPermission();
  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const AstroarchApp(),
    ),
  );
}

class AstroarchApp extends StatelessWidget {
  const AstroarchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Astroarch Interface',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forMode(state.themeMode),
      // v0.2.48: scala testo globale regolabile (segnalato da Tucniak: testo
      // piccolo su tablet). Combina la scala di sistema con il moltiplicatore
      // scelto in Settings (default 1.15 → leggermente più grande del base).
      builder: (context, child) {
        final sysScale = MediaQuery.textScalerOf(context);
        Widget content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: sysScale.clamp(
              minScaleFactor: state.textScale,
              maxScaleFactor: state.textScale * 1.6,
            ),
          ),
          child: child ?? const SizedBox(),
        );
        // v0.2.50: tema con foto reale → sfondo GLOBALE (tutte le schermate).
        // Foto + scrim graduato sotto a tutto; gli Scaffold hanno bg
        // trasparente così la foto traspare ovunque, restando leggibile.
        if (state.themeMode.hasPhotoBackground) {
          content = Stack(fit: StackFit.expand, children: [
            Image.asset(AppTheme.ojPhotoAsset, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: AppTheme.ojBg)),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xB3000000), Color(0xCC04060C), Color(0xE604060C)],
              stops: [0.0, 0.45, 1.0],
            ))),
            content,
          ]);
        }
        return content;
      },
      // Avvio:
      //  - già connesso            → ShellScreen
      //  - non connesso + profili salvati → ConnectionsScreen (seleziona un
      //    bridge salvato con un tap, oppure "+" per aggiungerne uno nuovo via
      //    QR/manuale). Niente più QR ad ogni avvio se hai già dei profili.
      //  - non connesso + nessun profilo (primo avvio) → LoginScreen (QR/manuale)
      home: state.api != null
          ? const ShellScreen()
          : (state.bridges.isNotEmpty
              ? const ConnectionsScreen()
              : const LoginScreen()),
    );
  }
}
