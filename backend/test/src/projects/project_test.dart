import 'package:backend/src/projects/project.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('Project.fromRow', () {
    test('mappt eine Zeile in der erwarteten Spaltenreihenfolge', () {
      final createdAt = DateTime.utc(2026, 6, 1, 8);
      final updatedAt = DateTime.utc(2026, 6, 2, 9);

      final row = ResultRow(
        values: [
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'Solaranlage planen',
          'hobby',
          'aktiv',
          25,
          [
            {'titel': 'Module bestellen', 'erledigt': true},
          ],
          {'budget': 2000},
          'privat',
          'obsidian://vault/Solaranlage',
          createdAt,
          updatedAt,
        ],
        schema: ResultSchema([]),
      );

      final project = Project.fromRow(row);

      expect(project.id, equals('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'));
      expect(project.titel, equals('Solaranlage planen'));
      expect(project.typ, equals('hobby'));
      expect(project.status, equals('aktiv'));
      expect(project.fortschritt, equals(25));
      expect(project.meilensteine, isA<List<dynamic>>());
      expect(project.ressourcen, equals({'budget': 2000}));
      expect(project.kontext, equals('privat'));
      expect(project.obsidianUri, equals('obsidian://vault/Solaranlage'));
      expect(project.createdAt, equals(createdAt));
      expect(project.updatedAt, equals(updatedAt));
    });

    test('lässt optionale Felder bei NULL-Werten leer', () {
      final timestamp = DateTime.utc(2026, 6, 7);

      final row = ResultRow(
        values: [
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'Minimalprojekt',
          null,
          'aktiv',
          0,
          null,
          null,
          'arbeit',
          null,
          timestamp,
          timestamp,
        ],
        schema: ResultSchema([]),
      );

      final project = Project.fromRow(row);

      expect(project.typ, isNull);
      expect(project.meilensteine, isNull);
      expect(project.ressourcen, isNull);
      expect(project.obsidianUri, isNull);
    });
  });

  group('Project.toJson', () {
    test('serialisiert Zeitstempel als ISO-8601 mit camelCase-Schlüsseln', () {
      final timestamp = DateTime.utc(2026, 6, 1, 12);
      final project = Project(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        titel: 'Test',
        status: 'aktiv',
        fortschritt: 10,
        kontext: 'privat',
        obsidianUri: 'obsidian://vault/Test',
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      final json = project.toJson();

      expect(json['obsidianUri'], equals('obsidian://vault/Test'));
      expect(json['createdAt'], equals('2026-06-01T12:00:00.000Z'));
      expect(json.containsKey('obsidian_uri'), isFalse);
    });
  });
}
