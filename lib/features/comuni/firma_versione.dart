import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/versione.dart';
import 'avvisi.dart';

/// Indirizzo del codice sorgente (licenza AGPL-3.0: chi usa l'app può averlo).
const indirizzoCodice = 'https://github.com/akito996/GestionaleFinanziaria';

/// Titolo della barra in alto con la versione, piccola, sotto: la firma
/// dell'app su ogni schermata, senza coprire nulla. Un tocco sulla versione
/// apre "Informazioni".
class TitoloConFirma extends StatelessWidget {
  const TitoloConFirma(this.titolo, {super.key});

  final String titolo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, maxLines: 1, overflow: TextOverflow.ellipsis),
        Tooltip(
          message: 'Informazioni sull\'app',
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => apriInformazioni(context),
            child: Text(
              Versione.firma,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: 'Versione ${Versione.numero}',
              style: tema.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 0.3,
                color: tema.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La versione in fondo alle pagine senza barra in alto (es. primo avvio).
class FirmaInFondo extends StatelessWidget {
  const FirmaInFondo({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => apriInformazioni(context),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              Versione.firma,
              semanticsLabel: 'Versione ${Versione.numero}',
              style: tema.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: tema.colorScheme.onSurface.withValues(alpha: 0.45),
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
    'GestionaleFinanziaria ${Versione.numero}',
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
                  Text('GestionaleFinanziaria', style: testo.titleLarge),
                  Text('Versione ${Versione.numero}', style: testo.bodyMedium),
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
                    'Software libero con licenza GNU AGPL-3.0: puoi usarlo, '
                    'studiarlo, modificarlo e condividerlo.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Codice sorgente'),
                  subtitle: const Text(indirizzoCodice),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => launchUrl(
                    Uri.parse(indirizzoCodice),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.library_books_outlined),
                  title: const Text('Licenze delle librerie usate'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'GestionaleFinanziaria',
                    applicationVersion: Versione.firma,
                    applicationLegalese: 'Licenza GNU AGPL-3.0',
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
