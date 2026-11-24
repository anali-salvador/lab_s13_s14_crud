import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/lista_tareas_screen.dart';

void main() {
  runApp(const MyApp());
}

// Color base de la app (índigo / morado)
const _colorSemilla = Color(0xFF5B5BD6);

// Crea el tema claro u oscuro con el mismo estilo
ThemeData _crearTema(Brightness brillo) {
  final colores = ColorScheme.fromSeed(
    seedColor: _colorSemilla,
    brightness: brillo,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colores,
    // AppBar transparente y sin sombra
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colores.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // Íconos de la barra de estado legibles sobre el fondo
      systemOverlayStyle: brillo == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    ),
    // Campos de texto redondeados y rellenos
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colores.surfaceContainerHighest.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colores.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colores.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colores.error, width: 2),
      ),
    ),
    // SnackBars flotantes y redondeados
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colores.inverseSurface,
      contentTextStyle: TextStyle(color: colores.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Diálogos redondeados
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
  );
}

// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis tareas',
      debugShowCheckedModeBanner: false,
      theme: _crearTema(Brightness.light),
      darkTheme: _crearTema(Brightness.dark),
      themeMode: ThemeMode.system, // sigue el modo del celular
      // Textos de Material (calendario, botones) en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: const ListaTareasScreen(),
    );
  }
}
