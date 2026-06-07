import 'package:backend/src/links/link.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('Link.fromRow', () {
    test('mappt eine Zeile in der erwarteten Spaltenreihenfolge', () {
      final createdAt = DateTime.utc(2026, 6, 7, 8);

      final row = ResultRow(
        values: [
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'task',
          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          'project',
          'cccccccc-cccc-cccc-cccc-cccccccccccc',
          'gehört zu',
          createdAt,
        ],
        schema: ResultSchema([]),
      );

      final link = Link.fromRow(row);

      expect(link.id, equals('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'));
      expect(link.vonTyp, equals('task'));
      expect(link.vonId, equals('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'));
      expect(link.zuTyp, equals('project'));
      expect(link.zuId, equals('cccccccc-cccc-cccc-cccc-cccccccccccc'));
      expect(link.beziehung, equals('gehört zu'));
      expect(link.createdAt, equals(createdAt));
    });

    test('lässt beziehung bei NULL-Wert leer', () {
      final createdAt = DateTime.utc(2026, 6, 7, 8);

      final row = ResultRow(
        values: [
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'task',
          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          'project',
          'cccccccc-cccc-cccc-cccc-cccccccccccc',
          null,
          createdAt,
        ],
        schema: ResultSchema([]),
      );

      final link = Link.fromRow(row);

      expect(link.beziehung, isNull);
    });
  });

  group('Link.toJson', () {
    test('serialisiert Zeitstempel als ISO-8601 mit camelCase-Schlüsseln', () {
      final timestamp = DateTime.utc(2026, 6, 1, 12);
      final link = Link(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        vonTyp: 'task',
        vonId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        zuTyp: 'project',
        zuId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        beziehung: 'gehört zu',
        createdAt: timestamp,
      );

      final json = link.toJson();

      expect(json['vonTyp'], equals('task'));
      expect(json['zuId'], equals('cccccccc-cccc-cccc-cccc-cccccccccccc'));
      expect(json['createdAt'], equals('2026-06-01T12:00:00.000Z'));
      expect(json.containsKey('von_typ'), isFalse);
    });
  });
}
