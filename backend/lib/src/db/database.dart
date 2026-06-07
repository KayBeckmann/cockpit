import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Verbindungsdaten aus `.env` — Defaults passen zum lokalen
/// Docker-Compose-Setup, Produktion überschreibt per Plattform-Umgebung.
class DatabaseConfig {
  /// Erstellt eine Konfiguration aus expliziten Werten.
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  /// Liest die Konfiguration aus geladenen Umgebungsvariablen, mit
  /// Defaults, die zum lokalen Docker-Compose-Setup passen.
  factory DatabaseConfig.fromEnv(DotEnv env) => DatabaseConfig(
    host: env['DB_HOST'] ?? 'localhost',
    port: int.tryParse(env['DB_PORT'] ?? '') ?? 5432,
    database: env['DB_NAME'] ?? 'cockpit',
    username: env['DB_USER'] ?? 'cockpit',
    password: env['DB_PASSWORD'] ?? 'cockpit',
  );

  /// Hostname des PostgreSQL-Servers.
  final String host;

  /// Port des PostgreSQL-Servers.
  final int port;

  /// Name der Datenbank.
  final String database;

  /// Benutzername für die Verbindung.
  final String username;

  /// Passwort für die Verbindung.
  final String password;

  /// Endpoint-Repräsentation für `package:postgres`.
  Endpoint get endpoint => Endpoint(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
  );
}

/// Cached Connection-Future — eine Verbindung pro Prozess statt pro Request.
Future<Connection>? _connectionFuture;

/// Öffnet (oder liefert die bereits bestehende) Datenbankverbindung.
Future<Connection> openConnection(DatabaseConfig config) {
  return _connectionFuture ??= Connection.open(
    config.endpoint,
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
}
