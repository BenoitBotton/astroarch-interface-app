import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../api/api_client.dart';
import '../../state/app_state.dart';
import '../../state/capture_job.dart';

/// Esegue una lista di CaptureJob in sequenza (Ekos-like).
///
/// Per ogni job:
/// 1. Cambia filter wheel se filter specificato e diverso dal corrente
/// 2. Imposta gain/offset/binning/frame_type
/// 3. Loop di N esposizioni: scatta -> attende fine -> dither (se on) -> delay
///
/// Stato esposto come ChangeNotifier per UI live.
class SequenceRunner extends ChangeNotifier {
  final AppState appState;
  SequenceRunner(this.appState);

  bool _running = false;
  bool _abort = false;
  bool _paused = false;
  int _currentJobIdx = -1;
  int _currentExposure = 0;
  String? _statusMsg;

  bool get running => _running;
  bool get paused => _paused;
  int get currentJobIdx => _currentJobIdx;
  int get currentExposure => _currentExposure;
  String? get statusMsg => _statusMsg;

  Future<void> run({required String camera, String? filterWheel}) async {
    if (_running) return;
    _running = true;
    _abort = false;
    _paused = false;
    appState.resetJobsStatus();
    notifyListeners();

    try {
      for (int i = 0; i < appState.captureJobs.length; i++) {
        if (_abort) break;
        _currentJobIdx = i;
        final job = appState.captureJobs[i];
        job.status = CaptureJobStatus.running;
        notifyListeners();

        // 1. Filter switch
        if (job.filter != null && filterWheel != null) {
          final ok = await _switchFilter(filterWheel, job.filter!);
          if (!ok) {
            job.status = CaptureJobStatus.failed;
            job.lastError = 'Cambio filter fallito';
            notifyListeners();
            continue;
          }
        }

        // 2. Setup parameters - upload mode FIRST (per ricevere FITS)
        try {
          // Forza UPLOAD_MODE=BOTH così Ekos ed app ricevono entrambi
          await appState.api!.cameraUploadSetup(
            device: camera, mode: 'BOTH',
            prefix: '${job.targetName ?? "frame"}_${job.filter ?? "none"}_XXX',
          );
        } catch (e) {
          // Non bloccante: alcuni driver non hanno UPLOAD_MODE
          // ignore_for_file: empty_catches
        }
        try {
          await appState.api!.cameraTransferFormat(job.transferFormat, device: camera);
        } catch (_) {}
        try {
          await appState.api!.cameraCaptureFormat(job.captureFormat, device: camera);
        } catch (_) {}
        try {
          await appState.api!.cameraGain(job.gain, device: camera);
          await appState.api!.cameraOffset(job.offset, device: camera);
          await appState.api!.cameraBinning(job.binX, job.binY, device: camera);
          await appState.api!.cameraFrameType(job.frameType, device: camera);
        } catch (e) {
          job.status = CaptureJobStatus.failed;
          job.lastError = 'Setup parametri: $e';
          notifyListeners();
          continue;
        }

        // 3. Loop esposizioni
        bool jobOk = true;
        for (int n = 0; n < job.count; n++) {
          if (_abort) break;
          while (_paused && !_abort) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          _currentExposure = n + 1;
          _statusMsg = 'Job ${i + 1}: ${job.summary} · scatto ${n + 1}/${job.count}';
          notifyListeners();

          try {
            await appState.api!.cameraExpose(job.exposureSec, device: camera);
          } on ApiException catch (e) {
            job.lastError = 'Expose: ${e.body}';
            jobOk = false;
            break;
          } catch (e) {
            job.lastError = 'Expose: $e';
            jobOk = false;
            break;
          }

          final ok = await _waitExposureDone(camera, job.exposureSec.toInt() + 60);
          if (!ok) {
            job.lastError = 'Timeout esposizione';
            jobOk = false;
            break;
          }
          job.doneCount = n + 1;
          notifyListeners();

          // Dither
          if (job.ditherEachFrame && n < job.count - 1) {
            try {
              await appState.api!.guideDither(amount: 3.0);
              // Aspetta che PHD2 sia "settled"
              await Future.delayed(const Duration(seconds: 8));
            } catch (_) {}
          }

          // Delay
          if (n < job.count - 1 && job.delaySec > 0) {
            await Future.delayed(Duration(milliseconds: (job.delaySec * 1000).toInt()));
          }
        }

        if (_abort) {
          job.status = CaptureJobStatus.aborted;
        } else if (jobOk) {
          job.status = CaptureJobStatus.done;
        } else {
          job.status = CaptureJobStatus.failed;
        }
        notifyListeners();
      }
    } finally {
      _running = false;
      _currentJobIdx = -1;
      _statusMsg = _abort ? 'Sequenza interrotta' : 'Sequenza completata';
      notifyListeners();
    }
  }

  void abort() {
    _abort = true;
    _paused = false;
    notifyListeners();
  }

  void pause() {
    _paused = true;
    notifyListeners();
  }

  void resume() {
    _paused = false;
    notifyListeners();
  }

  Future<bool> _switchFilter(String filterWheel, String wantedName) async {
    final p = appState.prop(filterWheel, 'FILTER_NAME');
    if (p == null) return true; // no filter wheel info, skip
    final elements = (p['elements'] as List? ?? []).cast<Map>();
    int? slot;
    for (int i = 0; i < elements.length; i++) {
      final v = elements[i]['value']?.toString().toUpperCase().trim();
      if (v == wantedName.toUpperCase().trim()) {
        slot = i + 1;
        break;
      }
    }
    if (slot == null) return false;
    try {
      await appState.api!.filterSelect(slot, device: filterWheel);
      // Aspetta che il movimento finisca
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (DateTime.now().isBefore(deadline)) {
        final fp = appState.prop(filterWheel, 'FILTER_SLOT');
        if (fp?['state'] == 'Ok') return true;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _waitExposureDone(String camera, int timeoutSec) async {
    // Aspetta avvio (Busy) entro 5s
    final startDeadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(startDeadline)) {
      if (_abort) return false;
      final p = appState.prop(camera, 'CCD_EXPOSURE');
      if (p?['state'] == 'Busy') break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    // Aspetta fine
    final deadline = DateTime.now().add(Duration(seconds: timeoutSec));
    while (DateTime.now().isBefore(deadline)) {
      if (_abort) return false;
      final p = appState.prop(camera, 'CCD_EXPOSURE');
      final state = p?['state'];
      if (state == 'Ok' || state == 'Idle') return true;
      if (state == 'Alert') return false;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }
}
