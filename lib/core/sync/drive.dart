import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'sync_backend.dart';

/// Errore di Google Drive con il codice HTTP (401 = accesso scaduto).
class ErroreDrive implements Exception {
  const ErroreDrive(this.codice, this.messaggio);

  final int codice;
  final String messaggio;

  bool get accessoScaduto => codice == 401;

  @override
  String toString() => 'Google Drive ($codice): $messaggio';
}

/// Google Drive, cartella nascosta dell'app (`appDataFolder`, ambito
/// `drive.appdata`): l'utente non la vede in Drive e l'app non vede nient'altro.
///
/// [client] aggiunge già l'autorizzazione (vedi `AccessoGoogle`).
class DriveBackend implements SyncBackend {
  DriveBackend(this._client);

  final http.Client _client;

  static const _api = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';
  static const _campi = 'id,name,appProperties';

  @override
  Future<List<FileRemoto>> elenca() async {
    final risultato = <FileRemoto>[];
    String? pagina;
    do {
      final r = await _client.get(
        Uri.parse(_api).replace(
          queryParameters: {
            'spaces': 'appDataFolder',
            'pageSize': '1000',
            'fields': 'nextPageToken,files($_campi)',
            'pageToken': ?pagina,
          },
        ),
      );
      final json = _json(r);
      for (final f
          in (json['files'] as List? ?? const [])
              .cast<Map<String, Object?>>()) {
        risultato.add(_file(f));
      }
      pagina = json['nextPageToken'] as String?;
    } while (pagina != null);
    return risultato;
  }

  @override
  Future<Uint8List> scarica(String id) async {
    final r = await _client.get(
      Uri.parse('$_api/$id').replace(queryParameters: {'alt': 'media'}),
    );
    _controlla(r);
    return r.bodyBytes;
  }

  @override
  Future<FileRemoto> crea(
    String nome,
    Uint8List dati, {
    Map<String, String> proprieta = const {},
  }) async {
    final r = await _multipart(
      'POST',
      Uri.parse(
        _upload,
      ).replace(queryParameters: {'uploadType': 'multipart', 'fields': _campi}),
      {
        'name': nome,
        'parents': ['appDataFolder'],
        'appProperties': proprieta,
      },
      dati,
    );
    return _file(_json(r));
  }

  @override
  Future<void> aggiorna(String id, Uint8List dati) async {
    final r = await _client.patch(
      Uri.parse('$_upload/$id')
          .replace(queryParameters: {'uploadType': 'media', 'fields': 'id'}),
      headers: {'Content-Type': 'application/octet-stream'},
      body: dati,
    );
    _controlla(r);
  }

  @override
  Future<void> rinomina(String id, String nome) async {
    final r = await _client.patch(
      Uri.parse('$_api/$id').replace(queryParameters: {'fields': 'id'}),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': nome}),
    );
    _controlla(r);
  }

  @override
  Future<void> elimina(String id) async {
    final r = await _client.delete(Uri.parse('$_api/$id'));
    if (r.statusCode != 404) {
      _controlla(r); // già eliminato: va bene
    }
  }

  // ------------------------------------------------------------- interni

  Future<http.Response> _multipart(
    String metodo,
    Uri indirizzo,
    Map<String, Object?> metadati,
    Uint8List dati,
  ) async {
    const confine = 'gestionale-finanziaria-confine';
    final corpo = BytesBuilder(copy: false)
      ..add(
        utf8.encode(
          '--$confine\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '${jsonEncode(metadati)}\r\n'
          '--$confine\r\n'
          'Content-Type: application/octet-stream\r\n\r\n',
        ),
      )
      ..add(dati)
      ..add(utf8.encode('\r\n--$confine--\r\n'));
    final richiesta = http.Request(metodo, indirizzo)
      ..headers['Content-Type'] = 'multipart/related; boundary=$confine'
      ..bodyBytes = corpo.toBytes();
    return http.Response.fromStream(await _client.send(richiesta));
  }

  static FileRemoto _file(Map<String, Object?> f) => FileRemoto(
    id: f['id']! as String,
    nome: f['name'] as String? ?? '',
    proprieta: {
      for (final MapEntry(:key, :value)
          in (f['appProperties'] as Map? ?? const {}).entries)
        '$key': '$value',
    },
  );

  static Map<String, Object?> _json(http.Response r) {
    _controlla(r);
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, Object?>;
  }

  static void _controlla(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return;
    }
    var messaggio = r.reasonPhrase ?? '';
    try {
      final errore = (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['error'];
      if (errore is Map && errore['message'] is String) {
        messaggio = errore['message'] as String;
      }
    } on FormatException {
      // corpo non JSON: resta il motivo HTTP
    }
    throw ErroreDrive(r.statusCode, messaggio);
  }
}
