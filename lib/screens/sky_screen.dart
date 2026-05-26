import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell_screen.dart';

/// Planetario KStars (v0.2.40).
/// Mostra il SkyMap live di KStars (vero rendering: stelle, costellazioni,
/// deep-sky, crosshair telescopio) come immagine che si aggiorna ogni ~2.5s.
///
/// FASE 1: vedere dove punta il telescopio nel cielo + zoom/pan/ricerca.
/// FASE 2: tap su un punto → ricentra lì → conferma → GOTO del telescopio.
///
/// Riusa /api/skymap/* del bridge. Centrare/zoomare NON muove il telescopio:
/// il goto avviene solo con conferma esplicita.
class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key});
  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  Timer? _timer;
  Uint8List? _png;
  Map<String, dynamic>? _focus;   // {ra_deg, dec_deg, fov_deg, object, alt_deg, az_deg}
  int _imgW = 1000, _imgH = 700;  // risoluzione richiesta al bridge
  String? _err;
  bool _inflight = false;
  bool _busy = false;             // azione di controllo in corso
  final GlobalKey _imgKey = GlobalKey();

  // --- Pan (trascinamento) ---
  Offset _dragOffset = Offset.zero;   // offset visivo durante il drag
  Offset _dragTotal = Offset.zero;    // delta totale del drag in px schermo
  Offset? _panStartGlobal;            // posizione iniziale (per drag piccolo = tap)
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    if (_inflight || _busy || _dragging) return;
    final s = context.read<AppState>();
    if (s.api == null) return;
    _inflight = true;
    try {
      final j = await s.api!.skymapView(width: _imgW, height: _imgH);
      final b64 = j['png_base64'] as String?;
      if (b64 == null) throw Exception('missing png');
      if (!mounted) return;
      setState(() {
        _png = base64.decode(b64);
        _focus = (j['focus'] as Map?)?.cast<String, dynamic>();
        _err = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _err = _extractDetail(e.body));
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
    } finally {
      _inflight = false;
    }
  }

  String _extractDetail(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] != null) return j['detail'].toString();
    } catch (_) {}
    return body;
  }

  Future<void> _action(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
      await _tick(); // refresh immediato dopo l'azione
    } on ApiException catch (e) {
      if (mounted) showSnack(context, '${'Errore: '.tr(context)}${_extractDetail(e.body)}', error: true);
    } catch (e) {
      if (mounted) showSnack(context, '${'Errore: '.tr(context)}$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- Pan (scorrimento col dito, come il mouse su KStars desktop) --------
  // Calcola l'area effettiva dell'immagine (BoxFit.contain) entro il box.
  ({double dispW, double dispH, double offX, double offY})? _imgRect() {
    final box = _imgKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size;
    final imgAR = _imgW / _imgH;
    final boxAR = size.width / size.height;
    double dispW, dispH, offX, offY;
    if (boxAR > imgAR) {
      dispH = size.height; dispW = dispH * imgAR;
      offX = (size.width - dispW) / 2; offY = 0;
    } else {
      dispW = size.width; dispH = dispW / imgAR;
      offX = 0; offY = (size.height - dispH) / 2;
    }
    return (dispW: dispW, dispH: dispH, offX: offX, offY: offY);
  }

  void _onPanStart(DragStartDetails d) {
    if (_busy) return;
    _dragging = true;
    _dragTotal = Offset.zero;
    _dragOffset = Offset.zero;
    _panStartGlobal = d.globalPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    setState(() {
      _dragTotal += d.delta;
      _dragOffset += d.delta;  // feedback visivo: l'immagine segue il dito
    });
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    if (!_dragging) return;
    final total = _dragTotal;
    final start = _panStartGlobal;
    _dragging = false;

    // Movimento minimo → è un tap, non un pan: apri il flusso goto
    if (total.distance < 10) {
      setState(() => _dragOffset = Offset.zero);
      if (start != null) await _gotoAtGlobal(start);
      return;
    }
    final s = context.read<AppState>();
    final rect = _imgRect();
    if (s.api == null || rect == null) {
      setState(() => _dragOffset = Offset.zero);
      return;
    }
    // Converti il delta da px schermo a px immagine richiesta
    final dxImg = total.dx * (_imgW / rect.dispW);
    final dyImg = total.dy * (_imgH / rect.dispH);
    // IMPORTANTE: NON resetto _dragOffset qui. L'immagine resta dov'è il dito
    // finché non arriva quella nuova ricentrata → swap atomico, niente scatto.
    setState(() => _busy = true);
    try {
      await s.api!.skymapPan(dxImg, dyImg, _imgW, _imgH);
      // Scarico subito la nuova immagine centrata e faccio lo swap atomico:
      // nuovo PNG + reset offset NELLO STESSO setState → transizione fluida.
      final j = await s.api!.skymapView(width: _imgW, height: _imgH);
      final b64 = j['png_base64'] as String?;
      if (!mounted) return;
      if (b64 != null) {
        setState(() {
          _png = base64.decode(b64);
          _focus = (j['focus'] as Map?)?.cast<String, dynamic>();
          _dragOffset = Offset.zero;
          _err = null;
          _busy = false;
        });
      } else {
        setState(() { _dragOffset = Offset.zero; _busy = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _dragOffset = Offset.zero; _busy = false; });
        showSnack(context, '${'Errore: '.tr(context)}$e', error: true);
      }
    }
  }

  // Tap pulito (onTapUp): tap-to-goto sul punto toccato
  Future<void> _onTapImage(TapUpDetails d) async {
    if (_dragging) return;
    await _gotoAtGlobal(d.globalPosition);
  }

  // --- FASE 2: tap → ricentra → conferma → goto ---------------------------
  Future<void> _gotoAtGlobal(Offset globalPos) async {
    if (_busy) return;
    final s = context.read<AppState>();
    if (s.api == null) return;
    final box = _imgKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final local = box.globalToLocal(globalPos);
    // L'immagine è BoxFit.contain: calcolo l'area effettiva
    final imgAR = _imgW / _imgH;
    final boxAR = size.width / size.height;
    double dispW, dispH, offX, offY;
    if (boxAR > imgAR) {
      dispH = size.height; dispW = dispH * imgAR;
      offX = (size.width - dispW) / 2; offY = 0;
    } else {
      dispW = size.width; dispH = dispW / imgAR;
      offX = 0; offY = (size.height - dispH) / 2;
    }
    final px = local.dx - offX, py = local.dy - offY;
    if (px < 0 || py < 0 || px > dispW || py > dispH) return; // tap fuori immagine
    // Mappo al sistema di coordinate dell'immagine richiesta
    final tx = (px / dispW * _imgW).round();
    final ty = (py / dispH * _imgH).round();

    setState(() => _busy = true);
    try {
      final r = await s.api!.skymapTap(tx, ty, _imgW, _imgH);
      await _tick(); // mostra il SkyMap ricentrato
      if (!mounted) return;
      final foc = (r['focus'] as Map?)?.cast<String, dynamic>() ?? {};
      final obj = (r['candidate_object'] ?? foc['object'])?.toString();
      final raDeg = (r['goto_ra_deg'] as num?)?.toDouble();
      final decDeg = (r['goto_dec_deg'] as num?)?.toDouble();
      if (raDeg == null || decDeg == null) {
        showSnack(context, 'Coordinate non disponibili'.tr(context), error: true);
        return;
      }
      _confirmGoto(s, obj, raDeg, decDeg, foc['ra_hms']?.toString(), foc['dec_dms']?.toString());
    } on ApiException catch (e) {
      if (mounted) showSnack(context, '${'Errore: '.tr(context)}${_extractDetail(e.body)}', error: true);
    } catch (e) {
      if (mounted) showSnack(context, '${'Errore: '.tr(context)}$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirmGoto(AppState s, String? obj, double raDeg, double decDeg,
      String? raHms, String? decDms) {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: T.panel(context),
      title: Text('Vai su questo punto?'.tr(context)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (obj != null && obj.isNotEmpty) ...[
          Text(obj, style: TextStyle(color: T.accent(context), fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        Text('RA  ${raHms ?? '${(raDeg / 15).toStringAsFixed(4)}h'}',
            style: const TextStyle(fontFamily: 'monospace')),
        Text('Dec ${decDms ?? '${decDeg.toStringAsFixed(3)}°'}',
            style: const TextStyle(fontFamily: 'monospace')),
        const SizedBox(height: 10),
        Text('Il telescopio si muoverà su queste coordinate.'.tr(context),
            style: TextStyle(color: T.muted(context), fontSize: 12)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text('ANNULLA'.tr(context))),
        ElevatedButton.icon(
          icon: const Icon(Icons.my_location, size: 18),
          label: Text('GOTO'.tr(context)),
          onPressed: () async {
            Navigator.pop(c);
            await _action(() async {
              // mountGoto vuole RA in ORE
              await s.api!.mountGoto(raDeg / 15.0, decDeg, action: 'track');
              if (mounted) showSnack(context, '${'Goto avviato: '.tr(context)}${obj ?? ''}');
            });
          },
        ),
      ],
    ));
  }

  Future<void> _searchDialog(AppState s) async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (c) => AlertDialog(
      backgroundColor: T.panel(context),
      title: Text('Cerca oggetto'.tr(context)),
      content: TextField(
        controller: ctl,
        autofocus: true,
        decoration: InputDecoration(hintText: 'M 51, NGC 7000, Vega…'.tr(context)),
        onSubmitted: (v) => Navigator.pop(c, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text('ANNULLA'.tr(context))),
        ElevatedButton(onPressed: () => Navigator.pop(c, ctl.text), child: Text('CENTRA'.tr(context))),
      ],
    ));
    if (name == null || name.trim().isEmpty) return;
    final q = name.trim();
    setState(() => _busy = true);
    try {
      // Risoluzione robusta via SIMBAD/Sesame (capisce "M51", "M 51",
      // "NGC 5194", "Whirlpool", "Vega"…) → coordinate → centra il SkyMap.
      // Più affidabile di lookTowards che è schizzinoso sul formato nome.
      final res = await s.api!.simbadSearch(q);
      final raHours = (res['ra_hours'] as num?)?.toDouble();
      final decDeg = (res['dec_deg'] as num?)?.toDouble();
      if (raHours != null && decDeg != null) {
        await s.api!.skymapCenterCoords(raHours * 15.0, decDeg);
        if (mounted) showSnack(context, '${'Centrato su '.tr(context)}$q');
      } else {
        // fallback: prova comunque lookTowards lato KStars
        await s.api!.skymapCenterObject(q);
      }
    } on ApiException catch (e) {
      // SIMBAD non ha trovato → fallback lookTowards, poi messaggio chiaro
      try {
        await s.api!.skymapCenterObject(q);
      } catch (_) {
        if (mounted) showSnack(context, '${'Oggetto non trovato: '.tr(context)}$q', error: true);
      }
      if (e.status != 404 && mounted) {
        // ignora, già gestito
      }
    } catch (e) {
      if (mounted) showSnack(context, '${'Errore: '.tr(context)}$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final connected = s.api != null;
    final foc = _focus;
    final fov = (foc?['fov_deg'] as num?)?.toDouble();
    final obj = foc?['object']?.toString();
    final raHms = foc?['ra_hms']?.toString();
    final decDms = foc?['dec_dms']?.toString();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: openShellDrawer),
        title: Row(children: [
          const Icon(Icons.public, size: 20),
          const SizedBox(width: 8),
          Text('Planetario'.tr(context)),
          const Spacer(),
          if (fov != null)
            Text('FOV ${fov < 1 ? fov.toStringAsFixed(2) : fov.toStringAsFixed(1)}°',
                style: TextStyle(color: T.muted(context), fontSize: 12, fontFamily: 'monospace')),
        ]),
      ),
      body: !connected
          ? Center(child: Text('Non connesso'.tr(context), style: TextStyle(color: T.muted(context))))
          : Column(children: [
              // --- Immagine planetario ---
              Expanded(
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  child: Stack(fit: StackFit.expand, children: [
                    if (_png != null)
                      GestureDetector(
                        onTapUp: _onTapImage,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Transform.translate(
                          // feedback visivo: durante il drag l'immagine segue il dito
                          offset: _dragOffset,
                          child: Image.memory(_png!,
                              key: _imgKey,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium),
                        ),
                      )
                    else if (_err != null)
                      Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.public_off, color: T.muted(context), size: 32),
                          const SizedBox(height: 10),
                          Text(_err!, textAlign: TextAlign.center,
                              style: TextStyle(color: T.muted(context), fontSize: 13)),
                          const SizedBox(height: 8),
                          Text('Avvia KStars dalla Dashboard (LAUNCH KStars)'.tr(context),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: T.muted(context), fontSize: 11)),
                        ]),
                      ))
                    else
                      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    // HUD: oggetto al centro + coordinate
                    if (_png != null && (obj != null || raHms != null)) Positioned(
                      left: 8, top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black54,
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (obj != null && obj.isNotEmpty)
                            Text(obj, style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 13)),
                          if (raHms != null)
                            Text('$raHms  ${decDms ?? ''}',
                                style: const TextStyle(color: Colors.white70,
                                    fontFamily: 'monospace', fontSize: 10)),
                        ]),
                      ),
                    ),
                    // hint tap
                    if (_png != null) Positioned(
                      right: 8, top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('Tap = vai qui'.tr(context),
                            style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ),
                    ),
                    if (_busy) const Positioned(
                      right: 8, bottom: 8,
                      child: SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ]),
                ),
              ),
              // --- Barra controlli ---
              Container(
                color: T.panel(context),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _ctlBtn(Icons.zoom_in, 'Zoom +'.tr(context),
                        () => _action(() => s.api!.skymapZoom(dir: 'in').then((_) {}))),
                    _ctlBtn(Icons.zoom_out, 'Zoom −'.tr(context),
                        () => _action(() => s.api!.skymapZoom(dir: 'out').then((_) {}))),
                    _ctlBtn(Icons.my_location, 'Telescopio'.tr(context),
                        () => _action(() => s.api!.skymapCenterTelescope().then((_) {}))),
                    _ctlBtn(Icons.search, 'Cerca'.tr(context), () => _searchDialog(s)),
                  ]),
                  const SizedBox(height: 6),
                  // Preset FOV rapidi
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    for (final f in const [1.0, 5.0, 20.0, 60.0, 120.0])
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: const Size(0, 30),
                          side: BorderSide(color: T.line(context)),
                        ),
                        onPressed: _busy ? null : () => _action(() => s.api!.skymapZoom(fovDeg: f).then((_) {})),
                        child: Text('${f < 1 ? f : f.toStringAsFixed(0)}°',
                            style: TextStyle(color: T.text(context), fontSize: 12)),
                      ),
                  ]),
                ]),
              ),
            ]),
    );
  }

  Widget _ctlBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _busy ? T.muted(context) : T.accent(context), size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: T.muted(context), fontSize: 10)),
        ]),
      ),
    );
  }
}
