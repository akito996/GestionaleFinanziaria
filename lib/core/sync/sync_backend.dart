import 'dart:typed_data';

/// Un file nello spazio remoto (es. un pacchetto di modifiche cifrato).
class FileRemoto {
  const FileRemoto({
    required this.id,
    required this.nome,
    this.proprieta = const {},
  });

  final String id;
  final String nome;

  /// Piccole etichette in chiaro (tipo, dispositivo, sequenza): mai dati.
  final Map<String, String> proprieta;
}

/// Dove finiscono i dati cifrati da sincronizzare (ADR-001).
///
/// Oggi: Google Drive, cartella nascosta `appDataFolder`. Domani, senza
/// riscrivere l'app: Cloudflare Workers + D1 (Scenario 7) o altro.
/// L'interfaccia tratta solo file di byte già cifrati: il formato e la logica
/// della sincronizzazione sono in `Sincronizzatore`.
abstract interface class SyncBackend {
  /// Tutti i file dell'app nello spazio remoto.
  Future<List<FileRemoto>> elenca();

  Future<Uint8List> scarica(String id);

  Future<FileRemoto> crea(
    String nome,
    Uint8List dati, {
    Map<String, String> proprieta = const {},
  });

  /// Sostituisce il contenuto (es. il keyring dopo un cambio password).
  Future<void> aggiorna(String id, Uint8List dati);

  /// Cambia nome (es. per mettere da parte un archivio senza cancellarlo).
  Future<void> rinomina(String id, String nome);

  Future<void> elimina(String id);
}
