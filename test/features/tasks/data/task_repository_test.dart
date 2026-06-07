import 'dart:convert';
import 'dart:io';

import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/core/network/api_client.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final taskJson = {
    'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'titel': 'Wäsche waschen',
    'status': 'inbox',
    'createdAt': '2026-06-07T08:00:00.000Z',
    'updatedAt': '2026-06-07T08:00:00.000Z',
  };

  TaskRepository repositoryFor(MockClientHandler handler) {
    return TaskRepository(ApiClient(httpClient: MockClient(handler)));
  }

  group('list', () {
    test('liefert die geparste Liste und reicht Filter als Query weiter', () async {
      late Uri requestedUri;
      final repository = repositoryFor((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode([taskJson]), HttpStatus.ok);
      });

      final result = await repository.list(
        kontext: 'privat',
        status: 'inbox',
        projektId: '42',
      );

      expect(requestedUri.path, equals('/tasks'));
      expect(
        requestedUri.queryParameters,
        equals({'kontext': 'privat', 'status': 'inbox', 'projekt_id': '42'}),
      );
      expect(result, isA<Ok<List<Task>>>());
      final tasks = (result as Ok<List<Task>>).value;
      expect(tasks, hasLength(1));
      expect(tasks.single.titel, equals('Wäsche waschen'));
    });

    test('liefert ServerFailure bei einer Fehlerantwort', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Authentifizierung erforderlich'}),
          HttpStatus.unauthorized,
        );
      });

      final result = await repository.list();

      expect(result, isA<Err<List<Task>>>());
      expect((result as Err<List<Task>>).failure, isA<ServerFailure>());
    });

    test('liefert NetworkFailure, wenn das Backend nicht erreichbar ist', () async {
      final repository = repositoryFor((request) async {
        throw const SocketException('keine Verbindung');
      });

      final result = await repository.list();

      expect((result as Err<List<Task>>).failure, isA<NetworkFailure>());
    });
  });

  group('find', () {
    test('liefert die Aufgabe als Task', () async {
      late Uri requestedUri;
      final repository = repositoryFor((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode(taskJson), HttpStatus.ok);
      });

      final result = await repository.find('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

      expect(requestedUri.path, equals('/tasks/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'));
      expect((result as Ok<Task>).value.id, equals(taskJson['id']));
    });

    test('liefert ServerFailure, wenn die Aufgabe nicht existiert', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Task nicht gefunden'}),
          HttpStatus.notFound,
        );
      });

      final result = await repository.find('unbekannt');

      expect((result as Err<Task>).failure, isA<ServerFailure>());
    });
  });

  group('create', () {
    test('sendet nur gesetzte Felder im Request-Body', () async {
      late http.Request captured;
      final repository = repositoryFor((request) async {
        captured = request;
        return http.Response(jsonEncode(taskJson), HttpStatus.created);
      });

      final result = await repository.create(
        titel: 'Wäsche waschen',
        kontext: 'privat',
        tags: const ['haushalt'],
      );

      expect(captured.method, equals('POST'));
      expect(
        jsonDecode(captured.body),
        equals({'titel': 'Wäsche waschen', 'kontext': 'privat', 'tags': ['haushalt']}),
      );
      expect((result as Ok<Task>).value.titel, equals('Wäsche waschen'));
    });

    test('serialisiert das Deadline-Feld als ISO-8601', () async {
      late http.Request captured;
      final repository = repositoryFor((request) async {
        captured = request;
        return http.Response(jsonEncode(taskJson), HttpStatus.created);
      });

      await repository.create(
        titel: 'Steuererklärung',
        deadline: DateTime.utc(2026, 7, 31, 22),
      );

      expect(
        jsonDecode(captured.body),
        equals({
          'titel': 'Steuererklärung',
          'deadline': '2026-07-31T22:00:00.000Z',
        }),
      );
    });

    test('liefert ServerFailure bei abgelehntem Request', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'titel ist erforderlich'}),
          HttpStatus.badRequest,
        );
      });

      final result = await repository.create(titel: '');

      expect((result as Err<Task>).failure.message, equals('titel ist erforderlich'));
    });
  });

  group('update', () {
    test('sendet die Änderungen unverändert als PUT-Body', () async {
      late http.Request captured;
      final repository = repositoryFor((request) async {
        captured = request;
        return http.Response(jsonEncode(taskJson), HttpStatus.ok);
      });

      final result = await repository.update('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', {
        'status': 'aktiv',
        'wiederholung': null,
      });

      expect(captured.method, equals('PUT'));
      expect(
        jsonDecode(captured.body),
        equals({'status': 'aktiv', 'wiederholung': null}),
      );
      expect(result, isA<Ok<Task>>());
    });

    test('liefert ServerFailure, wenn die Aufgabe nicht existiert', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Task nicht gefunden'}),
          HttpStatus.notFound,
        );
      });

      final result = await repository.update('unbekannt', {'status': 'aktiv'});

      expect((result as Err<Task>).failure, isA<ServerFailure>());
    });
  });

  group('delete', () {
    test('liefert Ok bei erfolgreichem Löschen', () async {
      late http.Request captured;
      final repository = repositoryFor((request) async {
        captured = request;
        return http.Response('', HttpStatus.noContent);
      });

      final result = await repository.delete('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

      expect(captured.method, equals('DELETE'));
      expect(result, isA<Ok<void>>());
    });

    test('liefert ServerFailure, wenn die Aufgabe nicht existiert', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Task nicht gefunden'}),
          HttpStatus.notFound,
        );
      });

      final result = await repository.delete('unbekannt');

      expect(result, isA<Err<void>>());
    });
  });
}
