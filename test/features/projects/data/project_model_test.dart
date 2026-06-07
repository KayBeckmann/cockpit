import 'package:cockpit/features/projects/data/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project.fromJson', () {
    test('parst Pflichtfelder und lässt optionale Felder null', () {
      final project = Project.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'titel': 'Gartenhaus bauen',
        'status': 'aktiv',
        'fortschritt': 0,
        'kontext': 'privat',
        'createdAt': '2026-06-07T08:00:00.000Z',
        'updatedAt': '2026-06-07T08:00:00.000Z',
      });

      expect(project.id, equals('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'));
      expect(project.titel, equals('Gartenhaus bauen'));
      expect(project.status, equals('aktiv'));
      expect(project.fortschritt, equals(0));
      expect(project.kontext, equals('privat'));
      expect(project.createdAt, equals(DateTime.utc(2026, 6, 7, 8)));
      expect(project.typ, isNull);
      expect(project.meilensteine, isNull);
      expect(project.ressourcen, isNull);
      expect(project.obsidianUri, isNull);
    });

    test('parst alle optionalen Felder, wenn vorhanden', () {
      final project = Project.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'titel': 'Cockpit',
        'typ': 'hobby',
        'status': 'aktiv',
        'fortschritt': 42,
        'meilensteine': [
          {'titel': 'M1', 'erledigt': false},
        ],
        'ressourcen': {'budget': 500},
        'kontext': 'privat',
        'obsidianUri': 'obsidian://open?vault=Vault&file=Cockpit',
        'createdAt': '2026-06-07T08:00:00.000Z',
        'updatedAt': '2026-06-07T09:30:00.000Z',
      });

      expect(project.typ, equals('hobby'));
      expect(project.fortschritt, equals(42));
      expect(project.meilensteine, isNotNull);
      expect(project.ressourcen, equals({'budget': 500}));
      expect(project.obsidianUri, equals('obsidian://open?vault=Vault&file=Cockpit'));
      expect(project.updatedAt, equals(DateTime.utc(2026, 6, 7, 9, 30)));
    });
  });
}
