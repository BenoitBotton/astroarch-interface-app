import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell_screen.dart';

/// v0.2.57: vista per il GUIDER INTERNO di Ekos (alternativa a PHD2).
/// Mostrata da GuideScreen quando il bridge riporta `backend == 'internal'`.
/// Comanda `org.kde.kstars.Ekos.Guide` via gli endpoint /api/guide/ekos_*.
///
/// NB: la vista PHD2 (grafico + star image + full frame) resta invariata e
/// viene usata quando Ekos guida con PHD2. Qui mostriamo stato + RMS +
/// i comandi base (start/stop/calibrate/dither/loop), che è ciò che il
/// guider interno espone via DBus.
class EkosGuideView extends StatefulWidget {
  final Future<void> Function()? onReload;
  const EkosGuideView({super.key, this.onReload});
  @override
  State<EkosGuideView> createState() => _EkosGuideViewState();
}

class _EkosGuideViewState extends State<EkosGuideView> {
  Timer? _timer;
  Map<String, dynamic>? _status;
  bool _inflight = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    if (_inflight) return;
    final s = context.read<AppState>();
    if (s.api == null) return;
    _inflight = true;
    try {
      final r = await s.api!.guideEkosStatus();
      if (mounted) setState(() => _status = r);
    } catch (_) {
      // transitorio: manteniamo l'ultimo stato noto
    } finally {
      _inflight = false;
    }
  }

  Future<void> _safe(Future Function() fn, String msg) async {
    try {
      await fn();
      if (mounted) showSnack(context, msg);
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, '${'Errore: '.tr(context)}${_detail(e.body)}', error: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, '${'Errore: '.tr(context)}$e', error: true);
    }
  }

  String _detail(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] != null) return j['detail'].toString();
    } catch (_) {}
    return body;
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    final st = _status?['state']?.toString() ?? '—';
    final rms = (_status?['rms_total'] as num?)?.toDouble();
    final raRms = (_status?['rms_ra'] as num?)?.toDouble();
    final decRms = (_status?['rms_dec'] as num?)?.toDouble();
    final guiding = st.toUpperCase().contains('GUID');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: openShellDrawer),
        title: Row(children: [
          const LiveDot(),
          const SizedBox(width: 10),
          Text('${'Guide'.tr(context)} · Ekos'),
          const Spacer(),
          Text(st, style: TextStyle(
              color: guiding ? T.ok(context) : T.muted(context), fontSize: 12)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Ricontrolla guider'.tr(context),
            onPressed: () => widget.onReload?.call(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: T.accent(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: T.accent(context).withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              Icon(Icons.auto_graph, color: T.accent(context), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Guida interna di Ekos (non PHD2). Comandi via Ekos.Guide.'.tr(context),
                style: TextStyle(color: T.muted(context), fontSize: 12),
              )),
            ]),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
            childAspectRatio: 1.7,
            children: [
              StatusCard(header: 'RMS TOTAL'.tr(context),
                  value: rms == null ? '—' : '${rms.toStringAsFixed(2)}″',
                  subtitle: 'target < 1.0″'),
              StatusCard(header: 'STATO'.tr(context), value: st),
              StatusCard(header: 'RA RMS'.tr(context),
                  value: raRms == null ? '—' : '${raRms.toStringAsFixed(2)}″'),
              StatusCard(header: 'DEC RMS'.tr(context),
                  value: decRms == null ? '—' : '${decRms.toStringAsFixed(2)}″'),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'START', icon: Icons.play_arrow,
                onPressed: api == null ? null
                    : () => _safe(() => api.guideEkosStart(), 'Guida avviata'.tr(context)))),
            const SizedBox(width: 8),
            Expanded(child: GhostButton(label: 'STOP', icon: Icons.stop,
                onPressed: api == null ? null
                    : () => _safe(() => api.guideEkosStop(), 'Fermato'.tr(context)))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: GhostButton(label: 'DITHER', icon: Icons.scatter_plot,
                onPressed: api == null ? null
                    : () => _safe(() => api.guideEkosDither(), 'Dither'.tr(context)))),
            const SizedBox(width: 8),
            Expanded(child: GhostButton(label: 'LOOP', icon: Icons.loop,
                onPressed: api == null ? null
                    : () => _safe(() => api.guideEkosLoop(), 'Loop avviato'.tr(context)))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: GhostButton(label: 'CALIBRATE', icon: Icons.adjust,
                onPressed: api == null ? null
                    : () => _safe(() => api.guideEkosCalibrate(),
                        'Calibrazione avviata'.tr(context)))),
          ]),
          const SizedBox(height: 12),
          Text('Nota: la vista PHD2 completa (grafico, star image, full frame) '
               'è disponibile quando in Ekos il guider è impostato su PHD2.'.tr(context),
              style: TextStyle(color: T.muted(context), fontSize: 11)),
        ],
      ),
    );
  }
}
