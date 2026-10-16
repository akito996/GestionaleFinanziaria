import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Unico permesso chiesto a Google: la cartella nascosta dell'app su Drive.
/// Non dà accesso agli altri file dell'utente.
const ambitoDrive = 'https://www.googleapis.com/auth/drive.appdata';

/// Accesso a Google Drive con il consenso dell'utente, sul dispositivo.
abstract interface class AccessoGoogle {
  /// Su questa build si può usare (es. Windows senza configurazione: no).
  bool get disponibile;

  /// Client HTTP autorizzato per Drive. Con [interattivo] può chiedere il
  /// consenso (finestra Google o browser); senza, `null` se serve il consenso.
  Future<http.Client?> client({required bool interattivo});

  /// L'accesso di prima non vale più (es. 401): la prossima volta si rinnova.
  Future<void> invalida();

  /// Toglie il consenso salvato su questo dispositivo.
  Future<void> esci();

  /// Quello giusto per la piattaforma: Android o Windows.
  static AccessoGoogle perPiattaforma(CredenzialiGoogle credenziali) =>
      Platform.isAndroid
      ? AccessoGoogleAndroid()
      : AccessoGoogleDesktop(credenziali);
}

/// Dove tenere le credenziali di Windows (il token di rinnovo): dentro
/// l'archivio cifrato, solo su questo dispositivo.
abstract interface class CredenzialiGoogle {
  Future<String?> leggi();
  Future<void> scrivi(String? json);
}

/// Credenziali tenute solo in memoria (es. prima che l'archivio esista).
class CredenzialiInMemoria implements CredenzialiGoogle {
  String? _json;

  @override
  Future<String?> leggi() async => _json;

  @override
  Future<void> scrivi(String? json) async => _json = json;
}

/// Android: autorizzazione di Google Play services per il solo ambito di
/// Drive (niente accesso al profilo). Google riconosce l'app dal nome del
/// pacchetto e dall'impronta della firma (client OAuth "Android").
class AccessoGoogleAndroid implements AccessoGoogle {
  bool _pronto = false;
  String? _ultimo;

  @override
  bool get disponibile => true;

  Future<GoogleSignInAuthorizationClient> _autorizzazioni() async {
    if (!_pronto) {
      await GoogleSignIn.instance.initialize();
      _pronto = true;
    }
    return GoogleSignIn.instance.authorizationClient;
  }

  @override
  Future<http.Client?> client({required bool interattivo}) async {
    final autorizzazioni = await _autorizzazioni();
    final esito =
        await autorizzazioni.authorizationForScopes([ambitoDrive]) ??
        (interattivo
            ? await autorizzazioni.authorizeScopes([ambitoDrive])
            : null);
    if (esito == null) {
      return null;
    }
    _ultimo = esito.accessToken;
    return ClientConToken(esito.accessToken);
  }

  @override
  Future<void> invalida() async {
    final token = _ultimo;
    if (token != null) {
      await (await _autorizzazioni()).clearAuthorizationToken(
        accessToken: token,
      );
    }
  }

  @override
  Future<void> esci() async {
    await _autorizzazioni();
    await GoogleSignIn.instance.disconnect();
  }
}

/// Windows: consenso nel browser con ritorno su `localhost` e PKCE (client
/// OAuth "App desktop"). Il segreto del client arriva dalla build (secret di
/// GitHub), mai dal repository: senza, la sincronizzazione non è disponibile.
class AccessoGoogleDesktop implements AccessoGoogle {
  AccessoGoogleDesktop(this._credenziali);

  /// Pubblico: identifica l'app, non dà accesso a nulla.
  static const idClient =
      '1023061682411-9d0mm48ceilv5h6qr97sjk0v6rh1hj73.apps.googleusercontent.com';
  static const _segreto = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET_WINDOWS',
  );

  final CredenzialiGoogle _credenziali;

  @override
  bool get disponibile => _segreto.isNotEmpty;

  ClientId get _id => ClientId(idClient, _segreto);

  @override
  Future<http.Client?> client({required bool interattivo}) async {
    var credenziali = await _salvate();
    if (credenziali == null || credenziali.refreshToken == null) {
      if (!interattivo) {
        return null;
      }
      final base = http.Client();
      try {
        credenziali = await obtainAccessCredentialsViaUserConsent(
          _id,
          [ambitoDrive],
          base,
          (indirizzo) => launchUrl(
            Uri.parse(indirizzo),
            mode: LaunchMode.externalApplication,
          ),
        );
      } finally {
        base.close();
      }
      await _credenziali.scrivi(jsonEncode(credenziali.toJson()));
    }
    final client = autoRefreshingClient(_id, credenziali, http.Client());
    client.credentialUpdates.listen(
      (nuove) => _credenziali.scrivi(jsonEncode(nuove.toJson())),
    );
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
    } on Object catch (e) {
      debugPrint('Credenziali Google non leggibili: $e');
      return null;
    }
  }

  @override
  Future<void> invalida() => _credenziali.scrivi(null);

  @override
  Future<void> esci() => _credenziali.scrivi(null);
}

/// Aggiunge il token di accesso a ogni richiesta.
class ClientConToken extends http.BaseClient {
  ClientConToken(this._token);

  final String _token;
  final _base = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _base.send(request);
  }

  @override
  void close() => _base.close();
}
