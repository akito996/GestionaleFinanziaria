import 'package:drift/drift.dart';

import '../ricorrenza.dart';
import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'osservazione.dart';
import 'pianificatore.dart';
import 'tabelle.dart';

/// Stato di una carta per le schermate.
class CartaConStato {
  const CartaConStato({
    required this.carta,
    required this.portafoglio,
    required this.conto,
    required this.prossimoAddebito,
    required this.chiusura,
    required this.daAddebitare,
    required this.debitoTotale,
  });

  final CartaCredito carta;
  final Portafoglio portafoglio;
  final Portafoglio conto;

  /// Prossimo giorno in cui il conto viene addebitato.
  final DateTime prossimoAddebito;

  /// Ultimo giorno di spese incluse nel prossimo addebito.
  final DateTime chiusura;

  /// Spese già registrate che verranno addebitate il [prossimoAddebito].
  final int daAddebitare;

  /// Tutto il debito della carta a oggi (anche le spese del periodo successivo).
  final int debitoTotale;

  /// Quota del plafond usata (0..1), se il plafond è impostato.
  double? get usoPlafond {
    final plafond = carta.plafondMinimo;
    if (plafond == null || plafond <= 0) {
      return null;
    }
    return (debitoTotale / plafond).clamp(0.0, 1.0);
  }
}

/// Carte di credito: spese nel portafoglio della carta, addebito mensile
/// automatico sul conto collegato (pagamento programmato con origine `carta`).
class CarteCreditoServizio {
  CarteCreditoServizio(
    this._db,
    this._orologio,
    this._pianificatore, {
    DateTime Function()? adesso,
  }) : _adesso = adesso ?? DateTime.now {
    _pianificatore.registraCalcolo(OriginePianificazione.carta, (
      p,
      data,
    ) async {
      final carta = p.origineId == null ? null : await _carta(p.origineId!);
      return carta == null ? null : _debitoAl(carta, chiusuraPer(carta, data));
    });
  }

  final Archivio _db;
  final OrologioLogico _orologio;
  final Pianificatore _pianificatore;
  final DateTime Function() _adesso;

  /// Ultimo giorno di spese incluse nell'addebito del giorno [addebito].
  static DateTime chiusuraPer(CartaCredito carta, DateTime addebito) {
    final mesePrecedente = DateTime(addebito.year, addebito.month - 1);
    if (carta.giornoChiusura <= 0) {
      return DateTime(addebito.year, addebito.month, 0);
    }
    final ultimo = DateTime(
      mesePrecedente.year,
      mesePrecedente.month + 1,
      0,
    ).day;
    return DateTime(
      mesePrecedente.year,
      mesePrecedente.month,
      carta.giornoChiusura <= ultimo ? carta.giornoChiusura : ultimo,
    );
  }

