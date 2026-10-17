import 'package:flutter/foundation.dart';

/// Invito a un portafoglio condiviso, come viaggia nel link d'invito
/// (ADR-019, scelta del 17/10/2026).
///
/// Il link porta alla pagina del sito; i dati stanno dopo il "#", che il
/// browser non manda mai al server. La pagina apre WalleCy con lo schema
/// `wallecy://invito?...`. Nessun segreto: senza la condivisione di Google
/// Drive i file non si leggono, e la chiave del portafoglio arriva solo
/// dopo, cifrata per chi entra.
@immutable
class InvitoCondiviso {
  const InvitoCondiviso({
    required this.cartellaId,
    required this.registroId,
    this.fileId,
    required this.portafoglio,
    required this.da,
    this.scadenza,
  });

  /// Pagina del sito che apre l'invito (GitHub Pages; con un dominio proprio
  /// si sposterà lì).
  static const pagina = 'https://akito996.github.io/WalleCy/invito.html';

  /// Cartella condivisa e registro del portafoglio (id di Google Drive).
  final String cartellaId;
  final String registroId;

  /// Il file preparato per chi è invitato (id di Google Drive).
  final String? fileId;

  /// Nome del portafoglio ed email di chi invita (da mostrare).
  final String portafoglio;
  final String da;

  /// Entro quando accettare.
  final DateTime? scadenza;

  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,200}$');

  /// Il link da mandare (pagina del sito).
  Uri get link => Uri.parse(pagina).replace(fragment: _parametri);

  /// Il link che apre direttamente l'app.
  Uri get linkApp => Uri.parse('wallecy://invito').replace(query: _parametri);

  String get _parametri => Uri(
    queryParameters: {
      'v': '1',
      'c': cartellaId,
      'r': registroId,
      'f': ?fileId,
      'p': portafoglio,
      'da': da,
      if (scadenza != null) 's': scadenza!.toUtc().toIso8601String(),
    },
  ).query;

  /// Da un link (pagina del sito o `wallecy://`); `null` se non è un invito
  /// valido.
  static InvitoCondiviso? daLink(String testo) {
    final uri = Uri.tryParse(testo.trim());
    if (uri == null) {
      return null;
    }
    final Map<String, String> p;
    try {
      p = uri.scheme == 'wallecy'
          ? uri.queryParameters
          : Uri(query: uri.fragment).queryParameters;
    } on FormatException {
      return null;
    }
    return daMappa(p);
  }

  static InvitoCondiviso? daMappa(Map<String, Object?> p) {
    final c = p['c'];
    final r = p['r'];
    final f = p['f'];
    if (c is! String ||
        r is! String ||
        !_id.hasMatch(c) ||
        !_id.hasMatch(r) ||
        (f != null && (f is! String || !_id.hasMatch(f)))) {
      return null;
    }
    final s = p['s'];
    return InvitoCondiviso(
      cartellaId: c,
      registroId: r,
      fileId: f as String?,
      portafoglio: _breve(p['p']),
      da: _breve(p['da']),
      scadenza: s is String ? DateTime.tryParse(s) : null,
    );
  }

  static String _breve(Object? testo) {
    final t = testo is String ? testo.trim() : '';
    return t.length > 100 ? t.substring(0, 100) : t;
  }

  Map<String, Object?> toJson() => {
    'c': cartellaId,
    'r': registroId,
    'f': fileId,
    'p': portafoglio,
    'da': da,
    if (scadenza != null) 's': scadenza!.toUtc().toIso8601String(),
  };

  bool scadutoAlle(DateTime ora) =>
      scadenza != null && !ora.isBefore(scadenza!);
}
