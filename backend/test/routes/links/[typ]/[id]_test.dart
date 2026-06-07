import 'dart:io';

import 'package:backend/src/links/link.dart';
import 'package:backend/src/links/link_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/links/[typ]/[id].dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockLinkRepository extends Mock implements LinkRepository {}

void main() {
  const objectId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  late _MockRequestContext context;
  late _MockRequest request;
  late _MockLinkRepository repository;

  final link = Link(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    vonTyp: 'task',
    vonId: objectId,
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

  test('liefert alle Verknüpfungen einer Entität als JSON', () async {
    when(() => request.method).thenReturn(HttpMethod.get);
    when(
      () => repository.listForObject('task', objectId),
    ).thenAnswer((_) async => [link]);

    final response = await route.onRequest(context, 'task', objectId);

    expect(response.statusCode, equals(HttpStatus.ok));
    final body = await response.json() as List<dynamic>;
    expect(body, hasLength(1));
    expect((body.first as Map<String, dynamic>)['id'], equals(link.id));
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => request.method).thenReturn(HttpMethod.post);

    final response = await route.onRequest(context, 'task', objectId);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
