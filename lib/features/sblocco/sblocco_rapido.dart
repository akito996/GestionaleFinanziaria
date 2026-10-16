import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../../core/sicurezza/cassaforte.dart';
import '../../core/sicurezza/sicurezza_dispositivo.dart';
import '../comuni/avvisi.dart';
import '../comuni/blocco_automatico.dart';
import '../comuni/errori.dart';

bool get _suWindows => defaultTargetPlatform == TargetPlatform.windows;

/// "Windows Hello", "impronta, viso o PIN", "impronta" (Android 10 e prima).
String nomeSbloccoRapido(SicurezzaDispositivo sicurezza) => _suWindows
    ? 'Windows Hello'
    : sicurezza.conPin
    ? 'impronta, viso o PIN'
    : 'impronta';

/// Testo del pulsante nella pagina di sblocco.
String pulsanteSbloccoRapido(SicurezzaDispositivo sicurezza) =>
    'Sblocca con ${nomeSbloccoRapido(sicurezza)}';

IconData get iconaSbloccoRapido =>
    _suWindows ? Icons.face_unlock_outlined : Icons.fingerprint;

/// Mentre si aspetta la verifica (la finestra di Windows Hello a volte
/// resta dietro l'app).
String testoInVerifica(SicurezzaDispositivo sicurezza) =>
    'In attesa della verifica: completala nella finestra di '
    '${nomeSbloccoRapido(sicurezza)}.'
    '${_suWindows ? ' Se non la vedi, cercala nella barra delle applicazioni.' : ''}';

/// Cosa manca al dispositivo per lo sblocco rapido (`null` se è pronto).
String? mancaPerSbloccoRapido(SicurezzaDispositivo sicurezza) =>
    switch (sicurezza.disponibilita) {
      DisponibilitaCassaforte.pronta => null,
      DisponibilitaCassaforte.nessunMetodo =>
        _suWindows
            ? 'Prima configura Windows Hello (PIN, viso o impronta) nelle '
                  'Impostazioni di Windows, in Account › Opzioni di accesso.'
            : 'Prima imposta un\'impronta, il viso o un PIN nelle '
                  'impostazioni del telefono, alla voce Sicurezza.',
      DisponibilitaCassaforte.nonSupportata =>
        'Questo dispositivo non lo permette.',
    };

/// Attiva lo sblocco rapido (chiede subito la verifica). `true` se attivo.
///
/// Ogni esito si vede: attivo, annullato o l'errore con il motivo.
/// [dallaProposta]: se non si attiva, l'avviso ricorda che si può fare dalle
/// Impostazioni (la proposta non ricompare).
Future<bool> attivaSbloccoRapido(
  BuildContext context,
  Sessione sessione, {
  bool dallaProposta = false,
}) async {
  final messaggi = ScaffoldMessenger.of(context);
  final dopo = dallaProposta ? ' $_quandoVuoi' : '';
  String esito;
  var riuscito = false;
  try {
    // Sul telefono il PIN si chiede in una schermata di sistema.
    await senzaBloccoAutomatico(sessione.attivaSbloccoRapido);
    riuscito = true;
    esito =
        'Sblocco con ${nomeSbloccoRapido(sessione.sicurezza)} attivo. Ogni '
        '14 giorni ti chiediamo la password, così non la dimentichi.';
  } on VerificaAnnullata {
    esito = 'Verifica annullata: lo sblocco rapido resta spento.$dopo';
  } on VerificaBloccata {
    esito = 'Troppi tentativi: riprova tra poco.$dopo';
  } on ChiaveDispositivoAnnullata {
    esito =
        'Sblocco rapido non attivato: il dispositivo ha rifiutato la '
        'chiave. Riprova.$dopo';
  } on ErroreCassaforte catch (e) {
    esito = 'Sblocco rapido non attivato (${e.dettaglio}).$dopo';
  } catch (e, stack) {
    // Mai in silenzio: i dettagli tecnici dicono cosa è successo.
    if (context.mounted) {
      await mostraErroreImprevisto(context, e, stack);
    }
    return false;
  }
  messaggi
    ..clearSnackBars()
    ..showSnackBar(avviso(content: Text(esito)));
  return riuscito;
}

const _quandoVuoi = 'Puoi attivarlo quando vuoi da Impostazioni › Sicurezza.';

/// Dopo la password, una volta sola: "Vuoi sbloccare più in fretta?".
///
/// La proposta conta come fatta appena compare: chiusa con Indietro, con
/// "Non ora" o con la verifica annullata non ricompare a ogni sblocco.
Future<void> proponiSbloccoRapido(
  BuildContext context,
  Sessione sessione,
) async {
  final sicurezza = sessione.sicurezza;
  await sicurezza.segnaPropostaFatta();
  if (!context.mounted) {
    return;
  }
  final nome = nomeSbloccoRapido(sicurezza);
  final scelta = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: Icon(iconaSbloccoRapido),
      title: const Text('Sblocco più veloce'),
      content: Text(
        'Vuoi aprire l\'archivio con $nome invece di scrivere la password?\n\n'
        'La password resta valida e ogni 14 giorni te la chiediamo, così non '
        'la dimentichi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Non ora'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Attiva'),
        ),
      ],
    ),
  );
  if (!context.mounted || sessione.fase != FaseSessione.sbloccata) {
    return;
  }
  if (scelta ?? false) {
    await attivaSbloccoRapido(context, sessione, dallaProposta: true);
    return;
  }
  // "Non ora" o Indietro.
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(avviso(content: const Text(_quandoVuoi)));
}
