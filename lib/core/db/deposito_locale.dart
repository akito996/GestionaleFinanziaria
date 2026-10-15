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
    final cartella = Directory(_unisci(base.path, 'archivio'));
    final appData = Platform.environment['APPDATA'];
    if (Platform.isWindows && appData != null) {
      await copiaArchivioPrecedente(
        destinazione: cartella,
        origini: [
          for (final vecchia in cartellePrecedentiWindows)
            Directory(_unisci(_unisci(appData, vecchia), 'archivio')),
        ],
      );
    }
    return DepositoLocale(cartella);
  }

  /// Su Windows la cartella dei dati dipende da editore e nome del programma
  /// (`%APPDATA%\<editore>\<nome>`). Quelle usate in passato, dalla più recente.
  static const cartellePrecedentiWindows = [
    r'io.github.akito996\GestionaleFinanziaria',
  ];

  /// Dopo un cambio di nome (ADR-018): se qui non c'è ancora un archivio,
  /// copia quello della prima [origini] che ne ha uno. L'originale resta
  /// dov'era: non si cancella mai nulla. La copia passa da una cartella
  /// temporanea, così un'interruzione non lascia mai un archivio a metà.
  static Future<bool> copiaArchivioPrecedente({
    required Directory destinazione,
    required List<Directory> origini,
  }) async {
    if (File(_unisci(destinazione.path, 'keyring.bin')).existsSync()) {
      return false;
    }
    for (final origine in origini) {
      if (!File(_unisci(origine.path, 'keyring.bin')).existsSync()) {
        continue;
      }
      final temporanea = Directory('${destinazione.path}.copia');
      if (temporanea.existsSync()) {
        await temporanea.delete(recursive: true);
      }
      await temporanea.create(recursive: true);
      await for (final voce in origine.list()) {
        if (voce is File) {
          final nome = voce.uri.pathSegments.last;
          await voce.copy(_unisci(temporanea.path, nome));
        }
      }
      if (destinazione.existsSync()) {
        // Cartella senza archivio (es. creata e lasciata vuota): si mette da parte.
        final istante = DateTime.now().toUtc().millisecondsSinceEpoch;
        await destinazione.rename('${destinazione.path}.vuota-$istante');
      }
      await temporanea.rename(destinazione.path);
      return true;
    }
    return false;
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
