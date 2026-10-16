import 'package:drift/drift.dart';

import 'archivio.dart';
import 'orologio.dart';

/// Cosa è collegato a un portafoglio, da mostrare prima di eliminarlo.
class CollegamentiPortafoglio {
  const CollegamentiPortafoglio({
    required this.movimenti,
    required this.programmati,
    required this.prestiti,
    required this.obiettivi,
    this.carta,
  });

  final int movimenti;

  /// Pagamenti programmati (voci, rate, entrate) che usano il portafoglio.
  final int programmati;
  final int prestiti;
  final int obiettivi;

  /// Nome della carta di credito collegata (è la carta o il conto che la
  /// paga): si gestisce dalla sezione Carte, qui non si elimina.
  final String? carta;

  int get altri => programmati + prestiti + obiettivi;
}

/// Eliminazione di un portafoglio (cancellazione morbida, annullabile):
/// i movimenti scelti si eliminano, gli altri passano a un altro portafoglio;
/// pagamenti programmati, prestiti e obiettivi collegati passano a quel
/// portafoglio o restano senza.
class EliminazionePortafoglio {
  EliminazionePortafoglio(this._db, this._orologio);

  final Archivio _db;
  final OrologioLogico _orologio;

  Future<CollegamentiPortafoglio> collegamenti(String id) async {
    final movimenti = await _movimenti(id);
    final programmati =
        await (_db.select(_db.pianificazioni)..where(
              (p) =>
                  p.eliminato.equals(false) &
                  (p.portafoglioId.equals(id) | p.destinazioneId.equals(id)),
            ))
            .get();
    final prestiti =
        await (_db.select(_db.prestiti)..where(
              (p) => p.eliminato.equals(false) & p.portafoglioId.equals(id),
            ))
            .get();
    final obiettivi =
        await (_db.select(_db.obiettivi)..where(
              (o) => o.eliminato.equals(false) & o.portafoglioId.equals(id),
            ))
            .get();
    final carta =
        await (_db.select(_db.carteCredito)..where(
              (c) =>
                  c.eliminato.equals(false) &
                  (c.portafoglioId.equals(id) | c.contoAddebitoId.equals(id)),
            ))
            .get();
    final cartaId = carta.firstOrNull?.portafoglioId;
    final nomeCarta = cartaId == null
        ? null
        : (await (_db.select(
            _db.portafogli,
          )..where((p) => p.id.equals(cartaId))).getSingleOrNull())?.nome;
    return CollegamentiPortafoglio(
      movimenti: movimenti.length,
      programmati: programmati.length,
      prestiti: prestiti.length,
      obiettivi: obiettivi.length,
      carta: carta.isEmpty ? null : (nomeCarta ?? 'Carta di credito'),
    );
  }

  Future<List<Movimento>> _movimenti(String id) =>
      (_db.select(_db.movimenti)..where(
            (m) =>
                m.eliminato.equals(false) &
                (m.portafoglioId.equals(id) |
                    m.portafoglioDestinazioneId.equals(id)),
          ))
          .get();

