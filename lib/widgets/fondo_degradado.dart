import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Fondo con degradado suave que usan todas las pantallas
class FondoDegradado extends StatelessWidget {
  final Widget child;

  const FondoDegradado({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final esClaro = Theme.of(context).brightness == Brightness.light;

    // Mezcla un color suave sobre el fondo para que sea opaco
    Color suave(Color color, double opacidad) =>
        Color.alphaBlend(color.withValues(alpha: opacidad), colores.surface);

    // AnnotatedRegion: íconos de la barra de estado legibles
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: esClaro ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              suave(colores.primaryContainer, 0.6),
              colores.surface,
              suave(colores.tertiaryContainer, 0.5),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
