import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Larghezze di riferimento (classi di finestra di Material 3), le stesse per
/// telefono, tablet e PC.
abstract final class Larghezze {
  /// Da qui (tablet in verticale, telefono in orizzontale): barra laterale
  /// invece della barra in basso.
  static const media = 600.0;

  /// Da qui (tablet in orizzontale, PC): due colonne.
  static const ampia = 840.0;

  /// Larghezza massima di una pagina a una colonna: oltre, le righe diventano
  /// troppo lunghe da leggere.
  static const lettura = 960.0;

  /// Larghezza massima delle pagine a due colonne.
  static const dueColonne = 1440.0;
}

/// Margini di una pagina a una colonna: 16 sui lati, di più sugli schermi
/// larghi, così il contenuto resta al centro (largo al massimo
/// [Larghezze.lettura]) e si scorre comunque da tutta la finestra.
EdgeInsets marginiPagina(
  BoxConstraints vincoli, {
  double sopra = 16,
  double sotto = 96,
}) {
  final lato = math.max(16.0, (vincoli.maxWidth - Larghezze.lettura) / 2);
  return EdgeInsets.fromLTRB(lato, sopra, lato, sotto);
}

/// Contenuto centrato con una larghezza massima: sui tablet in orizzontale e
/// sui PC la pagina non si stira da un bordo all'altro.
class ContenutoCentrato extends StatelessWidget {
  const ContenutoCentrato({
    super.key,
    required this.child,
    this.larghezzaMassima = Larghezze.lettura,
  });

  final Widget child;
  final double larghezzaMassima;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larghezzaMassima),
        child: child,
      ),
    );
  }
}

/// Elenco di schede: una colonna su telefono e tablet in verticale, due
/// colonne da [Larghezze.ampia] in su. [intestazione] sta sopra, a tutta
/// larghezza.
class ElencoSchede extends StatelessWidget {
  const ElencoSchede({
    super.key,
    required this.schede,
    this.intestazione = const [],
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 96),
  });

  final List<Widget> schede;
  final List<Widget> intestazione;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth < Larghezze.ampia || schede.length < 2) {
          return ListView(
            padding: marginiPagina(
              vincoli,
              sopra: padding.top,
              sotto: padding.bottom,
            ),
            children: [...intestazione, ...schede],
          );
        }
        // Due colonne: le schede si alternano (1ª a sinistra, 2ª a destra...).
        return SingleChildScrollView(
          padding: padding,
          child: ContenutoCentrato(
            larghezzaMassima: Larghezze.dueColonne,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...intestazione,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final colonna in [0, 1]) ...[
                      if (colonna == 1) const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = colonna; i < schede.length; i += 2)
                              schede[i],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
