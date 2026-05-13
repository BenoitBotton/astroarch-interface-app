import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';

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
      home: state.api == null ? const LoginScreen() : const ShellScreen(),
    );
  }
}
