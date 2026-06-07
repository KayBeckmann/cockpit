import 'dart:io';

import 'package:backend/src/auth/auth_middleware.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/auth/me/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  late _MockRequestContext context;
  late _MockRequest request;

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();

    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUser>(),
    ).thenReturn(const AuthenticatedUser(id: userId));
  });

  group('GET /auth/me', () {
    test('liefert die ID des authentifizierten Benutzers', () async {
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.body(),
        completion(equals('{"id":"$userId"}')),
      );
    });

    test('lehnt andere HTTP-Methoden mit 405 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });
}
