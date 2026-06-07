import 'dart:convert';
import 'dart:io';

import 'package:backend/src/auth/jwt_service.dart';
import 'package:backend/src/auth/password_hasher.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../../../routes/auth/login.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockConnection extends Mock implements Connection {}

class _FakeSql extends Fake implements Sql {}

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';
  const email = 'kay@example.com';
  const password = 'sicheres-passwort';
  final passwordHash = PasswordHasher.hash(password);

  late _MockRequestContext context;
  late _MockConnection connection;
  late JwtService jwtService;

  setUpAll(() {
    registerFallbackValue(_FakeSql());
  });

  setUp(() {
    context = _MockRequestContext();
    connection = _MockConnection();
    jwtService = const JwtService('test-secret');

    when(
      () => context.read<Future<Connection>>(),
    ).thenAnswer((_) => Future.value(connection));
    when(() => context.read<JwtService>()).thenReturn(jwtService);
  });

  Result userQueryResult(List<List<Object?>> rows) => Result(
    rows: rows
        .map((values) => ResultRow(values: values, schema: ResultSchema([])))
        .toList(),
    affectedRows: rows.length,
    schema: ResultSchema([]),
  );

  void stubUserQuery(Result result) {
    when(
      () => connection.execute(any(), parameters: any(named: 'parameters')),
    ).thenAnswer((_) async => result);
  }

  Request requestWithBody(Object? body) => Request.post(
    Uri.parse('http://localhost/auth/login'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode(body),
  );

  group('POST /auth/login', () {
    test('lehnt andere HTTP-Methoden mit 405 ab', () async {
      when(
        () => context.request,
      ).thenReturn(Request.get(Uri.parse('http://localhost/auth/login')));

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('antwortet mit 400, wenn Felder fehlen', () async {
      when(() => context.request).thenReturn(requestWithBody({'email': email}));

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('antwortet mit 401, wenn keine E-Mail bekannt ist', () async {
      when(
        () => context.request,
      ).thenReturn(requestWithBody({'email': email, 'password': password}));
      stubUserQuery(userQueryResult([]));

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('antwortet mit 401 bei falschem Passwort', () async {
      when(
        () => context.request,
      ).thenReturn(requestWithBody({'email': email, 'password': 'falsch'}));
      stubUserQuery(
        userQueryResult([
          [userId, passwordHash],
        ]),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('liefert ein gültiges Token bei korrekten Zugangsdaten', () async {
      when(
        () => context.request,
      ).thenReturn(requestWithBody({'email': email, 'password': password}));
      stubUserQuery(
        userQueryResult([
          [userId, passwordHash],
        ]),
      );

      final response = await route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));

      final body = await response.json() as Map<String, dynamic>;
      expect(jwtService.verifyToken(body['token'] as String), equals(userId));
    });
  });
}
