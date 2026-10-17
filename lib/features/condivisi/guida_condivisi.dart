import 'package:flutter/material.dart';

import '../comuni/layout.dart';

/// Chi legge la guida: chi condivide un suo portafoglio o chi è invitato.
enum RuoloGuida { proprietario, membro }

/// Apre "Come si fa": i passi per chi condivide e per chi è invitato.
Future<void> apriGuidaCondivisi(
  BuildContext context, {
  RuoloGuida ruolo = RuoloGuida.proprietario,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => GuidaCondivisiPagina(ruolo: ruolo)),
);

/// Istruzioni semplici per i portafogli condivisi (ADR-019): si sceglie in
/// alto "Condivido io" o "Mi hanno invitato" e si seguono i passi numerati.
class GuidaCondivisiPagina extends StatefulWidget {
  const GuidaCondivisiPagina({super.key, this.ruolo = RuoloGuida.proprietario});

  final RuoloGuida ruolo;

  @override
  State<GuidaCondivisiPagina> createState() => _GuidaCondivisiPaginaState();
}

class _GuidaCondivisiPaginaState extends State<GuidaCondivisiPagina> {
  late var _ruolo = widget.ruolo;

  static const _proprietario = [
    '**Apri il portafoglio** che vuoi condividere. Oppure creane uno nuovo '
        'e accendi «Condiviso».',
    'Tocca **☰ › Condividi con altre persone** e scrivi l\'**indirizzo '
        'Gmail** dell\'altra persona.',
    'Se Google lo chiede, **scegli il tuo account e consenti**: WalleCy vede '
        'solo i file che crea lei, non il resto del tuo Drive.',
    'All\'altra persona arriva un\'**email d\'invito**. Se non la trova, nella '
        'scheda «Portafoglio condiviso» tocca **Copia il link d\'invito** e '
        'mandalo su WhatsApp o SMS.',
    'Ha **un\'ora** per accettare. Quando entra, nella scheda la vedi come '
        '«Membro». Fatto!',
  ];

  static const _membro = [
    '**Installa WalleCy** e crea il tuo archivio, se non l\'hai già.',
    'Dal telefono **apri l\'email d\'invito** (o il link che ti hanno '
        'mandato), tocca «Apri l\'invito» e poi **«Apri in WalleCy»**. Sul PC: '
        'Impostazioni › Portafogli condivisi › **«Ho un link d\'invito»** e '
        'incolla il link.',
    'In **Nuovi inviti** tocca **«Accetta»**.',
    'Nella finestra di Google **scegli il tuo account** e **seleziona tutti i '
        'file proposti**, poi conferma.',
    'Dopo pochi secondi il portafoglio compare in **Panoramica**. Se nei '
        'portafogli condivisi resta «in arrivo», **toccalo** e scegli i file '
        'che mancano.',
  ];

  static const _dopo = [
    'Le modifiche arrivano agli altri **entro un minuto**. Per vederle subito '
        'tocca **⟳** in alto o trascina la pagina verso il basso.',
    'Ognuno modifica le **voci che ha inserito**; il proprietario può '
        'modificarle tutte.',
    'Per smettere: nella scheda «Portafoglio condiviso» **Interrompi la '
        'condivisione** (proprietario) o **Esci dalla condivisione** (membro). '
        'Il portafoglio resta, come un portafoglio normale.',
  ];

  static const _problemi = [
    '**L\'email non arriva**: il proprietario tocca «Copia il link d\'invito» '
        'e lo manda in un messaggio.',
    '**Invito scaduto** (oltre un\'ora): il proprietario tocca «Invita di '
        'nuovo».',
    '**Google dice «accesso bloccato»**: finché WalleCy è «in prova» presso '
        'Google, l\'account del membro va aggiunto tra gli utenti di test '
        'dell\'app.',
    '**⟳ è rossa**: toccala e, se Google lo chiede, consenti di nuovo '
        'l\'accesso.',
  ];

  @override
  Widget build(BuildContext context) {
    final passi = _ruolo == RuoloGuida.proprietario ? _proprietario : _membro;
    return Scaffold(
      appBar: AppBar(title: const Text('Portafogli condivisi: come si fa')),
      body: LayoutBuilder(
        builder: (context, vincoli) => ListView(
          padding: marginiPagina(vincoli),
          children: [
            SegmentedButton<RuoloGuida>(
              segments: const [
                ButtonSegment(
                  value: RuoloGuida.proprietario,
                  icon: Icon(Icons.star_outline),
                  label: Text('Condivido io'),
                ),
                ButtonSegment(
                  value: RuoloGuida.membro,
                  icon: Icon(Icons.mail_outline),
                  label: Text('Mi hanno invitato'),
                ),
              ],
              selected: {_ruolo},
              onSelectionChanged: (s) => setState(() => _ruolo = s.single),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final (i, testo) in passi.indexed)
                      _Passo(numero: i + 1, testo: testo),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Sezione(icona: Icons.sync, titolo: 'Dopo', righe: _dopo),
            const SizedBox(height: 16),
            _Sezione(
              icona: Icons.help_outline,
              titolo: 'Se qualcosa non va',
              righe: _problemi,
            ),
          ],
        ),
      ),
    );
  }
}

/// Un passo numerato.
class _Passo extends StatelessWidget {
  const _Passo({required this.numero, required this.testo});

  final int numero;
  final String testo;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: schema.primary,
            child: Text(
              '$numero',
              style: TextStyle(color: schema.onPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TestoConGrassetti(testo),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un riquadro con un titolo e qualche punto.
class _Sezione extends StatelessWidget {
  const _Sezione({
    required this.icona,
    required this.titolo,
    required this.righe,
  });

  final IconData icona;
  final String titolo;
  final List<String> righe;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icona),
              const SizedBox(width: 12),
              Text(titolo, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          for (final r in righe)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: TestoConGrassetti(r)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Testo con le parti tra `**` in grassetto.
class TestoConGrassetti extends StatelessWidget {
  const TestoConGrassetti(this.testo, {super.key});

  final String testo;

  @override
  Widget build(BuildContext context) {
    final parti = testo.split('**');
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, p) in parti.indexed)
            TextSpan(
              text: p,
              style: i.isOdd
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
        ],
      ),
    );
  }
}
