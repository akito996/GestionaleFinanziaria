import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/sessione.dart';
import 'layout.dart';

/// Dopo "Mostra meno" la parte chiusa (il pulsante, la sezione, la voce)
/// resta sullo schermo: la pagina si è accorciata e, se [contesto] è finito
/// sopra o sotto il bordo visibile (es. sotto la barra in basso), la pagina
/// scorre fino a lì. Altrimenti sembrerebbe sparito tutto.
void mantieniInVista(BuildContext? Function() contesto) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final c = contesto();
    if (c == null || !c.mounted) {
      return;
    }
    final oggetto = c.findRenderObject();
    final posizione = Scrollable.maybeOf(c)?.position;
    if (oggetto == null || !oggetto.attached || posizione == null) {
      return;
    }
    final vista = RenderAbstractViewport.maybeOf(oggetto);
    if (vista == null) {
      return;
    }
    // Scorrimento con l'elemento in cima / in fondo alla parte visibile.
    final inCima = vista.getOffsetToReveal(oggetto, 0).offset;
    final inFondo = vista.getOffsetToReveal(oggetto, 1).offset;
    final attuale = posizione.pixels;
    double? destinazione;
    if (attuale > inCima) {
      // Finito sopra il bordo: torna visibile, un po' sotto il bordo in alto.
      destinazione = vista.getOffsetToReveal(oggetto, 0.2).offset;
    } else if (attuale < inFondo) {
      // Finito sotto il bordo (o sotto la barra in basso): un po' più su.
      destinazione = vista.getOffsetToReveal(oggetto, 0.8).offset;
    }
    if (destinazione != null) {
      posizione.animateTo(
        destinazione.clamp(
          posizione.minScrollExtent,
          posizione.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  });
}

/// Ricorda una scelta "aperta/chiusa" (preferenza del dispositivo).
mixin _Ricordata<T extends StatefulWidget> on State<T> {
  Sessione get sessione;
  String get chiavePreferenza;
  bool get predefinita;

  late bool aperta = predefinita;

  @override
  void initState() {
    super.initState();
    sessione.statistiche.preferenza(chiavePreferenza).then((v) {
      if (mounted && v != null) {
        setState(() => aperta = v == '1');
      }
    });
  }

  void alterna() {
    setState(() => aperta = !aperta);
    sessione.statistiche.salvaPreferenza(chiavePreferenza, aperta ? '1' : '0');
    if (!aperta) {
      mantieniInVista(() => context);
    }
  }
}

/// Sezione con il titolo sempre visibile e il contenuto che si chiude con
/// "Mostra meno" (es. "Spese fisse" nel costo della vita). Chiusa resta solo
/// la riga del titolo, con il totale. La scelta resta per la prossima volta.
class SezioneRipiegabile extends StatefulWidget {
  const SezioneRipiegabile({
    super.key,
    required this.sessione,
    required this.chiave,
    required this.titolo,
    required this.child,
    this.dettaglio,
    this.inScheda = true,
  }) : costruisci = null;

  /// La sezione si disegna da sé (es. una scheda con il grafico che ha già il
  /// titolo): [costruisci] riceve se è aperta e come aprirla o chiuderla.
  const SezioneRipiegabile.costruita({
    super.key,
    required this.sessione,
    required this.chiave,
    required this.titolo,
    required Widget Function(
      BuildContext context,
      bool aperta,
      VoidCallback alterna,
    )
    this.costruisci,
  }) : child = const SizedBox.shrink(),
       dettaglio = null,
       inScheda = true;

  final Sessione sessione;

  /// Identifica la sezione nelle preferenze (es. "costo_vita.fisse").
  final String chiave;
  final String titolo;

  /// A destra del titolo (es. il totale), visibile anche da chiusa.
  final String? dettaglio;
  final Widget child;

  /// `true` = titolo e contenuto nella stessa scheda; `false` = il contenuto
  /// è già una scheda (es. un grafico) e il titolo sta sopra.
  final bool inScheda;

  final Widget Function(
    BuildContext context,
    bool aperta,
    VoidCallback alterna,
  )?
  costruisci;

  @override
  State<SezioneRipiegabile> createState() => _SezioneRipiegabileState();
}

