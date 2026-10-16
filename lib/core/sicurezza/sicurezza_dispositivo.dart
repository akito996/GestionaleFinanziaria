import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sodium/sodium_sumo.dart';

import '../crypto/cifratura.dart';
import '../crypto/eccezioni.dart';
import 'cassaforte.dart';

/// Sicurezza di questo dispositivo (ADR-016): sblocco rapido (impronta, viso
/// o PIN su Android, Windows Hello sul PC) e blocco automatico.
///
/// Tutto sta nel file `sicurezza.json` accanto al keyring e non viene mai
/// sincronizzato: vale solo per questo dispositivo. Il file non contiene
/// segreti in chiaro: la chiave dei dati è avvolta con una chiave che si
/// ricava solo dal segreto rilasciato dalla cassaforte del dispositivo dopo la
/// verifica dell'utente.
class SicurezzaDispositivo extends ChangeNotifier {
  SicurezzaDispositivo({
    required this._sodium,
    required this._file,
    required this._cassaforte,
    DateTime Function()? adesso,
  }) : _adesso = adesso ?? DateTime.now;

  final SodiumSumo _sodium;
  final File _file;
  final CassaforteDispositivo _cassaforte;
  final DateTime Function() _adesso;

  /// Ogni quanto si chiede comunque la password, per non dimenticarla.
  static const intervalloPassword = Duration(days: 14);

  /// Blocco automatico predefinito, dopo questo tempo in secondo piano.
  static const bloccoPredefinito = Duration(minutes: 5);

  /// Scelte del blocco automatico (`null` = mai).
  static const scelteBlocco = <Duration?>[
    Duration.zero,
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
    null,
  ];

  static const _versione = 1;

  DisponibilitaCassaforte _disponibilita =
      DisponibilitaCassaforte.nonSupportata;
  _Rapido? _rapido;
  DateTime? _ultimaPassword;
  bool _propostaFatta = false;
  Duration? _bloccoAutomatico = bloccoPredefinito;
  String? _avviso;

  DisponibilitaCassaforte get disponibilita => _disponibilita;

  /// Oltre a impronta e viso vale anche il PIN del dispositivo.
  bool get conPin => _cassaforte.conPin;

  bool get rapidoAttivo => _rapido != null;

  /// Sblocco rapido attivo ma sono passati 14 giorni dall'ultima password.
  bool get passwordDaChiedere {
    if (_rapido == null) {
      return false;
    }
    final ultima = _ultimaPassword;
    return ultima == null ||
        !_adesso().isBefore(ultima.add(intervalloPassword));
  }

  /// Si può aprire l'archivio con impronta, viso, PIN o Windows Hello.
  bool get rapidoPronto => rapidoAttivo && !passwordDaChiedere;

  /// Da quando la password verrà chiesta di nuovo.
  DateTime? get prossimaPassword => _ultimaPassword?.add(intervalloPassword);

  /// Si può proporre di attivare lo sblocco rapido (una volta sola).
  bool get proponibile =>
      _disponibilita == DisponibilitaCassaforte.pronta &&
      _rapido == null &&
      !_propostaFatta;

  /// Dopo quanto tempo in secondo piano l'archivio si blocca (`null` = mai).
  Duration? get bloccoAutomatico => _bloccoAutomatico;

  /// Messaggio da mostrare una volta (es. sblocco rapido spento dal sistema).
  String? prendiAvviso() {
    final avviso = _avviso;
    if (avviso != null) {
      _avviso = null;
      _salva().ignore();
    }
    return avviso;
  }

  /// Legge il file e chiede al dispositivo cosa offre.
  Future<void> carica() async {
    leggi();
    await aggiornaDisponibilita();
  }

  /// Il dispositivo può essere cambiato nel frattempo (es. impronta aggiunta).
  Future<void> aggiornaDisponibilita() async {
    final disponibilita = await _cassaforte.disponibilita();
    if (disponibilita != _disponibilita) {
      _disponibilita = disponibilita;
      notifyListeners();
    }
  }

  /// Attiva lo sblocco rapido per l'archivio aperto: chiede subito la
  /// verifica. Lancia [VerificaAnnullata] se l'utente rinuncia.
  Future<void> attivaRapido(SecureKey dek, String idArchivio) async {
    final sfida = _sodium.randombytes.buf(32);
    final esito = await _cassaforte.attiva(sfida);
    final chiave = _chiave(esito.materiale);
    final Uint8List avvolta;
    try {
      avvolta = dek.runUnlockedSync(
        (byte) => Cifratore(_sodium).cifra(byte, chiave, aad: _aad(idArchivio)),
      );
    } finally {
      chiave.dispose();
    }
    _rapido = _Rapido(
      idArchivio: idArchivio,
      sfida: sfida,
      dati: esito.dati,
      dek: avvolta,
    );
    _ultimaPassword ??= _adesso();
    _avviso = null;
    await _salva();
    notifyListeners();
  }

  /// La chiave dei dati dopo impronta, viso, PIN o Windows Hello; `null` se
  /// l'utente annulla. Lancia [ChiaveDispositivoAnnullata] (sblocco rapido
  /// spento: serve la password) o [VerificaBloccata].
  Future<SecureKey?> apriRapido(String idArchivio) async {
    final rapido = _rapido;
    if (rapido == null) {
      return null;
    }
    final Uint8List materiale;
    try {
      materiale = await _cassaforte.leggi(rapido.sfida, rapido.dati);
    } on VerificaAnnullata {
      return null;
    } on ChiaveDispositivoAnnullata {
      await _spegniDalSistema();
      rethrow;
    }
    final chiave = _chiave(materiale);
    try {
      final byte = Cifratore(_sodium)
          .decifra(rapido.dek, chiave, aad: _aad(idArchivio));
      try {
        return SecureKey.fromList(_sodium, byte);
      } finally {
        byte.fillRange(0, byte.length, 0);
      }
    } on CryptoException {
      // Archivio diverso o chiave del dispositivo cambiata.
      await _spegniDalSistema();
      throw const ChiaveDispositivoAnnullata();
    } finally {
      chiave.dispose();
    }
  }

