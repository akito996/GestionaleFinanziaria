import 'dart:typed_data';

/// Pacchetto di modifiche cifrato, così come sta sul backend remoto.
/// Il backend non vede mai dati in chiaro: [datiCifrati] è già un blob versionato.
class PacchettoRemoto {
  const PacchettoRemoto({
    required this.dispositivoId,
    required this.sequenza,
    required this.datiCifrati,
  });

  /// Dispositivo che l'ha scritto (ogni dispositivo scrive solo i propri pacchetti).
  final String dispositivoId;

  /// Numero progressivo per dispositivo (anti-replay, insieme all'AAD).
  final int sequenza;

  final Uint8List datiCifrati;
}

/// Novità arrivate dal backend dopo un certo punto.
class Novita {
  const Novita({required this.pacchetti, required this.cursore});

  final List<PacchettoRemoto> pacchetti;

  /// Da passare alla chiamata successiva di [SyncBackend.novitaDopo].
  final String cursore;
}

/// Dove finiscono i dati cifrati da sincronizzare (ADR-001).
///
/// Oggi: Google Drive, cartella `appDataFolder`. Domani, senza riscrivere l'app:
/// Cloudflare Workers + D1 (Scenario 7) o altro. L'interfaccia tratta solo byte cifrati.
abstract interface class SyncBackend {
  /// Collega l'account dell'utente (consenso OAuth sul dispositivo).
  Future<void> collega();

  Future<void> scollega();

  /// `keyring.bin`: chiave dei dati avvolta da password e Recovery Key. `null` se non esiste.
  Future<Uint8List?> leggiKeyring();

  Future<void> scriviKeyring(Uint8List datiCifrati);

  /// Scrive un pacchetto di modifiche di questo dispositivo.
  Future<void> scriviPacchetto(PacchettoRemoto pacchetto);

  /// Pacchetti nuovi dopo [cursore] (`null` = dall'inizio), di tutti i dispositivi.
  Future<Novita> novitaDopo(String? cursore);

  /// Snapshot completo cifrato, per compattare la storia dei pacchetti.
  Future<void> scriviSnapshot(DateTime data, Uint8List datiCifrati);

  /// Ultimo snapshot disponibile, `null` se non ce ne sono.
  Future<Uint8List?> leggiUltimoSnapshot();
}
