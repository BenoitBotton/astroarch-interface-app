import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'notifications.dart';

/// Widget invisibile montato nella shell. Ogni 4s legge lo stato (poll
/// ekos_status + phd2Live + messaggi INDI da AppState) e, confrontandolo
/// con lo stato precedente, genera notifiche locali sulle TRANSIZIONI:
///  - sequenza completata
///  - star lost durante guiding
///  - guiding interrotto inatteso durante una sequenza
///  - nuovo errore INDI
///
/// Tutta la logica è nel Timer (mai in build) → niente side-effect di
/// rendering. Read-only su AppState, nessun comando inviato.
class NotificationWatcher extends StatefulWidget {
  const NotificationWatcher({super.key});
  @override
  State<NotificationWatcher> createState() => _NotificationWatcherState();
}

class _NotificationWatcherState extends State<NotificationWatcher> {
  Timer? _timer;

  // stato precedente per il rilevamento transizioni
  int? _lastDone;
  int? _lastTotal;
  bool _seqWasRunning = false;
  bool _lastStarLost = false;
  String _lastAppState = '';
  int _lastMsgCount = 0;
  bool _primed = false; // primo giro: solo snapshot, niente notifiche

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted) return;
    final s = context.read<AppState>();
    if (s.api == null) return;

    // --- Capture: poll ekos_status ---
    int done = -1, total = -1, activeJob = -1;
    try {
      final st = await s.api!.captureEkosStatus();
      done = (st['job_image_progress'] as num?)?.toInt() ?? -1;
      total = (st['job_image_count'] as num?)?.toInt() ?? -1;
      activeJob = (st['active_job_id'] as num?)?.toInt() ?? -1;
    } catch (_) {}

    // --- PHD2 live (da AppState) ---
    final live = s.phd2Live;
    final starLost = live['star_lost'] == true;
    final appState = live['app_state']?.toString() ?? '';

    // --- Messaggi INDI ---
    final msgs = s.messages;

    if (!_primed) {
      // primo giro: salva lo snapshot senza notificare (evita raffica all'avvio)
      _lastDone = done; _lastTotal = total;
      _seqWasRunning = activeJob >= 0;
      _lastStarLost = starLost; _lastAppState = appState;
      _lastMsgCount = msgs.length;
      _primed = true;
      return;
    }

    // 1) Sequenza completata: era in corso, ora non più, e i frame fatti
    //    coincidono col totale (o quasi). Notifica una volta.
    final seqRunning = activeJob >= 0;
    if (_seqWasRunning && !seqRunning && (_lastDone ?? 0) > 0) {
      final d = _lastDone ?? 0, t = _lastTotal ?? 0;
      Notifs.show(Notifs.idSequence, 'Sequenza completata',
          t > 0 ? 'Acquisiti $d/$t frame.' : 'Acquisiti $d frame.');
    }
    // anche: done raggiunge total mentre ancora attivo
    else if (seqRunning && total > 0 && done >= total &&
             (_lastDone ?? 0) < total) {
      Notifs.show(Notifs.idSequence, 'Sequenza completata',
          'Acquisiti $done/$total frame.');
    }

    // 2) Star lost durante guiding (transizione false→true)
    if (starLost && !_lastStarLost &&
        (appState == 'Guiding' || _lastAppState == 'Guiding')) {
      Notifs.show(Notifs.idStarLost, 'Stella di guida persa!',
          'PHD2 ha perso la stella. Controlla la guida.');
    }

    // 3) Guiding interrotto inatteso durante una sequenza
    if (_lastAppState == 'Guiding' && appState != 'Guiding' &&
        appState.isNotEmpty && seqRunning) {
      Notifs.show(Notifs.idGuiding, 'Guida interrotta',
          'PHD2 non sta più guidando ($appState) durante la sequenza.');
    }

    // 4) Nuovi messaggi INDI di errore
    if (msgs.length > _lastMsgCount) {
      final fresh = msgs.skip(_lastMsgCount);
      for (final m in fresh) {
        final txt = (m['message']?.toString() ?? m.toString());
        if (txt.toUpperCase().contains('ERROR') ||
            txt.toUpperCase().contains('ALERT')) {
          Notifs.show(Notifs.idError, 'Avviso INDI', txt);
          break; // una sola per giro, evita raffica
        }
      }
    }

    // aggiorna snapshot
    _lastDone = done; _lastTotal = total;
    _seqWasRunning = seqRunning;
    _lastStarLost = starLost; _lastAppState = appState;
    _lastMsgCount = msgs.length;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
