/// Ogni quanto si ripete un pagamento.
enum Frequenza {
  settimanale('settimanale', 'Ogni settimana', 0),
  mensile('mensile', 'Ogni mese', 1),
  bimestrale('bimestrale', 'Ogni 2 mesi', 2),
  trimestrale('trimestrale', 'Ogni 3 mesi', 3),
  semestrale('semestrale', 'Ogni 6 mesi', 6),
  annuale('annuale', 'Ogni anno', 12);

  const Frequenza(this.codice, this.etichetta, this.mesi);

  /// Valore salvato nel database: non cambiarlo per le frequenze esistenti.
  final String codice;
  final String etichetta;

  /// Passo in mesi (0 = settimanale).
  final int mesi;

  static Frequenza daCodice(String? codice) => Frequenza.values.firstWhere(
    (f) => f.codice == codice,
    orElse: () => Frequenza.mensile,
  );
}

/// Regola di ripetizione: dal giorno [inizio], ogni [frequenza], fino a [fine]
/// (inclusa) oppure per [occorrenze] volte. Senza fine = per sempre.
///
/// I mesi senza quel giorno (es. il 31 a febbraio) usano l'ultimo giorno del mese,
/// e il mese dopo si torna al giorno originale.
class Ricorrenza {
  const Ricorrenza({
    required this.inizio,
    this.frequenza = Frequenza.mensile,
    this.fine,
    this.occorrenze,
  }) : assert(occorrenze == null || occorrenze > 0);

  final DateTime inizio;
  final Frequenza frequenza;
  final DateTime? fine;
  final int? occorrenze;

  /// Data della n-esima ripetizione (0 = la prima), senza controllare la fine.
  DateTime _n(int n) {
    final base = DateTime(inizio.year, inizio.month, inizio.day);
    if (frequenza == Frequenza.settimanale) {
      return DateTime(base.year, base.month, base.day + 7 * n);
    }
    final mese = DateTime(base.year, base.month + frequenza.mesi * n);
    final ultimo = DateTime(mese.year, mese.month + 1, 0).day;
    return DateTime(
      mese.year,
      mese.month,
      base.day <= ultimo ? base.day : ultimo,
    );
  }

  bool _entroLaFine(int n, DateTime data) {
    if (occorrenze != null && n >= occorrenze!) {
      return false;
    }
    final f = fine;
    return f == null || !data.isAfter(DateTime(f.year, f.month, f.day));
  }

  /// Tutte le date tra [da] e [a] (inclusi).
  List<DateTime> tra(DateTime da, DateTime a) {
    final inizioGiorno = DateTime(da.year, da.month, da.day);
    final fineGiorno = DateTime(a.year, a.month, a.day);
    final out = <DateTime>[];
    for (var n = 0; ; n++) {
      final data = _n(n);
      if (data.isAfter(fineGiorno) || !_entroLaFine(n, data)) {
        break;
      }
      if (!data.isBefore(inizioGiorno)) {
        out.add(data);
      }
    }
    return out;
  }

  /// Le date che cadono nel mese di [mese].
  List<DateTime> nelMese(DateTime mese) => tra(
    DateTime(mese.year, mese.month),
    DateTime(mese.year, mese.month + 1, 0),
  );

  /// Prima data uguale o successiva a [giorno], se esiste ancora.
  DateTime? prossima(DateTime giorno) {
    final da = DateTime(giorno.year, giorno.month, giorno.day);
    for (var n = 0; n < 100000; n++) {
      final data = _n(n);
      if (!_entroLaFine(n, data)) {
        return null;
      }
      if (!data.isBefore(da)) {
        return data;
      }
    }
    return null;
  }

  /// Ultima data della serie, se la serie ha una fine.
  DateTime? get ultima {
    if (occorrenze != null) {
      final ultimaPerNumero = _n(occorrenze! - 1);
      final f = fine;
      if (f == null || !ultimaPerNumero.isAfter(f)) {
        return ultimaPerNumero;
      }
    }
    final f = fine;
    if (f == null) {
      return null;
    }
    final date = tra(inizio, f);
    return date.isEmpty ? null : date.last;
  }

  /// Descrizione per l'utente: "Ogni mese dal 5, fino al 31/12/2027".
  String descrizione() {
    final giorno = inizio.day;
    final quando = switch (frequenza) {
      Frequenza.settimanale => 'Ogni settimana',
      Frequenza.mensile => 'Ogni mese il giorno $giorno',
      _ => '${frequenza.etichetta}, il giorno $giorno',
    };
    final fino = occorrenze != null
        ? ', per $occorrenze volte'
        : fine != null
        ? ', fino al ${_data(fine!)}'
        : '';
    return '$quando$fino';
  }

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
