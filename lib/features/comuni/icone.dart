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
