import 'dart:io';

import 'package:backend/src/db/database.dart';
import 'package:backend/src/env/env.dart';
import 'package:postgres/postgres.dart';

/// Einfacher Migrationsrunner: führt SQL-Dateien aus `migrations/` in
/// alphabetischer Reihenfolge aus und merkt sich den Stand in der
/// Tabelle `schema_migrations`. Aufruf (aus `backend/`):
///
/// ```sh
/// dart run bin/migrate.dart
/// ```
Future<void> main() async {
  final env = loadEnv();
  final connection = await openConnection(DatabaseConfig.fromEnv(env));

  await connection.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  ''');

  final appliedRows = await connection.execute(
    'SELECT version FROM schema_migrations',
  );
  final appliedVersions = appliedRows.map((row) => row[0]! as String).toSet();

  final files =
      Directory('migrations').listSync().whereType<File>().where(
        (file) => file.path.endsWith('.sql'),
      ).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final version = file.uri.pathSegments.last;
    if (appliedVersions.contains(version)) {
      stdout.writeln('skip  $version (bereits angewendet)');
      continue;
    }

    stdout.writeln('apply $version');
    final sql = await file.readAsString();
    await connection.runTx((session) async {
      // Simple Query Protocol: Migrationsdateien dürfen mehrere
      // Anweisungen enthalten, was Prepared Statements nicht erlauben.
      await session.execute(Sql(sql), queryMode: QueryMode.simple);
      await session.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@version)'),
        parameters: {'version': version},
      );
    });
  }

  await connection.close();
  stdout.writeln('Migrationen abgeschlossen.');
}
