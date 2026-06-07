import 'dart:convert';
import 'dart:io';

import 'package:backend/src/tasks/task.dart';
import 'package:backend/src/tasks/task_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/tasks/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late _MockRequestContext context;
  late _MockRequest request;
  late _MockTaskRepository repository;

  final task = Task(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
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
    when(
      () => repository.list(
        kontext: any(named: 'kontext'),
        status: any(named: 'status'),
        projektId: any(named: 'projektId'),
      ),
    ).thenAnswer((_) async => [task]);
  });

  Request requestWithBody(Object? body) => Request.post(
    Uri.parse('http://localhost/tasks'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode(body),
  );

  group('GET /tasks', () {
    test('liefert die Liste als JSON', () async {
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.uri).thenReturn(Uri.parse('http://localhost/tasks'));

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as List<dynamic>;
      expect(body, hasLength(1));
      expect(
        (body.first as Map<String, dynamic>)['titel'],
        equals('Wäsche waschen'),
      );
    });

    test(
      'reicht Filter-Parameter aus der Query an das Repository weiter',
      () async {
        when(() => request.method).thenReturn(HttpMethod.get);
        when(() => request.uri).thenReturn(
          Uri.parse(
            'http://localhost/tasks?kontext=privat&status=aktiv&projekt_id=42',
          ),
        );

        await route.onRequest(context);

        verify(
          () => repository.list(
            kontext: 'privat',
            status: 'aktiv',
            projektId: '42',
          ),
        ).called(1);
      },
    );
  });

  group('POST /tasks', () {
    test('lehnt fehlenden Titel mit 400 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(
        requestWithBody({'beschreibung': 'x'}),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('lehnt eine ungültige Wiederholungsregel mit 400 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(
        requestWithBody({
          'titel': 'Neue Aufgabe',
          'wiederholung': {'typ': 'stuendlich', 'intervall': 1},
        }),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('legt eine Aufgabe an und liefert 201', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(
        () => context.request,
      ).thenReturn(requestWithBody({'titel': 'Neue Aufgabe'}));
      when(
        () => repository.create(
          titel: any(named: 'titel'),
          beschreibung: any(named: 'beschreibung'),
          deadline: any(named: 'deadline'),
          prioritaet: any(named: 'prioritaet'),
          status: any(named: 'status'),
          projektId: any(named: 'projektId'),
          kontext: any(named: 'kontext'),
          wiederholung: any(named: 'wiederholung'),
          energieLevel: any(named: 'energieLevel'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer((_) async => task);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.created));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['id'], equals(task.id));
    });

    test('normalisiert eine gültige Wiederholungsregel', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(
        requestWithBody({
          'titel': 'Müll rausbringen',
          'wiederholung': {
            'typ': 'woechentlich',
            'intervall': 2,
            'bis': '2026-12-31T00:00:00.000Z',
          },
        }),
      );
      when(
        () => repository.create(
          titel: any(named: 'titel'),
          beschreibung: any(named: 'beschreibung'),
          deadline: any(named: 'deadline'),
          prioritaet: any(named: 'prioritaet'),
          status: any(named: 'status'),
          projektId: any(named: 'projektId'),
          kontext: any(named: 'kontext'),
          wiederholung: any(named: 'wiederholung'),
          energieLevel: any(named: 'energieLevel'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer((_) async => task);

      await route.onRequest(context);

      verify(
        () => repository.create(
          titel: 'Müll rausbringen',
          wiederholung: {
            'typ': 'woechentlich',
            'intervall': 2,
            'bis': '2026-12-31T00:00:00.000Z',
          },
        ),
      ).called(1);
    });
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => request.method).thenReturn(HttpMethod.delete);

    final response = await route.onRequest(context);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
