import 'archivio.dart';
import 'id.dart';

/// Orologio logico (semplificazione di HLC) per la colonna `aggiornato_il`.
///
/// Valore = microsecondi (17 cifre, crescenti anche se l'ora del PC torna indietro)
/// + id del dispositivo. Le stringhe si confrontano in ordine alfabetico: la modifica
/// più recente vince (ADR-001). Con la sincronizzazione l'orologio "vede" quelli
/// degli altri dispositivi ([ricevi]): una modifica fatta qui dopo averne
/// ricevuta una è sempre più recente, anche se l'ora del dispositivo è indietro.
class OrologioLogico {
  OrologioLogico._(this._dispositivo, this._ultimo);

  static const _chiaveDispositivo = 'dispositivo_id';

  /// Legge (o crea al primo uso) l'id di questo dispositivo, salvato in `impostazioni`.
  static Future<OrologioLogico> carica(Archivio db) async {
    final riga = await (db.select(
      db.impostazioni,
    )..where((i) => i.chiave.equals(_chiaveDispositivo))).getSingleOrNull();
    var dispositivo = riga?.valore;
    if (dispositivo == null) {
      dispositivo = nuovoId();
      await db
          .into(db.impostazioni)
          .insert(
            ImpostazioniCompanion.insert(
              chiave: _chiaveDispositivo,
              valore: dispositivo,
            ),
          );
    }
    return OrologioLogico._(dispositivo, 0);
  }

  final String _dispositivo;
  int _ultimo;

  String get dispositivoId => _dispositivo;

  String adesso() {
    final ora = DateTime.now().toUtc().microsecondsSinceEpoch;
    _ultimo = ora > _ultimo ? ora : _ultimo + 1;
    return '${_ultimo.toString().padLeft(17, '0')}-$_dispositivo';
  }

  /// Un orologio arrivato da un altro dispositivo: i prossimi saranno dopo.
  void ricevi(String orologio) {
    final tempo = tempoDi(orologio);
    if (tempo != null && tempo > _ultimo) {
      _ultimo = tempo;
    }
  }

  /// La parte numerica (microsecondi) di un orologio, `null` se non valido.
  static int? tempoDi(String orologio) {
    final trattino = orologio.indexOf('-');
    return int.tryParse(
      trattino < 0 ? orologio : orologio.substring(0, trattino),
    );
  }
}
