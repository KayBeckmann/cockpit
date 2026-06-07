/// Globale Konstanten für Cockpit.
///
/// Umgebungsspezifische Werte (API-Basis-URL, Secrets) kommen aus `.env`
/// (siehe ADR-0003) und werden hier nicht hartkodiert.
class AppConstants {
  AppConstants._();

  static const String appName = 'Cockpit';
}
