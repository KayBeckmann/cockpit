import 'dart:convert';
import 'dart:io';

import 'package:backend/src/tasks/task.dart';
import 'package:backend/src/tasks/task_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/quick-capture/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late _MockRequestContext context;
  late _MockRequest request;
  late _MockTaskRepository repository;

  final task = Task(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    titel: 'Spontane Idee',
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

  Request requestWithBody(Object? body) => Request.post(
    Uri.parse('http://localhost/quick-capture'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode(body),
  );

  group('POST /quick-capture', () {
    test('lehnt fehlenden Titel mit 400 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(
        () => context.request,
      ).thenReturn(requestWithBody({'beschreibung': 'x'}));

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('legt eine kontextlose Inbox-Aufgabe an und liefert 201', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(
        () => context.request,
      ).thenReturn(requestWithBody({'titel': 'Spontane Idee'}));
      when(
        () => repository.create(
          titel: any(named: 'titel'),
          beschreibung: any(named: 'beschreibung'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => task);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.created));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['id'], equals(task.id));
      verify(
        () => repository.create(titel: 'Spontane Idee', status: 'inbox'),
      ).called(1);
    });
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => request.method).thenReturn(HttpMethod.get);

    final response = await route.onRequest(context);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
