import 'dart:io';

import 'package:backend/src/links/link_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/links/[id].dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockLinkRepository extends Mock implements LinkRepository {}

void main() {
  const linkId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  late _MockRequestContext context;
  late _MockRequest request;
  late _MockLinkRepository repository;

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    repository = _MockLinkRepository();

    when(() => context.request).thenReturn(request);
    when(
      () => context.read<Future<LinkRepository>>(),
    ).thenAnswer((_) => Future.value(repository));
  });

  group('DELETE /links/:id', () {
    test('liefert 204, wenn die Verknüpfung gelöscht wurde', () async {
      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => repository.delete(linkId)).thenAnswer((_) async => true);

      final response = await route.onRequest(context, linkId);

      expect(response.statusCode, equals(HttpStatus.noContent));
    });

    test('liefert 404, wenn keine Verknüpfung existiert', () async {
      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => repository.delete(linkId)).thenAnswer((_) async => false);

      final response = await route.onRequest(context, linkId);

      expect(response.statusCode, equals(HttpStatus.notFound));
    });
  });

  test('lehnt andere HTTP-Methoden mit 405 ab', () async {
    when(() => request.method).thenReturn(HttpMethod.get);

    final response = await route.onRequest(context, linkId);

    expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
  });
}
