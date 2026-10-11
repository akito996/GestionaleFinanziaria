import 'package:flutter/material.dart';

import '../../core/versione.dart';
import 'navigazione.dart';

/// La versione come una firma: piccola, poco contrastata, in basso a sinistra.
/// Va messa a tutto schermo ([Positioned.fill]): si allinea da sola.
/// Non intercetta tocchi e clic (sta sopra tutte le schermate). Sul telefono
/// sta appena sopra la barra di navigazione, per non toccarne le etichette.
class FirmaVersione extends StatelessWidget {
  const FirmaVersione({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Stessa regola della navigazione: si misura lo spazio reale disponibile.
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, vincoli) => Align(
          alignment: Alignment.bottomLeft,
          child: SafeArea(
            top: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                0,
                8,
                vincoli.maxWidth < larghezzaBarraLaterale
                    ? (NavigationBarTheme.of(context).height ?? 80) + 2
                    : 3,
              ),
              child: DefaultTextStyle(
                style: tema.textTheme.labelSmall!.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.3,
                  color: tema.colorScheme.onSurface.withValues(alpha: 0.38),
                  decoration: TextDecoration.none,
                ),
                child: Text(
                  Versione.firma,
                  semanticsLabel: 'Versione ${Versione.numero}',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
