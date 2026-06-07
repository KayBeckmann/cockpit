/// Globale Konstanten für Cockpit.
///
/// Umgebungsspezifische Werte (API-Basis-URL, Secrets) kommen aus `.env`
/// (siehe ADR-0003) und werden hier nicht hartkodiert.
class AppConstants {
  AppConstants._();

  static const String appName = 'Cockpit';

  /// Basis-URL des Backends. Per `--dart-define=API_BASE_URL=...` überschreibbar
  /// (z. B. für Staging/Produktion); im lokalen Dev-Setup zeigt sie auf den
  /// `BACKEND_PORT` aus `.env.example`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8085',
  );
}
