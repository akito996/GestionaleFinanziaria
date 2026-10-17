import 'package:flutter/material.dart';

import '../../core/db/contabilita.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../carte/carte_pagina.dart';
import '../comuni/in_arrivo.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import '../costo_vita/costo_vita_pagina.dart' show meseBreve;
import '../../core/db/statistiche.dart';
import '../grafici/grafici.dart';
import '../grafici/grafici_avanzati.dart';
import '../movimenti/movimento_modulo.dart';
import '../movimenti/riga_movimento.dart';
import 'avviso_obiettivi.dart';
import 'elimina_portafoglio.dart';
import 'portafoglio_modulo.dart';
import '../comuni/avvisi.dart';
import '../condivisi/condividi_portafoglio.dart';
import '../sync/sync_pagina.dart';

/// Dettaglio di un portafoglio: saldo e movimenti, con modifica e archiviazione.
class PortafoglioPagina extends StatelessWidget {
  const PortafoglioPagina({
    super.key,
    required this.sessione,
    required this.portafoglioId,
  });

  final Sessione sessione;
  final String portafoglioId;

  Future<void> _archivia(BuildContext context, PortafoglioConSaldo p) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archiviare "${p.portafoglio.nome}"?'),
        content: const Text(
          'Il portafoglio sparisce dagli elenchi, ma i suoi movimenti restano '
          'salvati. Lo ritrovi in Impostazioni › Portafogli archiviati, da '
          'dove puoi ripristinarlo quando vuoi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archivia'),
          ),
        ],
      ),
    );
    if (conferma != true || !context.mounted) {
      return;
    }
    final contabilita = sessione.contabilita;
    await contabilita.archiviaPortafoglio(p.portafoglio.id);
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: Text('"${p.portafoglio.nome}" archiviato'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () => contabilita.archiviaPortafoglio(
              p.portafoglio.id,
              archiviato: false,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final contabilita = sessione.contabilita;
    return StreamBuilder<List<PortafoglioConSaldo>>(
      stream: contabilita.osservaPortafogli(),
      builder: (context, snapshot) {
        final p = snapshot.data
            ?.where((p) => p.portafoglio.id == portafoglioId)
            .firstOrNull;
        if (p == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(p.portafoglio.nome),
            // In alto solo ⟳; il resto nel menu ☰.
            actions: [
              PulsanteSincronizza(sessione: sessione),
              MenuStrumenti(
                sessione: sessione,
                notifiche: false,
                strumenti: [
                  Strumento(
                    icona: const Icon(Icons.group_add_outlined),
                    titolo: 'Condividi con altre persone',
                    descrizione: 'Invita qualcuno a usarlo insieme a te',
                    azione: () => apriInvito(context, sessione, portafoglioId),
                  ),
                  Strumento(
                    icona: const Icon(Icons.edit_outlined),
                    titolo: 'Modifica portafoglio',
                    descrizione: 'Nome, tipo, valuta e saldo di partenza',
                    azione: () => apriModuloPortafoglio(
                      context,
                      sessione,
                      esistente: p.portafoglio,
                    ),
                  ),
                  Strumento(
                    icona: const Icon(Icons.archive_outlined),
                    titolo: 'Archivia portafoglio',
                    descrizione: 'Sparisce dagli elenchi, i movimenti restano',
                    azione: () => _archivia(context, p),
                  ),
                  Strumento(
                    icona: const Icon(Icons.delete_outline),
                    titolo: 'Elimina portafoglio',
                    descrizione: 'Scegli tu cosa fare dei suoi movimenti',
                    azione: () => apriEliminaPortafoglio(
                      context,
                      sessione,
                      p.portafoglio,
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab-portafoglio-$portafoglioId',
            onPressed: () => apriModuloMovimento(
              context,
              sessione,
              portafoglioId: portafoglioId,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Movimento'),
          ),
          body: StreamBuilder<List<MovimentoDettaglio>>(
            stream: contabilita.osservaMovimenti(
              portafoglioId: portafoglioId,
              limite: 500,
            ),
            builder: (context, snapshot) {
              final movimenti = snapshot.data ?? const [];
              // Trascinando verso il basso si sincronizza subito.
              return AggiornaTrascinando(
                sessione: sessione,
                child: LayoutBuilder(
                  builder: (context, vincoli) => ListView(
                    padding: marginiPagina(vincoli, sopra: 0),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              p.tipo.nome,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Importo.formatta(p.saldo, p.portafoglio.valuta),
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: p.saldo < 0
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            AvvisiCarte(
                              sessione: sessione,
                              portafoglioId: portafoglioId,
                            ),
                            AvvisoObiettivi(
                              sessione: sessione,
                              portafoglioId: portafoglioId,
                              saldo: p.saldo,
                              valuta: p.portafoglio.valuta,
                            ),
                            SchedaInArrivo(
                              sessione: sessione,
                              portafoglioId: portafoglioId,
                              giorni: 30,
                              titolo:
                                  'Prossimi movimenti su questo portafoglio',
                              chiave: 'inarrivo.$portafoglioId',
                              escludiOrigini: const {'carta'},
                            ),
                            SchedaPersone(
                              sessione: sessione,
                              portafoglioId: portafoglioId,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _AndamentoSaldo(
                          sessione: sessione,
                          portafoglioId: portafoglioId,
                          valuta: p.portafoglio.valuta,
                        ),
                      ),
                      const Divider(height: 1),
                      if (movimenti.isEmpty && snapshot.hasData)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Nessun movimento. Premi "+ Movimento" per aggiungerne uno.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final m in movimenti)
                        RigaMovimento(
                          sessione: sessione,
                          dettaglio: m,
                          portafoglioId: portafoglioId,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Saldo di fine mese degli ultimi 12 mesi (linea; in alternativa tabella).
class _AndamentoSaldo extends StatefulWidget {
  const _AndamentoSaldo({
    required this.sessione,
    required this.portafoglioId,
    required this.valuta,
  });

  final Sessione sessione;
  final String portafoglioId;
  final String valuta;

  @override
  State<_AndamentoSaldo> createState() => _AndamentoSaldoState();
}

class _AndamentoSaldoState extends State<_AndamentoSaldo> {
  late final _candele = widget.sessione.statistiche.osservaCandeleSaldo(
    widget.portafoglioId,
    finoA: DateTime.now(),
  );
  late final _saldi = widget.sessione.statistiche.osservaSaldoMensile(
    widget.portafoglioId,
    finoA: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _saldi,
      builder: (context, snapshot) {
        final saldi = snapshot.data;
        if (saldi == null) {
          return const SizedBox.shrink();
        }
        final etichette = [for (final s in saldi) meseBreve(context, s.mese)];
        return SchedaGrafico(
          sessione: widget.sessione,
          chiave: 'portafoglio.andamento',
          titolo: 'Andamento del saldo',
          sottotitolo: 'Ultimi 12 mesi',
          tipi: const [
            TipoGrafico.linee,
            TipoGrafico.colonne,
            TipoGrafico.candele,
            TipoGrafico.tabella,
          ],
          costruisci: (context, tipo) => switch (tipo) {
            TipoGrafico.tabella => TabellaDati(
              colonne: const ['Mese', 'Saldo a fine mese'],
              righe: [
                for (final s in saldi)
                  [
                    meseLeggibile(context, s.mese),
                    Importo.formatta(s.saldo, widget.valuta),
                  ],
              ],
            ),
            TipoGrafico.colonne => Colonne(
              voci: [
                for (final (i, s) in saldi.indexed)
                  VoceValore(etichette[i], s.saldo),
              ],
              valuta: widget.valuta,
            ),
            TipoGrafico.candele => StreamBuilder<List<CandelaSaldo>>(
              stream: _candele,
              builder: (context, c) => c.data == null
                  ? const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : CandeleGrafico(
                      candele: c.data!,
                      etichette: [
                        for (final x in c.data!) meseBreve(context, x.mese),
                      ],
                      valuta: widget.valuta,
                    ),
            ),
            _ => GraficoLinee(
              etichette: etichette,
              valuta: widget.valuta,
              serie: [
                SerieTempo('Saldo', [for (final s in saldi) s.saldo]),
              ],
            ),
          },
        );
      },
    );
  }
}
