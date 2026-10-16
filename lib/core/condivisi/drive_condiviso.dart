import 'dart:convert';

import 'package:http/http.dart' as http;

/// File di una cartella condivisa.
typedef FileCondiviso = ({String id, String nome, String autore});

/// Errore di Drive con lo stato HTTP (es. 403 = permesso mancante).
final class ErroreDriveCondiviso implements Exception {
  const ErroreDriveCondiviso(this.stato, this.dettaglio);

  final int stato;
  final String dettaglio;

  @override
  String toString() => 'Drive $stato: $dettaglio';
}

/// Operazioni su una cartella condivisa di Google Drive (permesso
/// `drive.file`, ADR-019): crea, condividi, elenca, leggi, scrivi.
class DriveCondiviso {
  DriveCondiviso(this._client);

  final http.Client _client;

  static final _api = Uri.https('www.googleapis.com', '/drive/v3/');
  static final _caricamento = Uri.https(
    'www.googleapis.com',
    '/upload/drive/v3/files',
    {'uploadType': 'multipart'},
  );
  static const _cartella = 'application/vnd.google-apps.folder';

  Future<Map<String, Object?>> _json(http.Response r) async {
    if (r.statusCode >= 300) {
      throw ErroreDriveCondiviso(r.statusCode, r.body);
    }
    return r.body.isEmpty
        ? const {}
        : jsonDecode(r.body) as Map<String, Object?>;
  }

  /// Nuova cartella nel Drive dell'utente; restituisce l'id.
  Future<String> creaCartella(String nome) async {
    final r = await _client.post(
      _api.resolve('files'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': nome, 'mimeType': _cartella}),
    );
    return (await _json(r))['id']! as String;
  }

  /// Condivide la cartella con un account Google, che potrà anche scrivere.
  Future<void> condividi(String cartellaId, String email) async {
    final r = await _client.post(
      _api
          .resolve('files/$cartellaId/permissions')
          .replace(queryParameters: {'sendNotificationEmail': 'true'}),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': 'writer',
        'type': 'user',
        'emailAddress': email,
      }),
    );
    await _json(r);
  }

  /// Nuovo file di testo nella cartella; restituisce l'id.
  Future<String> scrivi(String cartellaId, String nome, String testo) async {
    const confine = 'wallecy-confine';
    final corpo =
        '--$confine\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${jsonEncode({
          'name': nome,
          'parents': [cartellaId],
        })}\r\n'
        '--$confine\r\n'
        'Content-Type: text/plain; charset=UTF-8\r\n\r\n'
        '$testo\r\n'
        '--$confine--';
    final r = await _client.post(
      _caricamento,
      headers: {'Content-Type': 'multipart/related; boundary=$confine'},
      body: utf8.encode(corpo),
    );
    return (await _json(r))['id']! as String;
  }

  /// I file nella cartella (anche quelli scritti dagli altri membri).
  Future<List<FileCondiviso>> elenca(String cartellaId) async {
    final r = await _client.get(
      _api
          .resolve('files')
          .replace(
            queryParameters: {
              'q': "'$cartellaId' in parents and trashed = false",
              'fields': 'files(id,name,owners(displayName))',
              'pageSize': '100',
            },
          ),
    );
    final file = (await _json(r))['files'] as List<Object?>? ?? const [];
    return [
      for (final f in file.cast<Map<String, Object?>>())
        (
          id: f['id']! as String,
          nome: f['name']! as String,
          autore:
              ((f['owners'] as List<Object?>?)?.firstOrNull
                      as Map<String, Object?>?)?['displayName']
                  as String? ??
              '',
        ),
    ];
  }

  /// Contenuto di un file di testo.
  Future<String> leggi(String fileId) async {
    final r = await _client.get(
      _api.resolve('files/$fileId').replace(queryParameters: {'alt': 'media'}),
    );
    if (r.statusCode >= 300) {
      throw ErroreDriveCondiviso(r.statusCode, r.body);
    }
    return utf8.decode(r.bodyBytes);
  }

  void chiudi() => _client.close();
}
