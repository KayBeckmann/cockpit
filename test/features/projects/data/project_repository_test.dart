import 'dart:convert';
import 'dart:io';

import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/core/network/api_client.dart';
import 'package:cockpit/features/projects/data/project_model.dart';
import 'package:cockpit/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final projectJson = {
    'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'titel': 'Gartenhaus bauen',
    'status': 'aktiv',
    'fortschritt': 0,
    'kontext': 'privat',
    'createdAt': '2026-06-07T08:00:00.000Z',
    'updatedAt': '2026-06-07T08:00:00.000Z',
  };

  ProjectRepository repositoryFor(MockClientHandler handler) {
    return ProjectRepository(ApiClient(httpClient: MockClient(handler)));
  }

  group('list', () {
    test('liefert die geparste Liste und reicht Filter als Query weiter', () async {
      late Uri requestedUri;
      final repository = repositoryFor((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode([projectJson]), HttpStatus.ok);
      });

      final result = await repository.list(kontext: 'privat', status: 'aktiv');

      expect(requestedUri.path, equals('/projects'));
      expect(
        requestedUri.queryParameters,
        equals({'kontext': 'privat', 'status': 'aktiv'}),
      );
      expect(result, isA<Ok<List<Project>>>());
      final projects = (result as Ok<List<Project>>).value;
      expect(projects, hasLength(1));
      expect(projects.single.titel, equals('Gartenhaus bauen'));
    });

    test('liefert ServerFailure bei einer Fehlerantwort', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Authentifizierung erforderlich'}),
          HttpStatus.unauthorized,
        );
      });

      final result = await repository.list();

      expect(result, isA<Err<List<Project>>>());
      expect((result as Err<List<Project>>).failure, isA<ServerFailure>());
    });

    test('liefert NetworkFailure, wenn das Backend nicht erreichbar ist', () async {
      final repository = repositoryFor((request) async {
        throw const SocketException('keine Verbindung');
      });

      final result = await repository.list();

      expect((result as Err<List<Project>>).failure, isA<NetworkFailure>());
    });
  });

  group('find', () {
    test('liefert das Projekt als Project', () async {
      late Uri requestedUri;
      final repository = repositoryFor((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode(projectJson), HttpStatus.ok);
      });

      final result = await repository.find('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

      expect(requestedUri.path, equals('/projects/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'));
      expect((result as Ok<Project>).value.id, equals(projectJson['id']));
    });

    test('liefert ServerFailure, wenn das Projekt nicht existiert', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Projekt nicht gefunden'}),
          HttpStatus.notFound,
        );
      });

      final result = await repository.find('unbekannt');

      expect((result as Err<Project>).failure, isA<ServerFailure>());
    });
  });

  group('create', () {
    test('sendet nur gesetzte Felder im Request-Body', () async {
      late http.Request captured;
      final repository = repositoryFor((request) async {
        captured = request;
        return http.Response(jsonEncode(projectJson), HttpStatus.created);
      });

      final result = await repository.create(titel: 'Gartenhaus bauen', kontext: 'privat');

      expect(captured.method, equals('POST'));
      expect(
        jsonDecode(captured.body),
        equals({'titel': 'Gartenhaus bauen', 'kontext': 'privat'}),
      );
      expect((result as Ok<Project>).value.titel, equals('Gartenhaus bauen'));
    });

    test('liefert ServerFailure bei abgelehntem Request', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'titel ist erforderlich'}),
          HttpStatus.badRequest,
        );
      });

      final result = await repository.create(titel: '', kontext: 'privat');

      expect((result as Err<Project>).failure.message, equals('titel ist erforderlich'));
    });
  });

  group('update', () {
    test('sendet die Änderungen unverändert als PUT-Body', () async {
      late http.Request captured;
      final repository = repositoryFor((request) async {
        captured = request;
        return http.Response(jsonEncode(projectJson), HttpStatus.ok);
      });

      final result = await repository.update('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', {
        'status': 'pausiert',
        'obsidianUri': null,
      });

      expect(captured.method, equals('PUT'));
      expect(
        jsonDecode(captured.body),
        equals({'status': 'pausiert', 'obsidianUri': null}),
      );
      expect(result, isA<Ok<Project>>());
    });

    test('liefert ServerFailure, wenn das Projekt nicht existiert', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Projekt nicht gefunden'}),
          HttpStatus.notFound,
        );
      });

      final result = await repository.update('unbekannt', {'status': 'aktiv'});

      expect((result as Err<Project>).failure, isA<ServerFailure>());
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

    test('liefert ServerFailure, wenn das Projekt nicht existiert', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Projekt nicht gefunden'}),
          HttpStatus.notFound,
        );
      });

      final result = await repository.delete('unbekannt');

      expect(result, isA<Err<void>>());
    });
  });
}
