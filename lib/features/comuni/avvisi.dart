import 'package:flutter/material.dart';

/// Per quanto resta visibile un avviso in basso.
const durataAvviso = Duration(seconds: 5);

/// Avviso in basso dell'app: sparisce da solo dopo [durataAvviso], anche
/// quando ha un pulsante ("Annulla"), e si chiude prima con la "x".
///
/// Usarlo al posto di `SnackBar(...)`: con un'azione Flutter lascerebbe
/// l'avviso aperto finché non lo chiudi a mano.
SnackBar avviso({
  required Widget content,
  SnackBarAction? action,
  Duration duration = durataAvviso,
}) => SnackBar(
  content: content,
  action: action,
  duration: duration,
  persist: false,
);
