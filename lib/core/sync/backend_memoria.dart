import 'dart:typed_data';

import 'sync_backend.dart';

/// Spazio remoto in memoria: per i test (due "dispositivi" sullo stesso
/// processo) e per provare la sincronizzazione senza Google Drive.
class BackendInMemoria implements SyncBackend {
  final _file = <String, (FileRemoto, Uint8List)>{};
  var _prossimo = 0;

  /// Quante chiamate sono state fatte (per controllare che non si scarichi
  /// più del necessario).
  var scaricamenti = 0;

  @override
  Future<List<FileRemoto>> elenca() async => [
    for (final (f, _) in _file.values) f,
  ];

  @override
  Future<Uint8List> scarica(String id) async {
    scaricamenti++;
    final file = _file[id];
    if (file == null) {
      throw StateError('File $id non trovato');
    }
    return Uint8List.fromList(file.$2);
  }

  @override
  Future<FileRemoto> crea(
    String nome,
    Uint8List dati, {
    Map<String, String> proprieta = const {},
  }) async {
    final id = 'f${_prossimo++}';
    final file = FileRemoto(id: id, nome: nome, proprieta: Map.of(proprieta));
    _file[id] = (file, Uint8List.fromList(dati));
    return file;
  }

  @override
  Future<void> aggiorna(String id, Uint8List dati) async {
    final (file, _) = _file[id]!;
    _file[id] = (file, Uint8List.fromList(dati));
  }

  @override
  Future<void> rinomina(String id, String nome) async {
    final (file, dati) = _file[id]!;
    _file[id] = (
      FileRemoto(id: id, nome: nome, proprieta: file.proprieta),
      dati,
    );
  }

  @override
  Future<void> elimina(String id) async => _file.remove(id);
}
