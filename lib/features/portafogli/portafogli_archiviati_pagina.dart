import 'package:flutter/material.dart';

import '../../core/db/contabilita.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/avvisi.dart';
import '../comuni/layout.dart';
import 'elimina_portafoglio.dart';

/// Impostazioni › Portafogli archiviati: si ripristinano (tornano negli
/// elenchi con i loro movimenti) o si eliminano.
class PortafogliArchiviatiPagina extends StatefulWidget {
  const PortafogliArchiviatiPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<PortafogliArchiviatiPagina> createState() =>
      _PortafogliArchiviatiPaginaState();
}

class _PortafogliArchiviatiPaginaState
    extends State<PortafogliArchiviatiPagina> {
  late final Stream<List<PortafoglioConSaldo>> _archiviati = widget
      .sessione
      .contabilita
      .osservaPortafogli(archiviati: true);

  Future<void> _ripristina(PortafoglioConSaldo p) async {
    final c = widget.sessione.contabilita;
    await c.archiviaPortafoglio(p.portafoglio.id, archiviato: false);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: Text('"${p.portafoglio.nome}" di nuovo tra i portafogli'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () => c.archiviaPortafoglio(p.portafoglio.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portafogli archiviati')),
      body: StreamBuilder<List<PortafoglioConSaldo>>(
        stream: _archiviati,
        builder: (context, snapshot) {
          final elenco = snapshot.data;
          if (elenco == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli),
              children: [
                if (elenco.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.inventory_2_outlined),
                      title: Text('Nessun portafoglio archiviato'),
                      subtitle: Text(
                        'Quando archivi un portafoglio, sparisce dagli '
                        'elenchi ma resta qui con tutti i suoi movimenti.',
                      ),
                    ),
                  ),
                for (final p in elenco)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      title: Text(p.portafoglio.nome),
                      subtitle: Text(
                        '${p.tipo.nome} · '
                        '${Importo.formatta(p.saldo, p.portafoglio.valuta)}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Ripristina',
                            icon: const Icon(Icons.unarchive_outlined),
                            onPressed: () => _ripristina(p),
                          ),
                          IconButton(
                            tooltip: 'Elimina',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => apriEliminaPortafoglio(
                              context,
                              widget.sessione,
                              p.portafoglio,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
