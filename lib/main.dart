import 'package:flutter/material.dart';
import 'package:sodium/sodium_sumo.dart';

import 'app.dart';
import 'core/db/deposito_locale.dart';
import 'core/sessione.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessione = Sessione(
    sodium: await SodiumSumoInit.init(),
    deposito: await DepositoLocale.predefinito(),
  );
  runApp(GestionaleApp(sessione: sessione));
  await sessione.avvia();
}
