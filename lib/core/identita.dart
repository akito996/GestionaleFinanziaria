/// Nome dell'app e autore (ADR-018), in un solo posto.
///
/// Sono solo testi visibili: gli identificativi tecnici (id dell'app Android
/// `io.github.akito996.gestionale_finanziaria`, contesti crittografici, nomi
/// dei canali nativi) restano quelli storici e non vanno cambiati.
abstract final class Identita {
  static const nome = 'WalleCy';

  /// Autore (nome d'arte), nella firma, nei metadati e nel copyright.
  static const autore = 'agjin';

  /// Anno della prima pubblicazione.
  static const anno = 2026;

  static const copyright = '© $anno $autore';

  /// Codice sorgente (licenza AGPL-3.0: chi usa l'app può averlo).
  static const indirizzoCodice = 'https://github.com/akito996/WalleCy';
}
