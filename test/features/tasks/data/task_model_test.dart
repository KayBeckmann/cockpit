import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task.fromJson', () {
    test('parst Pflichtfelder und lässt optionale Felder null', () {
      final task = Task.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'titel': 'Wäsche waschen',
        'status': 'inbox',
        'createdAt': '2026-06-07T08:00:00.000Z',
        'updatedAt': '2026-06-07T08:00:00.000Z',
      });

      expect(task.id, equals('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'));
      expect(task.titel, equals('Wäsche waschen'));
      expect(task.status, equals('inbox'));
      expect(task.createdAt, equals(DateTime.utc(2026, 6, 7, 8)));
      expect(task.beschreibung, isNull);
      expect(task.deadline, isNull);
      expect(task.kontext, isNull);
      expect(task.wiederholung, isNull);
      expect(task.tags, isNull);
    });

    test('parst alle optionalen Felder, wenn vorhanden', () {
      final task = Task.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'titel': 'Steuererklärung',
        'beschreibung': 'Belege sammeln',
        'deadline': '2026-07-31T22:00:00.000Z',
        'prioritaet': 3,
        'status': 'aktiv',
        'projektId': 'pppppppp-pppp-pppp-pppp-pppppppppppp',
        'kontext': 'privat',
        'wiederholung': {'typ': 'jaehrlich', 'intervall': 1},
        'energieLevel': 'hoch',
        'tags': ['finanzen', 'papierkram'],
        'teilaufgaben': [
          {'titel': 'Belege sortieren', 'erledigt': false},
        ],
        'createdAt': '2026-06-07T08:00:00.000Z',
        'updatedAt': '2026-06-07T09:30:00.000Z',
      });

      expect(task.beschreibung, equals('Belege sammeln'));
      expect(task.deadline, equals(DateTime.utc(2026, 7, 31, 22)));
      expect(task.prioritaet, equals(3));
      expect(task.projektId, equals('pppppppp-pppp-pppp-pppp-pppppppppppp'));
      expect(task.kontext, equals('privat'));
      expect(task.wiederholung, equals({'typ': 'jaehrlich', 'intervall': 1}));
      expect(task.energieLevel, equals('hoch'));
      expect(task.tags, equals(['finanzen', 'papierkram']));
      expect(task.teilaufgaben, isNotNull);
      expect(task.updatedAt, equals(DateTime.utc(2026, 6, 7, 9, 30)));
    });
  });
}
