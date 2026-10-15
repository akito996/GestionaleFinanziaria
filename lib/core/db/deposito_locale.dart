import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// File dell'archivio sul dispositivo: `keyring.bin` (chiave dei dati avvolta)
/// e `archivio.db` (database SQLCipher). Nessun file contiene dati in chiaro.
class DepositoLocale {
  DepositoLocale(this.cartella);

  /// Cartella privata dell'app (su Windows `%APPDATA%\...`, su Android la sandbox dell'app).
  static Future<DepositoLocale> predefinito() async {
    final base = await getApplicationSupportDirectory();
    return DepositoLocale(Directory(_unisci(base.path, 'archivio')));
  }

  final Directory cartella;

  File get fileKeyring => File(_unisci(cartella.path, 'keyring.bin'));
  File get fileArchivio => File(_unisci(cartella.path, 'archivio.db'));

  /// Sblocco rapido e blocco automatico di questo dispositivo (mai sincronizzato).
  File get fileSicurezza => File(_unisci(cartella.path, 'sicurezza.json'));

  Future<bool> esisteKeyring() async => fileKeyring.existsSync();

  Future<Uint8List> leggiKeyring() => fileKeyring.readAsBytes();

  /// Scrittura atomica: prima un file temporaneo, poi la sostituzione.
  /// Un'interruzione a metà non lascia mai un keyring danneggiato.
  Future<void> scriviKeyring(Uint8List byte) async {
    await cartella.create(recursive: true);
    final temporaneo = File('${fileKeyring.path}.tmp');
    await temporaneo.writeAsBytes(byte, flush: true);
    await temporaneo.rename(fileKeyring.path);
  }

  /// Database senza keyring (es. keyring cancellato a mano): non si potrebbe più aprire.
  /// Non si cancella mai nulla: il file viene rinominato e messo da parte.
  Future<File?> metteDaParteArchivioOrfano() async {
    if (!fileArchivio.existsSync()) {
      return null;
    }
    final istante = DateTime.now().toUtc().millisecondsSinceEpoch;
    return fileArchivio.rename('${fileArchivio.path}.orfano-$istante');
  }

  /// Prima di scaricare un archivio da Google Drive al posto di questo: database
  /// e keyring vengono rinominati e messi da parte, mai cancellati.
  Future<void> metteDaParteArchivio() async {
    final istante = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final file in [fileArchivio, fileKeyring]) {
      if (file.existsSync()) {
        await file.rename('${file.path}.sostituito-$istante');
      }
    }
  }

  static String _unisci(String a, String b) => '$a${Platform.pathSeparator}$b';
}
