import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/sessione.dart';

/// Schermata principale (provvisoria): conferma che l'archivio cifrato è aperto.
/// Portafogli e movimenti arrivano nel prossimo passo.
class HomePagina extends StatefulWidget {
  const HomePagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<HomePagina> createState() => _HomePaginaState();
}

class _HomePaginaState extends State<HomePagina> {
  late final Future<List<DefinizioneTipo>> _tipi;

  @override
  void initState() {
    super.initState();
    final archivio = widget.sessione.archivio;
    _tipi = archivio.select(archivio.definizioniTipo).get();

    // Conferma visibile dell'apertura ("Archivio sbloccato", "Archivio creato", ...).
    final avviso = widget.sessione.avviso;
    widget.sessione.avviso = null;
    if (avviso != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.lock_open, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(avviso),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GestionaleFinanziaria'),
        actions: [
          IconButton(
            tooltip: 'Archivio aperto: tocca per bloccarlo',
            icon: const Icon(Icons.lock_open),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              widget.sessione.blocca();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DefinizioneTipo>>(
        future: _tipi,
        builder: (context, snapshot) {
          final tipi = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text('Archivio aperto'),
                subtitle: Text(
                  'ID ${widget.sessione.idArchivio ?? ''} · '
                  'dati cifrati con SQLCipher sul dispositivo',
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
