import 'dart:convert';
import 'dart:io';

import 'package:backend/src/links/link.dart';
import 'package:backend/src/links/link_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/links/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockLinkRepository extends Mock implements LinkRepository {}

void main() {
  late _MockRequestContext context;
  late _MockRequest request;
  late _MockLinkRepository repository;

  final link = Link(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    vonTyp: 'task',
    vonId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    zuTyp: 'project',
    zuId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
    createdAt: DateTime.utc(2026, 6, 7),
  );

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    repository = _MockLinkRepository();

    when(() => context.request).thenReturn(request);
    when(
      () => context.read<Future<LinkRepository>>(),
    ).thenAnswer((_) => Future.value(repository));
  });

  Request requestWithBody(Object? body) => Request.post(
    Uri.parse('http://localhost/links'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode(body),
  );

  group('POST /links', () {
    test('lehnt unvollständige Angaben mit 400 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(
        () => context.request,
      ).thenReturn(requestWithBody({'vonTyp': 'task', 'vonId': link.vonId}));

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('erstellt eine Verknüpfung und liefert 201', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.request).thenReturn(
        requestWithBody({
          'vonTyp': link.vonTyp,
          'vonId': link.vonId,
          'zuTyp': link.zuTyp,
          'zuId': link.zuId,
          'beziehung': 'gehört zu',
        }),
      );
      when(
        () => repository.create(
          vonTyp: any(named: 'vonTyp'),
          vonId: any(named: 'vonId'),
          zuTyp: any(named: 'zuTyp'),
          zuId: any(named: 'zuId'),
          beziehung: any(named: 'beziehung'),
        ),
      ).thenAnswer((_) async => link);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.created));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['id'], equals(link.id));
      verify(
        () => repository.create(
          vonTyp: link.vonTyp,
          vonId: link.vonId,
          zuTyp: link.zuTyp,
          zuId: link.zuId,
          beziehung: 'gehört zu',
        ),
      ).called(1);
    });
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => request.method).thenReturn(HttpMethod.get);

    final response = await route.onRequest(context);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
