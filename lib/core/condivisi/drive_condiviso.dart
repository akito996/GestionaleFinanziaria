import 'dart:convert';

import 'package:http/http.dart' as http;

/// File di una cartella condivisa.
typedef FileCondiviso = ({String id, String nome, String autore});

/// Nome, tipo, cartelle che lo contengono e proprietario di un elemento.
typedef InfoDrive = ({
  String nome,
  bool cartella,
  List<String> padri,
  String? emailProprietario,
});

/// Come è stata ottenuta una cartella dentro «WalleCy».
enum Origine { trovata, spostata, creata }

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
///
/// Tutto sta in un'unica cartella «WalleCy» nel Drive dell'utente, con una
/// sottocartella per ogni condivisione: niente cartelle sparse nella radice.
class DriveCondiviso {
  DriveCondiviso(this._client);

  final http.Client _client;

  /// La cartella che raccoglie tutte le condivisioni.
  static const cartellaApp = 'WalleCy';

  static final _api = Uri.https('www.googleapis.com', '/drive/v3/');
  static final _caricamento = Uri.https(
    'www.googleapis.com',
    '/upload/drive/v3/files',
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

  /// Testo dentro gli apici di una ricerca di Drive.
  static String _testo(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

  /// Elementi che l'app può vedere (creati da lei o scelti dall'utente),
  /// dal più vecchio.
  Future<List<({String id, List<String> padri})>> _cerca(String q) async {
    final r = await _client.get(
      _api
          .resolve('files')
          .replace(
            queryParameters: {
              'q': '$q and trashed = false',
              'fields': 'files(id,parents)',
              'orderBy': 'createdTime',
              'pageSize': '100',
            },
          ),
    );
    final file = (await _json(r))['files'] as List<Object?>? ?? const [];
    return [
      for (final f in file.cast<Map<String, Object?>>())
        (
          id: f['id']! as String,
          padri: (f['parents'] as List<Object?>? ?? const []).cast<String>(),
        ),
    ];
  }

  /// Nuova cartella (nella radice o dentro [padre]); restituisce l'id.
  Future<String> creaCartella(String nome, {String? padre}) async {
    final r = await _client.post(
      _api.resolve('files'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': nome,
        'mimeType': _cartella,
        if (padre != null) 'parents': [padre],
      }),
    );
    return (await _json(r))['id']! as String;
  }

  /// La cartella «WalleCy» nella radice del Drive: la crea solo se manca.
  Future<String> cartellaWalleCy() async {
    final trovate = await _cerca(
      "name = '$cartellaApp' and mimeType = '$_cartella' "
      "and 'root' in parents",
    );
    return trovate.firstOrNull?.id ?? await creaCartella(cartellaApp);
  }

  /// Una cartella creata prima dall'app, ovunque sia.
  Future<String?> trovaCartella(String nome) async =>
      (await _cerca("name = '${_testo(nome)}' and mimeType = '$_cartella'"))
          .firstOrNull
          ?.id;

  /// La cartella [nome] dentro «WalleCy»: la riusa se c'è già (e ce la
  /// sposta se era altrove), altrimenti la crea.
  Future<({String id, Origine origine})> cartellaDentroWalleCy(
    String nome,
  ) async {
    final padre = await cartellaWalleCy();
    final trovate = await _cerca(
      "name = '${_testo(nome)}' and mimeType = '$_cartella'",
    );
    final dentro = trovate.where((c) => c.padri.contains(padre)).firstOrNull;
    if (dentro != null) {
      return (id: dentro.id, origine: Origine.trovata);
    }
    final fuori = trovate.firstOrNull;
    if (fuori != null) {
      await sposta(fuori.id, padre, fuori.padri);
      return (id: fuori.id, origine: Origine.spostata);
    }
    return (
      id: await creaCartella(nome, padre: padre),
      origine: Origine.creata,
    );
  }

  /// Sposta un elemento nella cartella [nuovoPadre].
  Future<void> sposta(String id, String nuovoPadre, List<String> padri) async {
    final r = await _client.patch(
      _api
          .resolve('files/$id')
          .replace(
            queryParameters: {
              'addParents': nuovoPadre,
              if (padri.isNotEmpty) 'removeParents': padri.join(','),
            },
          ),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    await _json(r);
  }

  /// Condivide una cartella o un file con un account Google, che potrà anche
  /// scrivere. Google gli manda un'email, con [messaggio] se c'è.
  Future<void> condividi(String id, String email, {String? messaggio}) async {
    final r = await _client.post(
      _api
          .resolve('files/$id/permissions')
          .replace(
            queryParameters: {
              'sendNotificationEmail': 'true',
              'emailMessage': ?messaggio,
            },
          ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': 'writer',
        'type': 'user',
        'emailAddress': email,
      }),
    );
    await _json(r);
  }

  /// Chi ha già accesso (email in minuscolo) e con quale ruolo ("owner",
  /// "writer", ...).
  Future<Map<String, String>> condivisoCon(String id) async {
    final r = await _client.get(
      _api
          .resolve('files/$id/permissions')
          .replace(
            queryParameters: {
              'fields': 'permissions(emailAddress,role)',
              'pageSize': '100',
            },
          ),
    );
    final permessi =
        (await _json(r))['permissions'] as List<Object?>? ?? const [];
    return {
      for (final p in permessi.cast<Map<String, Object?>>())
        if (p['emailAddress'] case final String email)
          email.toLowerCase(): p['role'] as String? ?? '',
    };
  }

  /// Il file [nome] nella cartella, se l'app lo vede.
  Future<String?> trovaFile(String cartellaId, String nome) async =>
      (await _cerca(
        "name = '${_testo(nome)}' and '${_testo(cartellaId)}' in parents",
      )).firstOrNull?.id;

  /// Scrive il file di testo [nome] nella cartella: lo aggiorna se c'è già,
  /// così ognuno ha un solo file. Restituisce l'id.
  Future<String> scrivi(String cartellaId, String nome, String testo) async {
    final esistente = await trovaFile(cartellaId, nome);
    if (esistente != null) {
      await aggiorna(esistente, testo);
      return esistente;
    }
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
      _caricamento.replace(queryParameters: {'uploadType': 'multipart'}),
      headers: {'Content-Type': 'multipart/related; boundary=$confine'},
      body: utf8.encode(corpo),
    );
    return (await _json(r))['id']! as String;
  }

