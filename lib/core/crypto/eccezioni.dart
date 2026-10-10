/// Errori del modulo crittografico. I messaggi sono pensati per essere mostrati all'utente.
sealed class CryptoException implements Exception {
  const CryptoException(this.messaggio);

  final String messaggio;

  @override
  String toString() => '$runtimeType: $messaggio';
}

/// Il blob non si decifra: dati manomessi, danneggiati, chiave sbagliata
/// o dati spostati in un altro contesto (altro dispositivo, altra sequenza).
final class DatiNonValidiException extends CryptoException {
  const DatiNonValidiException([
    super.messaggio =
        'I dati sono danneggiati o non appartengono a questo archivio.',
  ]);
}

/// Il blob o il keyring dichiarano una versione di algoritmo che questa app non conosce
/// (es. creati da una versione più recente).
final class VersioneNonSupportataException extends CryptoException {
  const VersioneNonSupportataException(int versione)
    : super('Formato dati versione $versione non supportato: aggiorna l\'app.');
}

final class PasswordErrataException extends CryptoException {
  const PasswordErrataException() : super('Password errata.');
}

final class RecoveryKeyNonValidaException extends CryptoException {
  const RecoveryKeyNonValidaException(super.messaggio);
}

/// Parametri di derivazione più deboli del minimo ammesso (possibile manomissione).
final class ParametriNonSicuriException extends CryptoException {
  const ParametriNonSicuriException(super.messaggio);
}
