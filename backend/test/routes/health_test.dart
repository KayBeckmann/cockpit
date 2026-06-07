import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../../routes/health.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockConnection extends Mock implements Connection {}

class _MockResult extends Mock implements Result {}

class _FakeSql extends Fake implements Sql {}

void main() {
  late _MockRequestContext context;
  late _MockRequest request;
  late _MockConnection connection;

  setUpAll(() {
    registerFallbackValue(_FakeSql());
  });

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    connection = _MockConnection();

    when(() => context.request).thenReturn(request);
    when(() => request.method).thenReturn(HttpMethod.get);
    when(
      () => context.read<Future<Connection>>(),
    ).thenAnswer((_) => Future.value(connection));
  });

  group('GET /health', () {
    test('antwortet mit 200, wenn die Datenbank erreichbar ist', () async {
      when(
        () => connection.execute(any()),
      ).thenAnswer((_) async => _MockResult());

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.body(),
        completion(equals('{"status":"ok","database":"connected"}')),
      );
    });

    test(
      'antwortet mit 503, wenn die Datenbank nicht erreichbar ist',
      () async {
        when(() => connection.execute(any())).thenThrow(Exception('refused'));

        final response = await route.onRequest(context);

        expect(response.statusCode, equals(HttpStatus.serviceUnavailable));
      },
    );

    test('lehnt andere HTTP-Methoden mit 405 ab', () async {
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });
}
