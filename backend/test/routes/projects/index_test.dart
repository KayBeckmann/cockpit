import 'dart:convert';
import 'dart:io';

import 'package:backend/src/projects/project.dart';
import 'package:backend/src/projects/project_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/projects/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  late _MockRequestContext context;
  late _MockRequest request;
  late _MockProjectRepository repository;

  final project = Project(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    titel: 'Solaranlage planen',
    status: 'aktiv',
    fortschritt: 0,
    kontext: 'privat',
    createdAt: DateTime.utc(2026, 6, 7),
    updatedAt: DateTime.utc(2026, 6, 7),
  );

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    repository = _MockProjectRepository();

    when(() => context.request).thenReturn(request);
    when(
      () => context.read<Future<ProjectRepository>>(),
    ).thenAnswer((_) => Future.value(repository));
    when(
      () => repository.list(
        kontext: any(named: 'kontext'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => [project]);
  });

  Request requestWithBody(Object? body) => Request.post(
    Uri.parse('http://localhost/projects'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode(body),
  );

  group('GET /projects', () {
    test('liefert die Liste als JSON', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(
        () => request.uri,
      ).thenReturn(Uri.parse('http://localhost/projects'));

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as List<dynamic>;
      expect(body, hasLength(1));
      expect(
        (body.first as Map<String, dynamic>)['titel'],
        equals('Solaranlage planen'),
      );
    });

    test(
      'reicht Filter-Parameter aus der Query an das Repository weiter',
      () async {
        when(() => request.method).thenReturn(HttpMethod.get);
        when(() => request.uri).thenReturn(
          Uri.parse('http://localhost/projects?kontext=privat&status=aktiv'),
        );

        await route.onRequest(context);

        verify(
          () => repository.list(kontext: 'privat', status: 'aktiv'),
        ).called(1);
      },
    );
  });

  group('POST /projects', () {
    test('lehnt fehlenden Titel mit 400 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(
        requestWithBody({'kontext': 'privat'}),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('lehnt fehlenden Kontext mit 400 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(
        requestWithBody({'titel': 'Neues Projekt'}),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('legt ein Projekt an und liefert 201', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(
        requestWithBody({'titel': 'Neues Projekt', 'kontext': 'privat'}),
      );
      when(
        () => repository.create(
          titel: any(named: 'titel'),
          kontext: any(named: 'kontext'),
          typ: any(named: 'typ'),
          status: any(named: 'status'),
          fortschritt: any(named: 'fortschritt'),
          meilensteine: any(named: 'meilensteine'),
          ressourcen: any(named: 'ressourcen'),
          obsidianUri: any(named: 'obsidianUri'),
        ),
      ).thenAnswer((_) async => project);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.created));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['id'], equals(project.id));
    });
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => request.method).thenReturn(HttpMethod.delete);

    final response = await route.onRequest(context);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
