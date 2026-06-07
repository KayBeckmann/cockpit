import 'dart:convert';
import 'dart:io';

import 'package:backend/src/tasks/task.dart';
import 'package:backend/src/tasks/task_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/tasks/[id].dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  const taskId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  final uri = Uri.parse('http://localhost/tasks/$taskId');

  late _MockRequestContext context;
  late _MockRequest request;
  late _MockTaskRepository repository;

  final task = Task(
    id: taskId,
    titel: 'Wäsche waschen',
    status: 'inbox',
    createdAt: DateTime.utc(2026, 6, 7),
    updatedAt: DateTime.utc(2026, 6, 7),
  );

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    repository = _MockTaskRepository();

    when(() => context.request).thenReturn(request);
    when(
      () => context.read<Future<TaskRepository>>(),
    ).thenAnswer((_) => Future.value(repository));
  });

  group('GET /tasks/:id', () {
    test('liefert die Aufgabe als JSON', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => repository.find(taskId)).thenAnswer((_) async => task);

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['id'], equals(taskId));
    });

    test('liefert 404, wenn keine Aufgabe existiert', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => repository.find(taskId)).thenAnswer((_) async => null);

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });
  });

  group('PUT /tasks/:id', () {
    test('aktualisiert nur die übergebenen Felder', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'status': 'aktiv'}),
        ),
      );
      when(
        () => repository.update(
          taskId,
          any(that: containsPair('status', 'aktiv')),
        ),
      ).thenAnswer((_) async => task);

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.ok));
      final captured = verify(
        () => repository.update(taskId, captureAny()),
      ).captured;
      expect(captured.single, equals({'status': 'aktiv'}));
    });

    test('normalisiert eine gültige Wiederholungsregel', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'wiederholung': {'typ': 'taeglich', 'intervall': 1},
          }),
        ),
      );
      when(
        () => repository.update(taskId, any()),
      ).thenAnswer((_) async => task);

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.ok));
      final captured = verify(
        () => repository.update(taskId, captureAny()),
      ).captured;
      expect(
        captured.single,
        equals({
          'wiederholung': {'typ': 'taeglich', 'intervall': 1},
        }),
      );
    });

    test('lehnt eine ungültige Wiederholungsregel mit 400 ab', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'wiederholung': {'typ': 'taeglich', 'intervall': 0},
          }),
        ),
      );

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('entfernt die Wiederholung bei explizitem null', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'wiederholung': null}),
        ),
      );
      when(
        () => repository.update(taskId, any()),
      ).thenAnswer((_) async => task);

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.ok));
      final captured = verify(
        () => repository.update(taskId, captureAny()),
      ).captured;
      expect(captured.single, equals({'wiederholung': null}));
    });

    test('liefert 404, wenn keine Aufgabe existiert', () async {
      when(() => context.request).thenReturn(
        Request.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'status': 'aktiv'}),
        ),
      );
      when(
        () => repository.update(taskId, any()),
      ).thenAnswer((_) async => null);

      final response = await route.onRequest(context, taskId);

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

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
  });

  group('DELETE /tasks/:id', () {
    test('liefert 204, wenn die Aufgabe gelöscht wurde', () async {
      when(() => context.request).thenReturn(Request.delete(uri));
      when(() => repository.delete(taskId)).thenAnswer((_) async => true);

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.noContent));
    });

    test('liefert 404, wenn keine Aufgabe existiert', () async {
      when(() => context.request).thenReturn(Request.delete(uri));
      when(() => repository.delete(taskId)).thenAnswer((_) async => false);

      final response = await route.onRequest(context, taskId);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => context.request).thenReturn(Request.post(uri));

    final response = await route.onRequest(context, taskId);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
