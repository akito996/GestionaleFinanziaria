import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Preferenze di questo dispositivo che servono anche ad archivio bloccato
/// (es. il tema): file `preferenze.json` accanto al keyring, mai
/// sincronizzato, nessun dato personale.
class PreferenzeDispositivo extends ChangeNotifier {
  PreferenzeDispositivo(this._file);

  final File _file;

  ThemeMode _tema = ThemeMode.system;

  /// Chiaro, scuro o come il sistema (predefinito).
  ThemeMode get tema => _tema;

  /// Legge il file (valori predefiniti se manca o è danneggiato).
  void leggi() {
    try {
      if (!_file.existsSync()) {
        return;
      }
      final json = jsonDecode(_file.readAsStringSync());
      if (json is Map<String, Object?>) {
        _tema = switch (json['tema']) {
          'chiaro' => ThemeMode.light,
          'scuro' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }
    } on FormatException {
      _tema = ThemeMode.system;
    }
  }

  Future<void> impostaTema(ThemeMode tema) async {
    _tema = tema;
    notifyListeners();
    await _file.parent.create(recursive: true);
    final temporaneo = File('${_file.path}.tmp');
    await temporaneo.writeAsString(
      jsonEncode({
        'v': 1,
        'tema': switch (tema) {
          ThemeMode.light => 'chiaro',
          ThemeMode.dark => 'scuro',
          ThemeMode.system => 'sistema',
        },
      }),
      flush: true,
    );
    await temporaneo.rename(_file.path);
  }
}
