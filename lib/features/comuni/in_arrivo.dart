import 'package:flutter/material.dart';

import '../../core/db/notifiche.dart';
import '../../core/db/pianificatore.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../movimenti/riga_movimento.dart';

/// "Oggi", "Domani", "Tra 3 giorni".
String quando(int giorni) => switch (giorni) {
  0 => 'Oggi',
  1 => 'Domani',
  _ => 'Tra $giorni giorni',
};

/// Scadenze in arrivo (bollette, rate, entrate, addebiti carta). Quelle entro
/// la finestra di avviso (3 giorni) sono evidenziate; quelle già gestite nelle
/// notifiche non compaiono. Non mostra nulla se non ce ne sono.
///
/// Con [chiave] l'elenco si chiude con "Mostra meno" (scelta ricordata).
class SchedaInArrivo extends StatefulWidget {
  const SchedaInArrivo({
    super.key,
    required this.sessione,
    this.portafoglioId,
    this.giorni = 7,
    this.titolo = 'In arrivo',
    this.escludiOrigini = const {},
    this.chiave,
  });

  /// Preferenza aperta/chiusa (es. `inarrivo.<portafoglio>`); `null` = sempre
  /// aperta.
  final String? chiave;

  /// Origini da non mostrare (es. le carte, che hanno un avviso dedicato).
  final Set<String> escludiOrigini;

  final Sessione sessione;

  /// Solo le scadenze che toccano questo portafoglio.
  final String? portafoglioId;
  final int giorni;
  final String titolo;

  @override
  State<SchedaInArrivo> createState() => _SchedaInArrivoState();
}

class _SchedaInArrivoState extends State<SchedaInArrivo> {
  // Creato una volta sola: dopo il blocco la scheda non tocca più l'archivio.
  late final Stream<List<ScadenzaInArrivo>> _scadenze = widget
      .sessione
      .pianificatore
      .osservaInArrivo(
        giorni: widget.giorni,
        portafoglioId: widget.portafoglioId,
      );

  /// Notifiche già lette o gestite: le loro scadenze non si mostrano più.
  late final Stream<Set<String>> _lette = widget.sessione.notifiche
      .osservaLette();

  bool _aperta = true;

  @override
  void initState() {
    super.initState();
    final chiave = widget.chiave;
    if (chiave != null) {
      widget.sessione.statistiche.preferenza('sezione.$chiave').then((v) {
        if (mounted && v != null) {
          setState(() => _aperta = v == '1');
        }
      });
    }
  }

  void _alterna() {
    setState(() => _aperta = !_aperta);
    widget.sessione.statistiche.salvaPreferenza(
      'sezione.${widget.chiave}',
      _aperta ? '1' : '0',
    );
  }

  /// Tipi di movimento che fanno entrare soldi (per segno e colore).
  late final Future<Set<String>> _tipiEntrata = widget.sessione.contabilita
      .tipi(AmbitoTipo.movimento)
      .then(
        (tipi) => {
          for (final t in tipi)
            if (t.effetto == EffettoSaldo.entrata) t.id,
        },
      );

  @override
  Widget build(BuildContext context) {
    final giorni = widget.giorni;
    final titolo = widget.titolo;
    return FutureBuilder<Set<String>>(
      future: _tipiEntrata,
      builder: (context, entrate) => StreamBuilder<Set<String>>(
        stream: _lette,
        builder: (context, lette) => StreamBuilder<List<ScadenzaInArrivo>>(
          stream: _scadenze,
          builder: (context, snapshot) {
            final gestite = lette.data ?? const <String>{};
            final scadenze = (snapshot.data ?? const <ScadenzaInArrivo>[])
                .where(
                  (s) =>
                      !widget.escludiOrigini.contains(
                        s.pianificazione.origine,
                      ) &&
                      !gestite.contains(
                        NotificheServizio.chiaveScadenza(
                          s.pianificazione.id,
                          s.dataPrevista,
                        ),
                      ),
                )
                .toList();
            if (scadenze.isEmpty) {
              return const SizedBox.shrink();
            }
            final schema = Theme.of(context).colorScheme;
            final urgenti = scadenze.where((s) => s.daAvvisare).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: urgenti > 0 ? schema.tertiaryContainer : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading: Icon(
                          urgenti > 0
                              ? Icons.notifications_active
                              : Icons.event_note,
                          color: urgenti > 0
                              ? schema.onTertiaryContainer
                              : null,
                        ),
                        title: Text(titolo),
                        subtitle: Text(
                          urgenti > 0
                              ? '$urgenti nei prossimi 3 giorni '
                                    '(le trovi anche nelle notifiche)'
                              : '${scadenze.length} nei prossimi $giorni giorni',
                        ),
                        onTap: widget.chiave == null ? null : _alterna,
                        trailing: widget.chiave == null
                            ? null
                            : IconButton(
                                tooltip: _aperta
                                    ? 'Mostra meno'
                                    : 'Mostra di più',
                                icon: Icon(
                                  _aperta
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                onPressed: _alterna,
                              ),
                      ),
                      if (_aperta)
                        for (final s in scadenze.take(6))
                          ListTile(
                            dense: true,
                            leading: Icon(
                              s.daAvvisare
                                  ? Icons.priority_high
                                  : Icons.schedule,
                              size: 20,
                              color: s.daAvvisare
                                  ? schema.error
                                  : schema.outline,
                            ),
                            title: Text(
                              s.pianificazione.descrizione.isEmpty
                                  ? 'Pagamento programmato'
                                  : s.pianificazione.descrizione,
                            ),
                            subtitle: Text(
                              // "Oggi" basta da solo (niente "Oggi · Oggi").
                              '${quando(s.giorniMancanti)}'
                              '${s.giorniMancanti == 0 ? '' : ' · ${dataLeggibile(context, s.data)}'}'
                              '${s.pianificazione.portafoglioId == null
                                  ? ' · promemoria'
                                  : s.pianificazione.richiedeConferma
                                  ? ' · chiede conferma'
                                  : ''}',
                            ),
                            trailing: Builder(
                              builder: (context) {
                                final entrata = (entrate.data ?? const {})
                                    .contains(s.pianificazione.tipoId);
                                return Text(
                                  Importo.formatta(
                                    entrata ? s.importo : -s.importo,
                                    s.pianificazione.valuta,
                                    conSegno: entrata,
                                  ),
                                  style: TextStyle(
                                    color: coloreEffetto(
                                      context,
                                      entrata
                                          ? EffettoSaldo.entrata
                                          : EffettoSaldo.uscita,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
