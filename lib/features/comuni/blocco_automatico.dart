import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/sessione.dart';

int _sospensioni = 0;

/// Esegue [azione] che porta l'app in secondo piano per scelta dell'utente
/// (fotocamera, scelta di un file, consenso di Google, PIN del telefono):
/// nel frattempo il blocco automatico non scatta.
Future<T> senzaBloccoAutomatico<T>(Future<T> Function() azione) async {
  _sospensioni++;
  try {
    return await azione();
  } finally {
    _sospensioni--;
  }
}

/// Blocco automatico (ADR-016): se l'app resta in secondo piano più del tempo
/// scelto nelle Impostazioni, l'archivio si blocca (con "Subito", appena
/// l'app va in secondo piano). Al ritorno lo sblocco rapido parte da solo.
class BloccoAutomatico {
  BloccoAutomatico(this.sessione, {DateTime Function()? adesso})
    : _adesso = adesso ?? DateTime.now {
    _ciclo = AppLifecycleListener(onHide: _nascosta, onShow: _visibile);
  }

  final Sessione sessione;
  final DateTime Function() _adesso;
  late final AppLifecycleListener _ciclo;
  Timer? _timer;
  DateTime? _scadenza;

  void _nascosta() {
    // In secondo piano per fotocamera, file o Google: non si conta.
    if (_sospensioni > 0) {
      return;
    }
    final durata = sessione.sicurezza.bloccoAutomatico;
    if (durata == null) {
      return;
    }
    if (durata == Duration.zero) {
      _blocca();
      return;
    }
    _scadenza = _adesso().add(durata);
    _timer?.cancel();
    _timer = Timer(durata, _blocca);
  }

  void _visibile() {
    _timer?.cancel();
    _timer = null;
    final scadenza = _scadenza;
    _scadenza = null;
    // Il timer può non essere partito (app sospesa dal sistema): si
    // controlla l'ora al ritorno.
    if (scadenza != null && !_adesso().isBefore(scadenza)) {
      _blocca();
    }
  }

  void _blocca() {
    _timer?.cancel();
    _timer = null;
    _scadenza = null;
    if (sessione.fase == FaseSessione.sbloccata) {
      sessione.blocca(automatico: true).ignore();
    }
  }

  void dispose() {
    _timer?.cancel();
    _ciclo.dispose();
  }
}
