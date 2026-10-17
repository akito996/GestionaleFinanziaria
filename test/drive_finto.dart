import 'dart:convert';

import 'package:gestionale_finanziaria/core/condivisi/accesso_drive_file.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const tipoCartella = 'application/vnd.google-apps.folder';

class ElementoFinto {
  ElementoFinto(
    this.nome,
    this.padre,
    this.proprietario, {
    this.cartella = false,
    this.testo = '',
  });

  final String nome;
  String padre;
  final String proprietario;
  final bool cartella;
  String testo;
}

/// Google Drive finto in memoria, condiviso da più account (l'utente "x" ha
/// l'email "x@example.com").
///
/// Come `drive.file` nella prova vera del 16/10/2026: l'app di un utente vede
/// solo ciò che quell'utente ha creato o scelto con la finestra di Google;
/// può creare file in una cartella su cui ha il permesso anche senza vederla.
/// Con [aperto], scegliere una cartella dà accesso anche a ciò che contiene.
class DriveFinto {
  DriveFinto({this.aperto = false});

  final bool aperto;
  final elementi = <String, ElementoFinto>{};
  final accessi = <String, Set<String>>{};

  /// Condivisioni: cartella o file → utenti con permesso di scrittura.
  final permessi = <String, Set<String>>{};
  final condivisioni = <({String id, String email, String? messaggio})>[];
  var richieste = 0;
  var _n = 0;

  String radice(String utente) => 'root:$utente';

  bool vede(String utente, String id) {
    final mie = accessi[utente] ?? const <String>{};
    if (mie.contains(id)) {
      return true;
    }
    final padre = elementi[id]?.padre;
    return aperto && padre != null && mie.contains(padre);
  }

  /// Permesso di scrittura: proprietario o condiviso (anche da una cartella
  /// sopra).
  bool puoScrivere(String utente, String id) {
    String? corrente = id;
    while (corrente != null) {
      final e = elementi[corrente];
      if (e == null) {
        return corrente == radice(utente);
      }
      if (e.proprietario == utente ||
          (permessi[corrente]?.contains(utente) ?? false)) {
        return true;
      }
      corrente = e.padre;
    }
    return false;
  }

  void concedi(String utente, String id) => (accessi[utente] ??= {}).add(id);

  String crea(String utente, ElementoFinto e) {
    final id = 'f${_n++}';
    elementi[id] = e;
    concedi(utente, id);
    return id;
  }

  Iterable<String> conNome(String nome) => [
    for (final e in elementi.entries)
      if (e.value.nome == nome) e.key,
  ];

  static http.Response _ok([Object? json]) =>
      http.Response(jsonEncode(json ?? {}), 200);
  static http.Response get _manca => http.Response('File not found', 404);

