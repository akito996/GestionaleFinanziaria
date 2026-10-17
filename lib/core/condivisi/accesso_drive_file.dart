import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../sync/accesso_google.dart';

/// Permesso "drive.file" (ADR-019): l'app vede solo i file che crea lei o che
/// l'utente sceglie con la finestra di Google. Serve ai portafogli condivisi:
/// il proprietario crea la cartella, il membro la sceglie una volta.
const ambitoDriveFile = 'https://www.googleapis.com/auth/drive.file';

/// Esito della scelta: client autorizzato e id dei file o cartelle scelti.
typedef ElementiScelti = ({http.Client client, List<String> scelti});

/// Cosa mostra la finestra di Google: cartelle e file di testo.
const tipiSceglibili = 'application/vnd.google-apps.folder,text/plain';

/// La scelta è stata annullata dall'utente.
final class SceltaAnnullata implements Exception {
  const SceltaAnnullata();
}

abstract interface class AccessoDriveFile {
  /// Client autorizzato a creare e leggere i propri file. Con [interattivo]
  /// può chiedere il consenso a Google; senza (sincronizzazione in
  /// sottofondo) restituisce `null` se il consenso non c'è ancora.
  Future<http.Client?> client({bool interattivo = true});

  /// Finestra di Google per scegliere cartelle o file condivisi da altri
  /// (anche più di uno). Con [soloId] mostra solo quei file.
  Future<ElementiScelti> scegli({List<String> soloId = const []});

  /// [credenziali]: dove Windows conserva il permesso (nell'archivio
  /// cifrato), così la sincronizzazione non riapre il browser.
  static AccessoDriveFile perPiattaforma([CredenzialiGoogle? credenziali]) =>
      Platform.isAndroid
      ? AccessoDriveFileAndroid()
      : AccessoDriveFileDesktop(credenziali ?? CredenzialiInMemoria());
}

/// Android: Google Play services (stesso client OAuth "Android" della
/// sincronizzazione) e selettore nativo di Drive.
class AccessoDriveFileAndroid implements AccessoDriveFile {
  static const _canale = MethodChannel('gestionale/drive_file');

  bool _pronto = false;

  @override
  Future<http.Client?> client({bool interattivo = true}) async {
    if (!_pronto) {
      await GoogleSignIn.instance.initialize();
      _pronto = true;
    }
    final autorizzazioni = GoogleSignIn.instance.authorizationClient;
    final esito =
        await autorizzazioni.authorizationForScopes([ambitoDriveFile]) ??
        (interattivo
            ? await autorizzazioni.authorizeScopes([ambitoDriveFile])
            : null);
    return esito == null ? null : ClientConToken(esito.accessToken);
  }

  @override
  Future<ElementiScelti> scegli({List<String> soloId = const []}) async {
    try {
      final risposta = await _canale.invokeMapMethod<String, Object?>(
        'scegli',
        {'soloId': soloId.join(',')},
      );
      final token = risposta?['token'];
      if (token is! String) {
        throw const SceltaAnnullata();
      }
      final scelti = (risposta?['scelti'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      return (client: ClientConToken(token), scelti: scelti);
    } on PlatformException catch (e) {
      if (e.code == 'annullato') {
        throw const SceltaAnnullata();
      }
      rethrow;
    }
  }
}

/// Windows: consenso e selettore nel browser, con ritorno su `localhost` e
/// PKCE (client OAuth "App desktop", come la sincronizzazione).
class AccessoDriveFileDesktop implements AccessoDriveFile {
  AccessoDriveFileDesktop(this._credenziali);

  static const _segreto = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET_WINDOWS',
  );

  /// Il permesso (con il token di rinnovo), nell'archivio cifrato.
  final CredenzialiGoogle _credenziali;

  ClientId get _id => ClientId(AccessoGoogleDesktop.idClient, _segreto);

  @override
  Future<http.Client?> client({bool interattivo = true}) async {
    var credenziali = await _salvate();
    if (credenziali == null || credenziali.refreshToken == null) {
      if (!interattivo) {
        return null;
      }
      final base = http.Client();
      try {
        credenziali = await obtainAccessCredentialsViaUserConsent(
          _id,
          [ambitoDriveFile],
          base,
          (indirizzo) => launchUrl(
            Uri.parse(indirizzo),
            mode: LaunchMode.externalApplication,
          ),
        );
      } finally {
        base.close();
      }
      await _salva(credenziali);
    }
    final client = autoRefreshingClient(_id, credenziali, http.Client());
    client.credentialUpdates.listen(_salva);
    return client;
  }

  Future<AccessCredentials?> _salvate() async {
    final json = await _credenziali.leggi();
    if (json == null) {
      return null;
    }
    try {
      return AccessCredentials.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _salva(AccessCredentials credenziali) =>
      _credenziali.scrivi(jsonEncode(credenziali.toJson()));

  @override
  Future<ElementiScelti> scegli({List<String> soloId = const []}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final ritorno = 'http://127.0.0.1:${server.port}';
      final verificatore = _casuale(48);
      final sfida = base64Url
          .encode(sha256.convert(ascii.encode(verificatore)).bytes)
          .replaceAll('=', '');
      final stato = _casuale(16);
      final indirizzo = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': AccessoGoogleDesktop.idClient,
        'scope': ambitoDriveFile,
        'redirect_uri': ritorno,
        'response_type': 'code',
        'access_type': 'offline',
        'prompt': 'consent',
        'trigger_onepick': 'true',
        'allow_folder_selection': 'true',
        'allow_multiple': 'true',
        'mimetypes': tipiSceglibili,
        if (soloId.isNotEmpty) 'file_ids': soloId.join(','),
        'code_challenge': sfida,
        'code_challenge_method': 'S256',
        'state': stato,
      });
      await launchUrl(indirizzo, mode: LaunchMode.externalApplication);
      final richiesta = await server.first.timeout(const Duration(minutes: 5));
      final p = richiesta.uri.queryParameters;
      richiesta.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write(
          '<!doctype html><meta charset="utf-8"><title>WalleCy</title>'
          '<p style="font:16px sans-serif">Fatto: puoi tornare a WalleCy.</p>',
        );
      await richiesta.response.close();
      final codice = p['code'];
      if (p['state'] != stato || codice == null) {
        throw const SceltaAnnullata();
      }
      final token = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        body: {
          'client_id': AccessoGoogleDesktop.idClient,
          'client_secret': _segreto,
          'code': codice,
          'code_verifier': verificatore,
          'grant_type': 'authorization_code',
          'redirect_uri': ritorno,
        },
      );
      final json = jsonDecode(token.body) as Map<String, Object?>;
      final accesso = json['access_token'];
      if (accesso is! String) {
        throw StateError('Token non ricevuto: ${token.body}');
      }
      // Il permesso resta per la sincronizzazione in sottofondo.
      final rinnovo = json['refresh_token'];
      final durata = json['expires_in'];
      if (rinnovo is String && durata is int) {
        await _salva(
          AccessCredentials(
            AccessToken(
              'Bearer',
              accesso,
              DateTime.now().toUtc().add(Duration(seconds: durata - 60)),
            ),
            rinnovo,
            [ambitoDriveFile],
          ),
        );
      }
      final scelti = (p['picked_file_ids'] ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      return (client: ClientConToken(accesso), scelti: scelti);
    } on TimeoutException {
      throw const SceltaAnnullata();
    } finally {
      await server.close(force: true);
    }
  }

  static String _casuale(int byte) {
    final r = Random.secure();
    return base64Url
        .encode(List<int>.generate(byte, (_) => r.nextInt(256)))
        .replaceAll('=', '');
  }
}
