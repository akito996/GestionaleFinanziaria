import 'dart:typed_data';

import 'package:gestionale_finanziaria/core/sicurezza/cassaforte.dart';

/// Cassaforte del dispositivo per i test: il segreto resta in memoria e la
/// "verifica" (impronta, PIN) riesce, si annulla o fallisce a comando.
class CassaforteFinta implements CassaforteDispositivo {
  CassaforteFinta({this.stato = DisponibilitaCassaforte.pronta});

  DisponibilitaCassaforte stato;

  /// Prossima verifica: l'utente annulla.
  bool annulla = false;

  /// Prossima lettura: il sistema ha annullato la chiave.
  bool chiaveAnnullata = false;

  Uint8List? _segreto;
  int verifiche = 0;

  @override
  bool get conPin => true;

  @override
  Future<DisponibilitaCassaforte> disponibilita() async => stato;

  @override
  Future<MaterialeCassaforte> attiva(Uint8List sfida) async {
    _verifica();
    _segreto = Uint8List.fromList(List.generate(32, (i) => (i * 7 + 3) % 256));
    // Sola lettura, come i byte che arrivano dal sistema vero.
    return (
      materiale: Uint8List.fromList(_segreto!).asUnmodifiableView(),
      dati: Uint8List.fromList([1, 2, 3]),
    );
  }

  @override
  Future<Uint8List> leggi(Uint8List sfida, Uint8List dati) async {
    if (chiaveAnnullata || _segreto == null) {
      _segreto = null;
      throw const ChiaveDispositivoAnnullata();
    }
    _verifica();
    return Uint8List.fromList(_segreto!).asUnmodifiableView();
  }

  @override
  Future<void> disattiva() async => _segreto = null;

  void _verifica() {
    verifiche++;
    if (annulla) {
      annulla = false;
      throw const VerificaAnnullata();
    }
  }
}
