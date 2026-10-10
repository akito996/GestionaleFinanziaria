import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/sessione.dart';

/// Schermata principale (provvisoria): conferma che l'archivio cifrato è aperto.
/// Portafogli e movimenti arrivano nel prossimo passo.
class HomePagina extends StatelessWidget {
  const HomePagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    final archivio = sessione.archivio;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GestionaleFinanziaria'),
        actions: [
          IconButton(
            tooltip: 'Blocca',
            icon: const Icon(Icons.lock),
            onPressed: sessione.blocca,
          ),
        ],
      ),
      body: FutureBuilder<List<DefinizioneTipo>>(
        future: archivio.select(archivio.definizioniTipo).get(),
        builder: (context, snapshot) {
          final tipi = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const ListTile(
                leading: Icon(Icons.verified_user),
                title: Text('Archivio aperto'),
                subtitle: Text(
                  'I dati sono cifrati con SQLCipher sul dispositivo.',
                ),
              ),
              const Divider(),
              for (final tipo in tipi)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.label_outline),
                  title: Text(tipo.nome),
                  subtitle: Text(tipo.ambito),
                ),
            ],
          );
        },
      ),
    );
  }
}
