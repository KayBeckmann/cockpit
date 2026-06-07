import 'package:backend/src/tasks/task.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('Task.fromRow', () {
    test('mappt eine Zeile in der erwarteten Spaltenreihenfolge', () {
      final createdAt = DateTime.utc(2026, 6, 1, 8);
      final updatedAt = DateTime.utc(2026, 6, 2, 9);
      final deadline = DateTime.utc(2026, 6, 10);

      final row = ResultRow(
        values: [
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'Wäsche waschen',
          'Feinwäsche separat',
          deadline,
          2,
          'aktiv',
          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          'privat',
          {'typ': 'woechentlich', 'intervall': 1},
          'niedrig',
          ['haushalt', 'routine'],
          [
            {'titel': 'Sortieren', 'erledigt': false},
          ],
          createdAt,
          updatedAt,
        ],
        schema: ResultSchema([]),
      );

      final task = Task.fromRow(row);

      expect(task.id, equals('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'));
      expect(task.titel, equals('Wäsche waschen'));
      expect(task.beschreibung, equals('Feinwäsche separat'));
      expect(task.deadline, equals(deadline));
      expect(task.prioritaet, equals(2));
      expect(task.status, equals('aktiv'));
      expect(task.projektId, equals('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'));
      expect(task.kontext, equals('privat'));
      expect(
        task.wiederholung,
        equals({'typ': 'woechentlich', 'intervall': 1}),
      );
      expect(task.energieLevel, equals('niedrig'));
      expect(task.tags, equals(['haushalt', 'routine']));
      expect(task.teilaufgaben, isA<List<dynamic>>());
      expect(task.createdAt, equals(createdAt));
      expect(task.updatedAt, equals(updatedAt));
    });

    test('lässt optionale Felder bei NULL-Werten leer (Quick-Capture)', () {
      final timestamp = DateTime.utc(2026, 6, 7);

      final row = ResultRow(
        values: [
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'Spontane Idee',
          null,
          null,
          null,
          'inbox',
          null,
          null,
          null,
          null,
          null,
          null,
          timestamp,
          timestamp,
        ],
        schema: ResultSchema([]),
      );

      final task = Task.fromRow(row);

      expect(task.kontext, isNull);
      expect(task.projektId, isNull);
      expect(task.tags, isNull);
      expect(task.status, equals('inbox'));
    });
  });

  group('Task.toJson', () {
    test('serialisiert Zeitstempel als ISO-8601 mit camelCase-Schlüsseln', () {
      final timestamp = DateTime.utc(2026, 6, 1, 12);
      final task = Task(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        titel: 'Test',
        status: 'inbox',
        projektId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        energieLevel: 'hoch',
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      final json = task.toJson();

      expect(json['projektId'], equals('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'));
      expect(json['energieLevel'], equals('hoch'));
      expect(json['createdAt'], equals('2026-06-01T12:00:00.000Z'));
      expect(json.containsKey('projekt_id'), isFalse);
    });
  });
}
