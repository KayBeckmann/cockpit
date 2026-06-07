import 'dart:io';

import 'package:backend/src/auth/auth_middleware.dart';
import 'package:backend/src/auth/jwt_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  late _MockRequestContext context;
  late _MockRequest request;
  late JwtService jwtService;

  setUpAll(() {
    registerFallbackValue(() => const AuthenticatedUser(id: 'fallback'));
  });

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    jwtService = const JwtService('test-secret');

    when(() => context.request).thenReturn(request);
    when(() => context.read<JwtService>()).thenReturn(jwtService);
    when(() => context.provide<AuthenticatedUser>(any())).thenReturn(context);
  });

  group('requireAuth', () {
    test('antwortet mit 401, wenn der Authorization-Header fehlt', () async {
      when(() => request.headers).thenReturn({});

      final handler = requireAuth()((_) async => Response());
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('antwortet mit 401 bei einem fehlerhaften Header-Format', () async {
      when(() => request.headers).thenReturn({'authorization': 'Token abc'});

      final handler = requireAuth()((_) async => Response());
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('antwortet mit 401 bei ungültigem Token', () async {
      when(
        () => request.headers,
      ).thenReturn({'authorization': 'Bearer ungueltiges-token'});

      final handler = requireAuth()((_) async => Response());
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'ruft den Handler auf und stellt den Benutzer bereit, '
      'wenn das Token gültig ist',
      () async {
        final token = jwtService.issueToken(userId);
        when(
          () => request.headers,
        ).thenReturn({'authorization': 'Bearer $token'});

        final handler = requireAuth()(
          (_) async => Response.json(body: {'ok': true}),
        );
        final response = await handler(context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final captured = verify(
          () => context.provide<AuthenticatedUser>(captureAny()),
        ).captured;
        final factory = captured.single as AuthenticatedUser Function();
        expect(factory().id, equals(userId));
      },
    );
  });
}