  /// Elimina il portafoglio [id]. I movimenti in [daEliminare] si eliminano;
  /// gli altri vanno in [spostaIn] (obbligatorio se ne restano). Restituisce
  /// come rimettere tutto com'era.
  Future<Future<void> Function()> elimina(
    String id, {
    Set<String> daEliminare = const {},
    String? spostaIn,
  }) async {
    if (spostaIn == id) {
      throw ArgumentError.value(
        spostaIn,
        'spostaIn',
        'è lo stesso portafoglio',
      );
    }
    final annulla = <Future<void> Function()>[];
    await _db.transaction(() async {
      final collegati = await collegamenti(id);
      if (collegati.carta != null) {
        throw StateError('Portafoglio usato dalla carta ${collegati.carta}');
      }
      final portafoglio = await (_db.select(
        _db.portafogli,
      )..where((p) => p.id.equals(id))).getSingle();
      if (spostaIn != null) {
        final destinazione = await (_db.select(
          _db.portafogli,
        )..where((p) => p.id.equals(spostaIn))).getSingle();
        if (destinazione.valuta != portafoglio.valuta) {
          throw ArgumentError.value(spostaIn, 'spostaIn', 'valuta diversa');
        }
      }

      for (final m in await _movimenti(id)) {
        final origine = m.portafoglioId == id ? spostaIn : m.portafoglioId;
        final arrivo = m.portafoglioDestinazioneId == id
            ? spostaIn
            : m.portafoglioDestinazioneId;
        // Un trasferimento verso il portafoglio che lo accoglie non ha più
        // senso: si elimina anche lui.
        final elimina =
            daEliminare.contains(m.id) || (arrivo != null && arrivo == origine);
        if (!elimina && origine == null) {
          throw ArgumentError('Scegli dove spostare i movimenti che restano');
        }
        await _movimento(
          m.id,
          elimina
              ? const MovimentiCompanion(eliminato: Value(true))
              : MovimentiCompanion(
                  portafoglioId: Value(origine!),
                  portafoglioDestinazioneId: Value(arrivo),
                ),
        );
        annulla.add(
          () => _movimento(
            m.id,
            MovimentiCompanion(
              eliminato: const Value(false),
              portafoglioId: Value(m.portafoglioId),
              portafoglioDestinazioneId: Value(m.portafoglioDestinazioneId),
            ),
          ),
        );
      }

      final programmati =
          await (_db.select(_db.pianificazioni)..where(
                (p) =>
                    p.eliminato.equals(false) &
                    (p.portafoglioId.equals(id) | p.destinazioneId.equals(id)),
              ))
              .get();
      for (final p in programmati) {
        await _pianificazione(
          p.id,
          PianificazioniCompanion(
            portafoglioId: Value(
              p.portafoglioId == id ? spostaIn : p.portafoglioId,
            ),
            destinazioneId: Value(
              p.destinazioneId == id ? spostaIn : p.destinazioneId,
            ),
          ),
        );
        annulla.add(
          () => _pianificazione(
            p.id,
            PianificazioniCompanion(
              portafoglioId: Value(p.portafoglioId),
              destinazioneId: Value(p.destinazioneId),
            ),
          ),
        );
      }

      for (final p
          in await (_db.select(_db.prestiti)..where(
                (p) => p.eliminato.equals(false) & p.portafoglioId.equals(id),
              ))
              .get()) {
        await _prestito(p.id, spostaIn);
        annulla.add(() => _prestito(p.id, p.portafoglioId));
      }

      for (final o
          in await (_db.select(_db.obiettivi)..where(
                (o) => o.eliminato.equals(false) & o.portafoglioId.equals(id),
              ))
              .get()) {
        await _obiettivo(o.id, spostaIn);
        annulla.add(() => _obiettivo(o.id, o.portafoglioId));
      }

      await _portafoglio(id, eliminato: true);
      annulla.add(() => _portafoglio(id, eliminato: false));
    });
    return () => _db.transaction(() async {
      for (final passo in annulla.reversed) {
        await passo();
      }
    });
  }

  Future<void> _movimento(String id, MovimentiCompanion valori) =>
      (_db.update(_db.movimenti)..where((m) => m.id.equals(id))).write(
        valori.copyWith(aggiornatoIl: Value(_orologio.adesso())),
      );

  Future<void> _pianificazione(String id, PianificazioniCompanion valori) =>
      (_db.update(_db.pianificazioni)..where((p) => p.id.equals(id))).write(
        valori.copyWith(aggiornatoIl: Value(_orologio.adesso())),
      );

  Future<void> _prestito(String id, String? portafoglioId) =>
      (_db.update(_db.prestiti)..where((p) => p.id.equals(id))).write(
        PrestitiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          portafoglioId: Value(portafoglioId),
        ),
      );

  Future<void> _obiettivo(String id, String? portafoglioId) =>
      (_db.update(_db.obiettivi)..where((o) => o.id.equals(id))).write(
        ObiettiviCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          portafoglioId: Value(portafoglioId),
        ),
      );

  Future<void> _portafoglio(String id, {required bool eliminato}) =>
      (_db.update(_db.portafogli)..where((p) => p.id.equals(id))).write(
        PortafogliCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          eliminato: Value(eliminato),
        ),
      );
}