  Future<void> disattivaRapido() async {
    if (_rapido == null) {
      return;
    }
    _rapido = null;
    await _cassaforte.disattiva();
    await _salva();
    notifyListeners();
  }

  /// L'utente ha appena aperto l'archivio con la password.
  Future<void> passwordUsata() async {
    _ultimaPassword = _adesso();
    await _salva();
    notifyListeners();
  }

  /// La proposta è comparsa: non si ripete, qualunque sia la risposta
  /// ("Non ora", Indietro, verifica annullata o non riuscita). Lo sblocco
  /// rapido resta attivabile dalle Impostazioni.
  Future<void> segnaPropostaFatta() async {
    _propostaFatta = true;
    await _salva();
    notifyListeners();
  }

  Future<void> impostaBloccoAutomatico(Duration? durata) async {
    _bloccoAutomatico = durata;
    await _salva();
    notifyListeners();
  }

  // ------------------------------------------------------------- interni

  Future<void> _spegniDalSistema() async {
    _rapido = null;
    _avviso =
        'Lo sblocco rapido si è spento perché sul dispositivo sono cambiati '
        'il blocco schermo o le impronte. Entra con la password: poi puoi '
        'riattivarlo dalle Impostazioni.';
    await _cassaforte.disattiva();
    await _salva();
    notifyListeners();
  }

  /// Chiave da 256 bit dal segreto della cassaforte (32 byte su Android, la
  /// firma di Windows Hello sul PC).
  SecureKey _chiave(Uint8List materiale) {
    final impronta = _sodium.crypto.genericHash(message: materiale, outLen: 32);
    materiale.fillRange(0, materiale.length, 0);
    final master = SecureKey.fromList(_sodium, impronta);
    impronta.fillRange(0, impronta.length, 0);
    try {
      return _sodium.crypto.kdf.deriveFromKey(
        masterKey: master,
        context: 'GFrapid1',
        subkeyId: BigInt.one,
        subkeyLen: 32,
      );
    } finally {
      master.dispose();
    }
  }

  static Uint8List _aad(String idArchivio) =>
      utf8.encode('gf-sblocco-rapido|v$_versione|$idArchivio');

  /// Legge il file (senza chiedere nulla al dispositivo).
  void leggi() {
    if (!_file.existsSync()) {
      return;
    }
    try {
      final json = jsonDecode(_file.readAsStringSync());
      if (json is! Map<String, Object?> || json['v'] != _versione) {
        return;
      }
      final secondi = json['bloccoAutomatico'];
      _bloccoAutomatico = switch (secondi) {
        final int s when s < 0 => null,
        final int s => Duration(seconds: s),
        _ => bloccoPredefinito,
      };
      // Nome storico della chiave: vale per ogni proposta già fatta.
      _propostaFatta = json['propostaRifiutata'] == true;
      final ultima = json['ultimaPassword'];
      _ultimaPassword = ultima is String ? DateTime.tryParse(ultima) : null;
      final avviso = json['avviso'];
      _avviso = avviso is String ? avviso : null;
      final rapido = json['rapido'];
      _rapido = rapido is Map<String, Object?> ? _Rapido.daJson(rapido) : null;
    } on FormatException {
      // File danneggiato: si riparte dai valori predefiniti (serve la password).
      _rapido = null;
    }
  }

  /// Scrittura atomica: prima un file temporaneo, poi la sostituzione.
  Future<void> _salva() async {
    final json = jsonEncode({
      'v': _versione,
      'bloccoAutomatico': _bloccoAutomatico?.inSeconds ?? -1,
      'propostaRifiutata': _propostaFatta,
      'ultimaPassword': _ultimaPassword?.toUtc().toIso8601String(),
      'avviso': _avviso,
      'rapido': _rapido?.toJson(),
    });
    await _file.parent.create(recursive: true);
    final temporaneo = File('${_file.path}.tmp');
    await temporaneo.writeAsString(json, flush: true);
    await temporaneo.rename(_file.path);
  }
}

/// Sblocco rapido attivo: la chiave dei dati avvolta e ciò che serve alla
/// cassaforte per rilasciare di nuovo il segreto.
class _Rapido {
  const _Rapido({
    required this.idArchivio,
    required this.sfida,
    required this.dati,
    required this.dek,
  });

  /// Lancia [FormatException] se i dati non sono validi.
  factory _Rapido.daJson(Map<String, Object?> json) {
    final id = json['id'];
    final sfida = json['sfida'];
    final dati = json['dati'];
    final dek = json['dek'];
    if (id is! String ||
        sfida is! String ||
        dati is! String ||
        dek is! String) {
      throw const FormatException('Sblocco rapido non valido');
    }
    return _Rapido(
      idArchivio: id,
      sfida: base64.decode(sfida),
      dati: base64.decode(dati),
      dek: base64.decode(dek),
    );
  }

  final String idArchivio;
  final Uint8List sfida;
  final Uint8List dati;
  final Uint8List dek;

  Map<String, Object?> toJson() => {
    'id': idArchivio,
    'sfida': base64.encode(sfida),
    'dati': base64.encode(dati),
    'dek': base64.encode(dek),
  };
}
