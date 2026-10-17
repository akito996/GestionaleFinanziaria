import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'invito.dart';

/// Riceve i link d'invito che aprono l'app (`wallecy://invito?...`, ADR-019):
/// quello dell'avvio e quelli che arrivano con l'app aperta. Per ora solo su
/// Android; su Windows il link si incolla in "Ho un link d'invito".
class RicevitoreInviti {
  RicevitoreInviti(this._consegna);

  final void Function(InvitoCondiviso invito) _consegna;

  static const _canale = MethodChannel('gestionale/invito');

  Future<void> avvia() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    _canale.setMethodCallHandler((chiamata) async {
      if (chiamata.method == 'arrivato') {
        _ricevi(chiamata.arguments);
      }
    });
    try {
      _ricevi(await _canale.invokeMethod<String>('iniziale'));
    } on MissingPluginException {
      // Build senza il canale (es. test): nessun link.
    } on PlatformException catch (e) {
      debugPrint('Link d\'invito non letto: $e');
    }
  }

  void _ricevi(Object? link) {
    if (link is String) {
      final invito = InvitoCondiviso.daLink(link);
      if (invito != null) {
        _consegna(invito);
      }
    }
  }
}