  /// Crea la carta: un portafoglio "Carta di credito" e l'addebito mensile.
  Future<String> crea({
    required String nome,
    required String contoAddebitoId,
    required int giornoAddebito,
    int giornoChiusura = 0,
    int? plafond,
  }) async {
    final conto = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(contoAddebitoId))).getSingle();
    final tipo =
        await (_db.select(_db.definizioniTipo)..where(
              (t) =>
                  t.ambito.equals(AmbitoTipo.portafoglio) &
                  t.nome.equals(tipoCartaDiCredito),
            ))
            .getSingle();
    final id = nuovoId();
    final portafoglioId = nuovoId();
    await _db.transaction(() async {
      await _db
          .into(_db.portafogli)
          .insert(
            PortafogliCompanion.insert(
              id: portafoglioId,
              aggiornatoIl: _orologio.adesso(),
              tipoId: tipo.id,
              nome: nome.trim(),
              valuta: conto.valuta,
              ordine: const Value(500),
            ),
          );
      await _db
          .into(_db.carteCredito)
          .insert(
            CarteCreditoCompanion.insert(
              id: id,
              aggiornatoIl: _orologio.adesso(),
              portafoglioId: portafoglioId,
              contoAddebitoId: contoAddebitoId,
              giornoAddebito: giornoAddebito,
              giornoChiusura: Value(giornoChiusura),
              plafondMinimo: Value(plafond),
            ),
          );
    });
    await _aggiornaAddebito(id);
    return id;
  }

  Future<void> modifica(
    String id, {
    required String nome,
    required String contoAddebitoId,
    required int giornoAddebito,
    int giornoChiusura = 0,
    int? plafond,
  }) async {
    final carta = (await _carta(id))!;
    await _db.transaction(() async {
      await (_db.update(_db.carteCredito)..where((c) => c.id.equals(id))).write(
        CarteCreditoCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          contoAddebitoId: Value(contoAddebitoId),
          giornoAddebito: Value(giornoAddebito),
          giornoChiusura: Value(giornoChiusura),
          plafondMinimo: Value(plafond),
        ),
      );
      await (_db.update(
        _db.portafogli,
      )..where((p) => p.id.equals(carta.portafoglioId))).write(
        PortafogliCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          nome: Value(nome.trim()),
        ),
      );
    });
    await _aggiornaAddebito(id);
  }

  /// Archivia la carta e ferma gli addebiti (i movimenti restano).
  Future<void> archivia(String id, {bool archiviata = true}) async {
    final carta = (await _carta(id))!;
    await (_db.update(_db.carteCredito)..where((c) => c.id.equals(id))).write(
      CarteCreditoCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        archiviata: Value(archiviata),
      ),
    );
    await (_db.update(
      _db.portafogli,
    )..where((p) => p.id.equals(carta.portafoglioId))).write(
      PortafogliCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        archiviato: Value(archiviata),
      ),
    );
    await (_db.update(_db.pianificazioni)..where(
          (p) =>
              p.origine.equals(OriginePianificazione.carta) &
              p.origineId.equals(id),
        ))
        .write(
          PianificazioniCompanion(
            aggiornatoIl: Value(_orologio.adesso()),
            attiva: Value(!archiviata),
          ),
        );
  }

  /// Carte attive con lo stato (aggiornato quando cambiano movimenti o carte).
  Stream<List<CartaConStato>> osserva() => _db
      .customSelect(
        'SELECT 1 AS osserva_carte_credito', // testo univoco: drift condivide le query uguali
        readsFrom: {_db.carteCredito, _db.portafogli, _db.movimenti},
      )
      .watch()
      .ricalcola((_) => stati());

  Future<List<CartaConStato>> stati() async {
    final carte =
        await (_db.select(_db.carteCredito)..where(
              (c) => c.eliminato.equals(false) & c.archiviata.equals(false),
            ))
            .get();
    final portafogli = {
      for (final p in await _db.select(_db.portafogli).get()) p.id: p,
    };
    final oggi = _oggi();
    final risultato = <CartaConStato>[];
    for (final carta in carte) {
      final prossimo = _regola(carta).prossima(oggi)!;
      final chiusura = chiusuraPer(carta, prossimo);
      risultato.add(
        CartaConStato(
          carta: carta,
          portafoglio: portafogli[carta.portafoglioId]!,
          conto: portafogli[carta.contoAddebitoId]!,
          prossimoAddebito: prossimo,
          chiusura: chiusura,
          daAddebitare: await _debitoAl(carta, chiusura),
          debitoTotale: await _debitoAl(carta, DateTime(9999)),
        ),
      );
    }
    risultato.sort((a, b) => a.portafoglio.nome.compareTo(b.portafoglio.nome));
    return risultato;
  }

  /// Carte che addebitano il conto [contoId] (per l'avviso nel portafoglio).
  Stream<List<CartaConStato>> osservaAddebitiSu(String contoId) =>
      osserva().map(
        (carte) =>
            carte.where((c) => c.carta.contoAddebitoId == contoId).toList(),
      );

  /// Carta di un portafoglio (se quel portafoglio è una carta).
  Future<CartaCredito?> perPortafoglio(String portafoglioId) =>
      (_db.select(_db.carteCredito)..where(
            (c) =>
                c.portafoglioId.equals(portafoglioId) &
                c.eliminato.equals(false),
          ))
          .getSingleOrNull();

  // ------------------------------------------------------------- interni

  DateTime _oggi() {
    final a = _adesso();
    return DateTime(a.year, a.month, a.day);
  }

  Ricorrenza _regola(CartaCredito carta) {
    final oggi = _oggi();
    return Ricorrenza(
      inizio: DateTime(oggi.year, oggi.month - 1, carta.giornoAddebito),
    );
  }

  Future<CartaCredito?> _carta(String id) => (_db.select(
    _db.carteCredito,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Debito della carta considerando i movimenti fino a [chiusura] compresa
  /// (spese meno rimborsi e addebiti già fatti). Mai negativo.
  Future<int> _debitoAl(CartaCredito carta, DateTime chiusura) async {
    final riga = await _db
        .customSelect(
          '''
          SELECT p.saldo_iniziale_minimo
            + COALESCE((SELECT SUM(CASE t.effetto
                  WHEN 'entrata' THEN m.importo_minimo
                  WHEN 'uscita' THEN -m.importo_minimo
                  WHEN 'trasferimento' THEN -m.importo_minimo
                  ELSE 0 END)
                FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
                WHERE m.portafoglio_id = p.id AND m.eliminato = 0
                  AND m.data <= ?), 0)
            + COALESCE((SELECT SUM(m.importo_minimo)
                FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
                WHERE m.portafoglio_destinazione_id = p.id AND m.eliminato = 0
                  AND t.effetto = 'trasferimento' AND m.data <= ?), 0) AS saldo
          FROM portafogli p WHERE p.id = ?
          ''',
          variables: [
            Variable.withString(Contabilita.giorno(chiusura)),
            Variable.withString(Contabilita.giorno(chiusura)),
            Variable.withString(carta.portafoglioId),
          ],
        )
        .getSingle();
    final saldo = riga.read<int>('saldo');
    return saldo < 0 ? -saldo : 0;
  }

  /// Pagamento programmato: ogni mese, nel giorno di addebito, trasferimento
  /// dal conto alla carta per l'importo del periodo chiuso.
  Future<void> _aggiornaAddebito(String id) async {
    final carta = (await _carta(id))!;
    final portafoglio = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(carta.portafoglioId))).getSingle();
    final trasferimento =
        await (_db.select(_db.definizioniTipo)..where(
              (t) =>
                  t.ambito.equals(AmbitoTipo.movimento) &
                  t.effetto.equals(EffettoSaldo.trasferimento) &
                  t.diSistema.equals(true),
            ))
            .getSingle();
    final oggi = _oggi();
    // Primo addebito: il prossimo giorno di addebito da oggi in poi.
    final primo = Ricorrenza(
      inizio: DateTime(oggi.year, oggi.month - 1, carta.giornoAddebito),
    ).prossima(oggi)!;
    await _pianificatore.salva(
      DatiPianificazione(
        origine: OriginePianificazione.carta,
        origineId: id,
        ricorrenza: Ricorrenza(inizio: primo),
        portafoglioId: carta.contoAddebitoId,
        destinazioneId: carta.portafoglioId,
        tipoId: trasferimento.id,
        descrizione: 'Addebito carta ${portafoglio.nome}',
        valuta: portafoglio.valuta,
      ),
    );
  }
}
