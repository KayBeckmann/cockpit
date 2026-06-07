import 'package:backend/src/tasks/wiederholung.dart';
import 'package:test/test.dart';

void main() {
  group('parseWiederholung', () {
    test('liefert null für ein fehlendes Feld', () {
      expect(parseWiederholung(null), isNull);
    });

    test('parst eine gültige Regel ohne Enddatum', () {
      final wiederholung = parseWiederholung({
        'typ': 'taeglich',
        'intervall': 1,
      });

      expect(wiederholung, isNotNull);
      expect(wiederholung!.typ, equals('taeglich'));
      expect(wiederholung.intervall, equals(1));
      expect(wiederholung.bis, isNull);
    });

    test('parst eine gültige Regel mit Enddatum', () {
      final wiederholung = parseWiederholung({
        'typ': 'woechentlich',
        'intervall': 2,
        'bis': '2026-12-31T00:00:00.000Z',
      });

      expect(wiederholung, isNotNull);
      expect(wiederholung!.bis, equals(DateTime.utc(2026, 12, 31)));
    });

    test('lehnt einen unbekannten Typ ab', () {
      expect(
        () => parseWiederholung({'typ': 'stuendlich', 'intervall': 1}),
        throwsFormatException,
      );
    });

    test('lehnt ein nicht-positives Intervall ab', () {
      expect(
        () => parseWiederholung({'typ': 'taeglich', 'intervall': 0}),
        throwsFormatException,
      );
    });

    test('lehnt ein nicht parsbares Enddatum ab', () {
      expect(
        () => parseWiederholung({
          'typ': 'taeglich',
          'intervall': 1,
          'bis': 'kein-datum',
        }),
        throwsFormatException,
      );
    });

    test('lehnt einen Wert ab, der kein Objekt ist', () {
      expect(() => parseWiederholung('taeglich'), throwsFormatException);
    });
  });

  group('Wiederholung.toJson', () {
    test('lässt das Enddatum weg, wenn keines gesetzt ist', () {
      const wiederholung = Wiederholung(typ: 'taeglich', intervall: 1);

      expect(
        wiederholung.toJson(),
        equals({'typ': 'taeglich', 'intervall': 1}),
      );
    });

    test('serialisiert das Enddatum als ISO-8601', () {
      final wiederholung = Wiederholung(
        typ: 'monatlich',
        intervall: 1,
        bis: DateTime.utc(2026, 12, 31),
      );

      expect(
        wiederholung.toJson(),
        equals({
          'typ': 'monatlich',
          'intervall': 1,
          'bis': '2026-12-31T00:00:00.000Z',
        }),
      );
    });
  });
}
