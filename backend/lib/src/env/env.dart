import 'dart:io';

import 'package:dotenv/dotenv.dart';

/// Lädt Konfiguration aus `.env` (Repo-Root, siehe `.env.example`) und
/// merged sie mit der Plattform-Umgebung — Werte aus `Platform.environment`
/// (z. B. in Docker gesetzt) haben Vorrang. Keine Secrets im Repo (ADR-0003).
DotEnv loadEnv() {
  final env = DotEnv(includePlatformEnvironment: true);
  for (final path in ['.env', '../.env']) {
    if (File(path).existsSync()) {
      env.load([path]);
      break;
    }
  }
  return env;
}