  /// Nuovo contenuto per un file esistente (anche di un altro account, se
  /// può scriverci).
  Future<void> aggiorna(String fileId, String testo) async {
    final r = await _client.patch(
      _caricamento
          .resolve('files/$fileId')
          .replace(queryParameters: {'uploadType': 'media'}),
      headers: {'Content-Type': 'text/plain; charset=UTF-8'},
      body: utf8.encode(testo),
    );
    await _json(r);
  }

  /// I file nella cartella che l'app vede.
  Future<List<FileCondiviso>> elenca(String cartellaId) async {
    final r = await _client.get(
      _api
          .resolve('files')
          .replace(
            queryParameters: {
              'q': "'${_testo(cartellaId)}' in parents and trashed = false",
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

  /// Nome, tipo, cartelle e proprietario di un elemento.
  Future<InfoDrive> info(String id) async {
    final r = await _client.get(
      _api
          .resolve('files/$id')
          .replace(
            queryParameters: {
              'fields': 'name,mimeType,parents,owners(emailAddress)',
            },
          ),
    );
    final json = await _json(r);
    return (
      nome: json['name'] as String? ?? '',
      cartella: json['mimeType'] == _cartella,
      padri: (json['parents'] as List<Object?>? ?? const []).cast<String>(),
      emailProprietario:
          ((json['owners'] as List<Object?>?)?.firstOrNull
                  as Map<String, Object?>?)?['emailAddress']
              as String?,
    );
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
