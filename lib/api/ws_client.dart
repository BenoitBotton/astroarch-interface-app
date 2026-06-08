import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

/// WebSocket client per /ws/state e /ws/frames.
/// Auto-reconnect con backoff.
class WsClient {
  final Uri uri;
  final void Function(Map<String, dynamic> json)? onJson;
  final void Function(Uint8List bytes)? onBytes;
  final void Function(String state)? onState;
  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _stop = false;
  Duration _backoff = const Duration(seconds: 1);
  static const Duration _maxBackoff = Duration(seconds: 30);

  WsClient({
    required this.uri,
    this.onJson,
    this.onBytes,
    this.onState,
  });

  Future<void> start() async {
    _stop = false;
    _connect();
  }

  void _connect() async {
    if (_stop) return;
    onState?.call('connecting');
    try {
      _ch = WebSocketChannel.connect(uri);
      await _ch!.ready;
      onState?.call('connected');
      _backoff = const Duration(seconds: 1);
      _sub = _ch!.stream.listen(
        (data) {
          if (data is String) {
            try {
              final j = jsonDecode(data);
              if (j is Map<String, dynamic>) onJson?.call(j);
            } catch (_) {}
          } else if (data is List<int>) {
            onBytes?.call(Uint8List.fromList(data));
          }
        },
        onError: (e) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_stop) return;
    onState?.call('reconnecting');
    _sub?.cancel();
    _sub = null;
    _ch = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_backoff, _connect);
    final ms = (_backoff.inMilliseconds * 2).clamp(1000, _maxBackoff.inMilliseconds);
    _backoff = Duration(milliseconds: ms);
  }

  /// v0.2.54: forza una riconnessione IMMEDIATA, resettando il backoff e
  /// chiudendo il socket corrente (che dopo un ritorno dal background può
  /// essere "half-open": sembra connesso ma è morto). Chiamato quando l'app
  /// torna in foreground → niente attesa del backoff (fino a 30s).
  Future<void> restart() async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    try { await _ch?.sink.close(ws_status.normalClosure); } catch (_) {}
    _ch = null;
    _backoff = const Duration(seconds: 1);
    _stop = false;
    _connect();
  }

  void send(String text) {
    _ch?.sink.add(text);
  }

  Future<void> stop() async {
    _stop = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    onState?.call('disconnected');
    await _sub?.cancel();
    await _ch?.sink.close(ws_status.normalClosure);
    _sub = null;
    _ch = null;
  }
}
