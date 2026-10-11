import 'dart:async';

/// Ricalcolo dei dati osservati, uno per ogni ascoltatore.
extension Ricalcolo<S> on Stream<S> {
  /// Come [asyncMap], ma ogni ascoltatore ha il proprio calcolo.
  ///
  /// Con [asyncMap] chi si iscrive mentre un altro è già iscritto non riceve
  /// nulla fino al cambiamento successivo: succede quando un widget viene
  /// ricreato (per esempio cambiando la larghezza della finestra) e la scheda
  /// restava "in caricamento". Qui ogni iscrizione riparte dalla query di
  /// drift, che ripete subito l'ultimo risultato.
  Stream<T> ricalcola<T>(FutureOr<T> Function(S evento) calcola) =>
      Stream<T>.multi((ascoltatore) {
        final iscrizione = asyncMap(calcola).listen(
          ascoltatore.add,
          onError: ascoltatore.addError,
          onDone: ascoltatore.close,
        );
        ascoltatore
          ..onPause = iscrizione.pause
          ..onResume = iscrizione.resume
          ..onCancel = iscrizione.cancel;
      }, isBroadcast: true);
}
