import 'package:flutter/material.dart';

/// Lucchetto aperto disegnato su misura: l'arco è spostato a destra, fuori dal corpo,
/// così si capisce a colpo d'occhio che l'archivio è aperto (l'icona Material
/// standard sembra chiusa nelle dimensioni piccole).
class LucchettoAperto extends StatelessWidget {
  const LucchettoAperto({super.key, this.dimensione, this.colore});

  final double? dimensione;
  final Color? colore;

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final lato = dimensione ?? tema.size ?? 24;
    return SizedBox.square(
      dimension: lato,
      child: CustomPaint(
        painter: _LucchettoApertoPainter(
          colore ?? tema.color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _LucchettoApertoPainter extends CustomPainter {
  _LucchettoApertoPainter(this.colore);

  final Color colore;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final pieno = Paint()..color = colore;
    final tratto = Paint()
      ..color = colore
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round;

    // Corpo, spostato a sinistra.
    final corpo = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.06, s * 0.46, s * 0.56, s * 0.46),
      Radius.circular(s * 0.08),
    );

    // Foro della chiave: ritagliato dal corpo (si vede lo sfondo).
    final foro = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRRect(corpo, pieno);
    canvas.drawCircle(Offset(s * 0.34, s * 0.64), s * 0.06, foro);
    canvas.drawRect(
      Rect.fromLTWH(s * 0.315, s * 0.66, s * 0.05, s * 0.12),
      foro,
    );
    canvas.restore();

    // Arco aperto: spostato a destra, fuori dal corpo, con una sola gamba agganciata.
    final arco = Path()
      ..moveTo(s * 0.52, s * 0.46)
      ..lineTo(s * 0.52, s * 0.3)
      ..arcToPoint(Offset(s * 0.9, s * 0.3), radius: Radius.circular(s * 0.19))
      ..lineTo(s * 0.9, s * 0.4);
    canvas.drawPath(arco, tratto);
  }

  @override
  bool shouldRepaint(_LucchettoApertoPainter vecchio) =>
      vecchio.colore != colore;
}

/// Icona "Esporta": documento con le righe e una freccia che ne esce a destra.
/// Stesso stile delle icone Material a contorno (tratto 2 su griglia 24).
class IconaEsporta extends StatelessWidget {
  const IconaEsporta({super.key, this.dimensione, this.colore});

  final double? dimensione;
  final Color? colore;

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final lato = dimensione ?? tema.size ?? 24;
    return SizedBox.square(
      dimension: lato,
      child: CustomPaint(
        painter: _IconaEsportaPainter(
          colore ?? tema.color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _IconaEsportaPainter extends CustomPainter {
  _IconaEsportaPainter(this.colore);

  final Color colore;

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate sulla griglia 24 × 24 delle icone Material.
    final u = size.width / 24;
    Offset p(double x, double y) => Offset(x * u, y * u);
    final tratto = Paint()
      ..color = colore
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Documento: il lato destro si interrompe dove passa la freccia.
    final documento = Path()
      ..moveTo(15 * u, 9.5 * u)
      ..lineTo(15 * u, 4 * u)
      ..arcToPoint(p(13, 2), radius: Radius.circular(2 * u), clockwise: false)
      ..lineTo(5 * u, 2 * u)
      ..arcToPoint(p(3, 4), radius: Radius.circular(2 * u), clockwise: false)
      ..lineTo(3 * u, 20 * u)
      ..arcToPoint(p(5, 22), radius: Radius.circular(2 * u), clockwise: false)
      ..lineTo(13 * u, 22 * u)
      ..arcToPoint(p(15, 20), radius: Radius.circular(2 * u), clockwise: false)
      ..lineTo(15 * u, 14.5 * u);
    canvas.drawPath(documento, tratto);

    // Righe del testo: la prima lunga, le altre corte (lasciano posto alla freccia).
    canvas
      ..drawLine(p(6.5, 6), p(11.5, 6), tratto)
      ..drawLine(p(6.5, 10), p(8.5, 10), tratto)
      ..drawLine(p(6.5, 14), p(8.5, 14), tratto)
      ..drawLine(p(6.5, 18), p(11.5, 18), tratto);

    // Freccia verso destra che esce dal documento.
    canvas.drawLine(p(11, 12), p(21.5, 12), tratto);
    final punta = Path()
      ..moveTo(18 * u, 8.5 * u)
      ..lineTo(21.5 * u, 12 * u)
      ..lineTo(18 * u, 15.5 * u);
    canvas.drawPath(punta, tratto);
  }

  @override
  bool shouldRepaint(_IconaEsportaPainter vecchio) => vecchio.colore != colore;
}
