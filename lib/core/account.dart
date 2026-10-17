import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import 'db/archivio.dart';
import 'db/orologio.dart';

/// Il profilo di chi usa l'archivio (Impostazioni › Account): nome e
/// cognome, email dell'account Google e nome nelle condivisioni. Una sola
/// riga che viaggia tra i propri dispositivi.
class ProfiloAccount {
  ProfiloAccount(this._db, this._orologio, {required this.idArchivio});

  final Archivio _db;
  final OrologioLogico _orologio;

  /// Codice dell'archivio (GF-XXXX-XXXX): il nome nelle condivisioni se non
  /// se ne sceglie uno.
  final String idArchivio;

  static const _id = 'io';

  /// Lunghezza massima dei nomi.
  static const lunghezzaMassima = 40;

  SimpleSelectStatement<$ProfiliTable, Profilo> get _riga =>
      _db.select(_db.profili)..where((p) => p.id.equals(_id));

  Future<Profilo?> leggi() => _riga.getSingleOrNull();

  Stream<Profilo?> osserva() => _riga.watchSingleOrNull();

  /// Il nome che vedono le altre persone nei portafogli condivisi: quello
  /// scelto o, se è vuoto, il codice dell'archivio.
  Future<String> nomeCondivisione() async {
    final scelto = pulito((await leggi())?.nomeCondivisione);
    return scelto.isEmpty ? idArchivio : scelto;
  }

  Future<void> salva({
    required String nome,
    required String email,
    required String nomeCondivisione,
  }) => _db
      .into(_db.profili)
      .insertOnConflictUpdate(
        ProfiliCompanion.insert(
          id: _id,
          aggiornatoIl: _orologio.adesso(),
          nome: Value(pulito(nome)),
          email: Value(email.trim().toLowerCase()),
          nomeCondivisione: Value(pulito(nomeCondivisione)),
        ),
      );

  /// L'email scoperta da Google (es. alla prima condivisione), se nel
  /// profilo manca.
  Future<void> emailSeManca(String email) async {
    final p = await leggi();
    if (email.isEmpty || (p?.email.isNotEmpty ?? false)) {
      return;
    }
    await salva(
      nome: p?.nome ?? '',
      email: email,
      nomeCondivisione: p?.nomeCondivisione ?? '',
    );
  }

  /// Un nome senza spazi in più né caratteri di controllo, al massimo
  /// [lunghezzaMassima] caratteri.
  static String pulito(Object? valore) {
    if (valore is! String) {
      return '';
    }
    final testo = valore
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return testo.length > lunghezzaMassima
        ? testo.substring(0, lunghezzaMassima).trim()
        : testo;
  }

  /// Email e nome dell'account Google collegato, da Google Drive (`about`).
  static Future<({String? email, String? nome})> daGoogle(
    http.Client client,
  ) async {
    final risposta = await client
        .get(
          Uri.https('www.googleapis.com', '/drive/v3/about', {
            'fields': 'user(emailAddress,displayName)',
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (risposta.statusCode != 200) {
      throw http.ClientException(
        'Google ha risposto ${risposta.statusCode}',
        risposta.request?.url,
      );
    }
    final utente =
        (jsonDecode(risposta.body) as Map<String, Object?>)['user']
            as Map<String, Object?>?;
    return (
      email: (utente?['emailAddress'] as String?)?.toLowerCase(),
      nome: utente?['displayName'] as String?,
    );
  }
}