  http.Client client(String utente) => MockClient((r) async {
    richieste++;
    final percorso = r.url.path;
    final q = r.url.queryParameters;
    final id = percorso.split('/').last;
    switch (r.method) {
      case 'GET' when percorso == '/drive/v3/about':
        return _ok({
          'user': {'emailAddress': '$utente@example.com'},
        });
      case 'POST' when percorso == '/drive/v3/files':
        final dati = jsonDecode(r.body) as Map<String, Object?>;
        final padre = (dati['parents'] as List<Object?>?)?.first as String?;
        if (padre != null && !puoScrivere(utente, padre)) {
          return _manca;
        }
        final nuovo = ElementoFinto(
          dati['name']! as String,
          padre ?? radice(utente),
          utente,
          cartella: dati['mimeType'] == tipoCartella,
        );
        return _ok({'id': crea(utente, nuovo)});
      case 'POST' when percorso.endsWith('/permissions'):
        final cartella = percorso.split('/')[4];
        final email = (jsonDecode(r.body) as Map)['emailAddress'] as String;
        condivisioni.add((
          id: cartella,
          email: email,
          messaggio: q['emailMessage'],
        ));
        (permessi[cartella] ??= {}).add(email.split('@').first);
        return _ok();
      case 'GET' when percorso.endsWith('/permissions'):
        final cartella = percorso.split('/')[4];
        return _ok({
          'permissions': [
            {
              'emailAddress': '${elementi[cartella]!.proprietario}@example.com',
              'role': 'owner',
            },
            for (final c in condivisioni.where((c) => c.id == cartella))
              {'emailAddress': c.email, 'role': 'writer'},
          ],
        });
      case 'POST' when percorso == '/upload/drive/v3/files':
        final parti = r.body.split('\r\n\r\n');
        final meta =
            jsonDecode(parti[1].split('\r\n').first) as Map<String, Object?>;
        final padre = (meta['parents']! as List).first as String;
        if (!puoScrivere(utente, padre)) {
          return _manca;
        }
        if (elementi[padre]?.cartella != true) {
          return http.Response('The specified parent is not a folder.', 403);
        }
        final nuovo = ElementoFinto(
          meta['name']! as String,
          padre,
          utente,
          testo: parti[2].split('\r\n--').first,
        );
        return _ok({'id': crea(utente, nuovo)});
      case 'PATCH' when !vede(utente, id) || !puoScrivere(utente, id):
        return _manca;
      case 'PATCH' when percorso.startsWith('/upload/'):
        elementi[id]!.testo = utf8.decode(r.bodyBytes);
        return _ok();
      case 'PATCH':
        elementi[id]!.padre = q['addParents']!;
        return _ok();
      case 'GET' when percorso == '/drive/v3/files':
        final filtro = q['q']!;
        final nome = RegExp(r"name = '([^']+)'").firstMatch(filtro)?.group(1);
        var padre = RegExp(r"'([^']+)' in parents")
            .firstMatch(filtro)
            ?.group(1);
        if (padre == 'root') {
          padre = radice(utente);
        }
        final soloCartelle = filtro.contains("mimeType = '$tipoCartella'");
        return _ok({
          'files': [
            for (final e in elementi.entries)
              if (vede(utente, e.key) &&
                  (nome == null || e.value.nome == nome) &&
                  (padre == null || e.value.padre == padre) &&
                  (!soloCartelle || e.value.cartella))
                {
                  'id': e.key,
                  'name': e.value.nome,
                  'parents': [e.value.padre],
                  'owners': [
                    {'displayName': e.value.proprietario},
                  ],
                },
          ],
        });
      case 'GET' when !vede(utente, id):
        return _manca;
      case 'GET' when q['alt'] == 'media':
        return http.Response.bytes(utf8.encode(elementi[id]!.testo), 200);
      case 'GET':
        final e = elementi[id]!;
        return _ok({
          'name': e.nome,
          'mimeType': e.cartella ? tipoCartella : 'text/plain',
          'parents': [e.padre],
          'owners': [
            {'emailAddress': '${e.proprietario}@example.com'},
          ],
        });
    }
    return http.Response('non previsto', 404);
  });
}

/// La finestra di Google finta: l'utente sceglie gli elementi che
/// soddisfano [sceglie], oppure tutti quelli mostrati con `soloId`.
class AccessoFinto implements AccessoDriveFile {
  AccessoFinto(this.drive, this.utente, {this.sceglie});

  final DriveFinto drive;
  final String utente;
  bool Function(ElementoFinto e)? sceglie;
  final richiesteSoloId = <List<String>>[];

  /// Consenso già dato (per la sincronizzazione in sottofondo).
  bool consenso = true;

  @override
  Future<http.Client?> client({bool interattivo = true}) async {
    if (!consenso && !interattivo) {
      return null;
    }
    consenso = true;
    return drive.client(utente);
  }

  @override
  Future<ElementiScelti> scegli({List<String> soloId = const []}) async {
    richiesteSoloId.add(soloId);
    final scelti = soloId.isNotEmpty
        ? soloId
        : [
            for (final e in drive.elementi.entries)
              if (sceglie?.call(e.value) ?? false) e.key,
          ];
    if (scelti.isEmpty) {
      throw const SceltaAnnullata();
    }
    for (final id in scelti) {
      drive.concedi(utente, id);
    }
    return (client: drive.client(utente), scelti: scelti);
  }
}
