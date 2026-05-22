import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/connections_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.loadPrefs();
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
      theme: state.nightMode ? AppTheme.buildNight() : AppTheme.buildPro(),
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