class _SezioneRipiegabileState extends State<SezioneRipiegabile>
    with _Ricordata {
  @override
  Sessione get sessione => widget.sessione;

  @override
  String get chiavePreferenza => 'sezione.${widget.chiave}';

  @override
  bool get predefinita => true;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final costruisci = widget.costruisci;
    if (costruisci != null) {
      return aperta
          ? costruisci(context, true, alterna)
          : Card(
              child: ListTile(
                title: Text(widget.titolo, style: testo.titleMedium),
                onTap: alterna,
                trailing: IconButton(
                  tooltip: 'Mostra di più',
                  icon: const Icon(Icons.expand_more),
                  onPressed: alterna,
                ),
              ),
            );
    }
    final intestazione = ListTile(
      title: Text(widget.titolo, style: testo.titleMedium),
      onTap: alterna,
      contentPadding: EdgeInsets.only(
        left: widget.inScheda ? 16 : 4,
        right: widget.inScheda ? 8 : 0,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.dettaglio != null)
            Text(widget.dettaglio!, style: testo.titleMedium),
          IconButton(
            tooltip: aperta ? 'Mostra meno' : 'Mostra di più',
            icon: Icon(aperta ? Icons.expand_less : Icons.expand_more),
            onPressed: alterna,
          ),
        ],
      ),
    );
    final contenuto = AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: aperta ? widget.child : const SizedBox(width: double.infinity),
    );
    if (widget.inScheda) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [intestazione, contenuto],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [intestazione, contenuto],
    );
  }
}

/// Una voce di [ElencoRipiegabile]: la riga breve e la scheda completa.
class VoceRipiegabile {
  const VoceRipiegabile({
    required this.id,
    required this.titolo,
    required this.completa,
    this.sottotitolo,
    this.valore,
    this.icona,
  });

  final String id;
  final String titolo;
  final String? sottotitolo;

  /// La cifra più importante (es. il debito residuo).
  final String? valore;
  final IconData? icona;
  final Widget completa;
}

/// Elenco di schede (carte, prestiti, obiettivi) con "Mostra meno" (una riga
/// per voce) e "Mostra di più" (schede complete). Da ridotta, un tocco apre la
/// singola voce. La scelta resta per la prossima volta.
class ElencoRipiegabile extends StatefulWidget {
  const ElencoRipiegabile({
    super.key,
    required this.sessione,
    required this.chiave,
    required this.voci,
    this.intestazione = const [],
  });

  final Sessione sessione;

  /// Identifica l'elenco nelle preferenze (es. "prestiti").
  final String chiave;
  final List<VoceRipiegabile> voci;
  final List<Widget> intestazione;

  @override
  State<ElencoRipiegabile> createState() => _ElencoRipiegabileState();
}

class _ElencoRipiegabileState extends State<ElencoRipiegabile> with _Ricordata {
  final Set<String> _aperte = {};
  final _pulsante = GlobalKey();
  final _chiavi = <String, GlobalKey>{};

  GlobalKey _chiaveVoce(String id) => _chiavi.putIfAbsent(id, GlobalKey.new);

  @override
  Sessione get sessione => widget.sessione;

  @override
  String get chiavePreferenza => 'elenco.${widget.chiave}.completo';

  /// Tutte ridotte o tutte complete: il pulsante in cima resta in vista.
  void _alternaTutte() {
    setState(_aperte.clear);
    alterna();
    mantieniInVista(() => _pulsante.currentContext);
  }

  /// Una voce aperta da ridotta torna a una riga, e resta in vista.
  void _riduci(String id) {
    setState(() => _aperte.remove(id));
    mantieniInVista(() => _chiaveVoce(id).currentContext);
  }

  @override
  bool get predefinita => true;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return ElencoSchede(
      intestazione: [
        ...widget.intestazione,
        Align(
          key: _pulsante,
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: _alternaTutte,
            icon: Icon(aperta ? Icons.unfold_less : Icons.unfold_more),
            label: Text(aperta ? 'Mostra meno' : 'Mostra di più'),
          ),
        ),
      ],
      schede: [
        for (final v in widget.voci)
          if (aperta || _aperte.contains(v.id))
            aperta
                ? v.completa
                : Column(
                    key: _chiaveVoce(v.id),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      v.completa,
                      TextButton.icon(
                        onPressed: () => _riduci(v.id),
                        icon: const Icon(Icons.expand_less),
                        label: const Text('Mostra meno'),
                      ),
                    ],
                  )
          else
            Card(
              key: _chiaveVoce(v.id),
              child: ListTile(
                leading: v.icona == null ? null : Icon(v.icona),
                title: Text(
                  v.titolo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: v.sottotitolo == null
                    ? null
                    : Text(
                        v.sottotitolo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (v.valore != null)
                      Text(
                        v.valore!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: schema.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    const Icon(Icons.expand_more),
                  ],
                ),
                onTap: () => setState(() => _aperte.add(v.id)),
              ),
            ),
      ],
    );
  }
}
