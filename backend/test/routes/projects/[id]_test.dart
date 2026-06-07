import 'dart:convert';
import 'dart:io';

import 'package:backend/src/projects/project.dart';
import 'package:backend/src/projects/project_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/projects/[id].dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  const projectId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  final uri = Uri.parse('http://localhost/projects/$projectId');

  late _MockRequestContext context;
  late _MockRequest request;
  late _MockProjectRepository repository;

  final project = Project(
    id: projectId,
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
  });

  group('GET /projects/:id', () {
    test('liefert das Projekt als JSON', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => repository.find(projectId)).thenAnswer((_) async => project);

      final response = await route.onRequest(context, projectId);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['id'], equals(projectId));
    });

    test('liefert 404, wenn kein Projekt existiert', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => repository.find(projectId)).thenAnswer((_) async => null);

      final response = await route.onRequest(context, projectId);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });
  });

  group('PUT /projects/:id', () {
    test('aktualisiert nur die übergebenen Felder', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'status': 'pausiert'}),
        ),
      );
      when(
        () => repository.update(
          projectId,
          any(that: containsPair('status', 'pausiert')),
        ),
      ).thenAnswer((_) async => project);

      final response = await route.onRequest(context, projectId);

      expect(response.statusCode, equals(HttpStatus.ok));
      final captured = verify(
        () => repository.update(projectId, captureAny()),
      ).captured;
      expect(captured.single, equals({'status': 'pausiert'}));
    });

    test('liefert 404, wenn kein Projekt existiert', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'status': 'pausiert'}),
        ),
      );
      when(
        () => repository.update(projectId, any()),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context, projectId);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('liefert 400 bei ungültigem JSON-Body', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: 'kein-json',
        ),
      );

      final response = await route.onRequest(context, projectId);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
  });

  group('DELETE /projects/:id', () {
    test('liefert 204, wenn das Projekt gelöscht wurde', () async {
      when(() => context.request).thenReturn(Request.delete(uri));
      when(() => repository.delete(projectId)).thenAnswer((_) async => true);

      final response = await route.onRequest(context, projectId);

      expect(response.statusCode, equals(HttpStatus.noContent));
    });

    test('liefert 404, wenn kein Projekt existiert', () async {
      when(() => context.request).thenReturn(Request.delete(uri));
      when(() => repository.delete(projectId)).thenAnswer((_) async => false);

      final response = await route.onRequest(context, projectId);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => context.request).thenReturn(Request.post(uri));

    final response = await route.onRequest(context, projectId);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
