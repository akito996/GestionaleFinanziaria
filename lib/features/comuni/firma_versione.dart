import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/sessione.dart';
import '../../core/versione.dart';
import 'avvisi.dart';
import 'blocco_automatico.dart';
import 'layout.dart';
import '../../core/identita.dart';

/// Indirizzo del codice sorgente (licenza AGPL-3.0: chi usa l'app può averlo).
const indirizzoCodice = Identita.indirizzoCodice;

/// La versione come una firma, solo all'apertura: compare per 3 secondi in
/// basso a sinistra quando si apre l'app e quando si sblocca l'archivio, poi
/// sfuma. Non intercetta tocchi e clic. Per rivederla: "Informazioni" (tocco
/// lungo sul lucchetto).
class FirmaIniziale extends StatefulWidget {
  const FirmaIniziale({super.key, required this.sessione});

  final Sessione sessione;

  /// Quanto resta visibile prima di sfumare.
  static const durata = Duration(seconds: 3);

  @override
  State<FirmaIniziale> createState() => _FirmaInizialeState();
}

class _FirmaInizialeState extends State<FirmaIniziale> {
  bool _visibile = true;
  Timer? _timer;
  FaseSessione? _fase;

  @override
  void initState() {
    super.initState();
    _fase = widget.sessione.fase;
    widget.sessione.addListener(_alCambio);
    _mostra();
  }

  @override
  void dispose() {
    widget.sessione.removeListener(_alCambio);
    _timer?.cancel();
    super.dispose();
  }

  /// Di nuovo per 3 secondi quando l'archivio si apre.
  void _alCambio() {
    final fase = widget.sessione.fase;
    if (fase != _fase && fase == FaseSessione.sbloccata) {
      _mostra();
    }
    _fase = fase;
  }

  void _mostra() {
    _timer?.cancel();
    if (mounted) {
      setState(() => _visibile = true);
    }
    _timer = Timer(FirmaIniziale.durata, () {
      if (mounted) {
        setState(() => _visibile = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visibile ? 1 : 0,
        duration: const Duration(milliseconds: 600),
        child: LayoutBuilder(
          builder: (context, vincoli) => Align(
            alignment: Alignment.bottomLeft,
            child: SafeArea(
              top: false,
              right: false,
              child: Padding(
                // Sul telefono sta appena sopra la barra di navigazione.
                padding: EdgeInsets.fromLTRB(
                  8,
                  0,
                  8,
                  vincoli.maxWidth < Larghezze.media
                      ? (NavigationBarTheme.of(context).height ?? 80) + 2
                      : 3,
                ),
                child: DefaultTextStyle(
                  style: tema.textTheme.labelSmall!.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.3,
                    color: tema.colorScheme.onSurface.withValues(alpha: 0.45),
                    decoration: TextDecoration.none,
                  ),
                  child: Text(
                    '${Identita.nome} ${Versione.firma} · ${Identita.copyright}',
                    semanticsLabel:
                        '${Identita.nome} versione ${Versione.numero}, '
                        '${Identita.copyright}',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Apre la pagina "Informazioni" (anche con un tocco lungo sul lucchetto).
Future<void> apriInformazioni(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const InformazioniPagina()));

/// Versione, build, licenza e codice sorgente; licenze delle librerie usate.
class InformazioniPagina extends StatelessWidget {
  const InformazioniPagina({super.key});

  String get _dettagli => [
    '${Identita.nome} ${Versione.numero}',
    if (Versione.commit.isNotEmpty) 'Build ${Versione.commit}',
    'Variante ${Versione.prova ? 'prova' : 'ufficiale'}',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Informazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 48),
                  const SizedBox(height: 8),
                  Text(Identita.nome, style: testo.titleLarge),
                  Text('Versione ${Versione.numero}', style: testo.bodyMedium),
                  Text(Identita.copyright, style: testo.bodySmall),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tag),
                  title: const Text('Versione'),
                  subtitle: Text(Versione.numero),
                ),
                ListTile(
                  leading: const Icon(Icons.commit),
                  title: const Text('Build'),
                  subtitle: Text(
                    Versione.commit.isEmpty
                        ? 'Locale (senza numero di build)'
                        : Versione.commit,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Variante'),
                  subtitle: Text(
                    Versione.prova
                        ? 'Prova: per provare le novità, dati separati'
                        : 'Ufficiale',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Privacy'),
                  subtitle: Text(
                    'I dati restano cifrati sui tuoi dispositivi. Con la '
                    'sincronizzazione viaggiano cifrati su Google Drive: '
                    'nessuno può leggerli, nemmeno Google.',
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.gavel_outlined),
                  title: Text('Licenza'),
                  subtitle: Text(
                    '${Identita.copyright}. Software libero con licenza GNU '
                    'AGPL-3.0: puoi usarlo, studiarlo, modificarlo e '
                    'condividerlo.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Codice sorgente'),
                  subtitle: const Text(indirizzoCodice),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => senzaBloccoAutomatico(
                    () => launchUrl(
                      Uri.parse(indirizzoCodice),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.library_books_outlined),
                  title: const Text('Licenze delle librerie usate'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: Identita.nome,
                    applicationVersion: Versione.firma,
                    applicationLegalese:
                        '${Identita.copyright}\nLicenza GNU AGPL-3.0',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _dettagli));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    avviso(content: const Text('Dettagli copiati')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copia i dettagli (per l\'assistenza)'),
            ),
          ),
        ],
      ),
    );
  }
}
