import 'package:flutter/material.dart';

/// Material-3-Theme für Cockpit in Hell- und Dunkelvariante.
///
/// Eine Seed-Farbe erzeugt über `ColorScheme.fromSeed` ein konsistentes
/// Farbschema für beide Varianten — Anpassungen erfolgen zentral hier.
abstract final class AppTheme {
  static const Color _seedColor = Colors.teal;

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );
}
