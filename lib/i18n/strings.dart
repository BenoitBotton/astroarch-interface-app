// AUTO-MAINTAINED. Tabella di traduzione IT → EN.
// La lingua di default dell'app è italiano: le stringhe italiane fungono
// da CHIAVE; quando l'utente seleziona English in Settings, .tr(context)
// restituisce il valore inglese dalla mappa (se manca, ritorna la chiave
// italiana, così nulla esplode in produzione anche se dimentichiamo una
// traduzione).
//
// REGOLA: ogni nuova stringa UI italiana va aggiunta qui prima del release.
// Per stringhe con placeholder (es. "${count} files") usare {0}, {1}, …
// e poi .trFmt(context, [args]).

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'locales/en.dart';

enum AppLocale { it, en }

class L10n {
  /// Tabella IT -> EN. Ogni voce nuova: italiano -> inglese.
  /// Le chiavi sono CASE-SENSITIVE, inclusa la punteggiatura.
  static const Map<String, String> _en = enStrings;


  /// Legge la stringa nella lingua corrente dello stato.
  static String t(BuildContext context, String it) {
    final loc = context.read<AppState>().locale;
    if (loc == AppLocale.it) return it;
    return _en[it] ?? it;
  }

  /// Variante "format" con placeholders {0}, {1}, …
  /// Esempio: 'Eliminare {0} file?'.trFmt(context, ['12'])
  static String tFmt(BuildContext context, String it, List<Object> args) {
    var s = t(context, it);
    for (int i = 0; i < args.length; i++) {
      s = s.replaceAll('{$i}', args[i].toString());
    }
    return s;
  }
}

extension StringTr on String {
  /// Traduzione di una stringa italiana. Esempio:
  ///   Text('Acquisisci e Risolvi'.tr(context))
  String tr(BuildContext c) => L10n.t(c, this);

  /// Traduzione con placeholders {0}, {1}, …
  String trFmt(BuildContext c, List<Object> args) => L10n.tFmt(c, this, args);
}
