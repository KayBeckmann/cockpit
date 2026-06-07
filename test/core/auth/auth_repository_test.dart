import 'dart:convert';
import 'dart:io';

import 'package:cockpit/core/auth/auth_repository.dart';
import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late FlutterSecureStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
  });

  AuthRepository repositoryFor(MockClientHandler handler) {
    return AuthRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
      storage: storage,
    );
  }

  group('login', () {
    test('sendet E-Mail und Passwort und speichert das Token bei Erfolg', () async {
      late http.Request captured;
      final repository = repositoryFor((request) async {
        captured = request;
        return http.Response(jsonEncode({'token': 'mein-jwt'}), HttpStatus.ok);
      });

      final result = await repository.login('kay@example.com', 'geheim');

      expect(captured.url.path, equals('/auth/login'));
      expect(
        jsonDecode(captured.body),
        equals({'email': 'kay@example.com', 'password': 'geheim'}),
      );
      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, equals('mein-jwt'));
      expect(await storage.read(key: 'cockpit_auth_token'), equals('mein-jwt'));
    });

    test('liefert ServerFailure bei abgelehntem Login', () async {
      final repository = repositoryFor((request) async {
        return http.Response(
          jsonEncode({'error': 'Ungültige Zugangsdaten'}),
          HttpStatus.unauthorized,
        );
      });

      final result = await repository.login('kay@example.com', 'falsch');

      expect(result, isA<Err<String>>());
      final failure = (result as Err<String>).failure;
      expect(failure, isA<ServerFailure>());
      expect(failure.message, equals('Ungültige Zugangsdaten'));
      expect(await storage.read(key: 'cockpit_auth_token'), isNull);
    });

    test('liefert NetworkFailure, wenn das Backend nicht erreichbar ist', () async {
      final repository = repositoryFor((request) async {
        throw const SocketException('Keine Verbindung');
      });

      final result = await repository.login('kay@example.com', 'geheim');

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).failure, isA<NetworkFailure>());
    });

    test('liefert ServerFailure, wenn die Antwort kein Token enthält', () async {
      final repository = repositoryFor((request) async {
        return http.Response(jsonEncode({'foo': 'bar'}), HttpStatus.ok);
      });

      final result = await repository.login('kay@example.com', 'geheim');

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).failure, isA<ServerFailure>());
    });
  });

  group('loadToken / logout', () {
    test('liefert null, solange niemand eingeloggt ist', () async {
      final repository = repositoryFor((request) async {
        throw UnimplementedError('sollte hier nicht aufgerufen werden');
      });

      expect(await repository.loadToken(), isNull);
    });

    test('logout entfernt ein gespeichertes Token', () async {
      await storage.write(key: 'cockpit_auth_token', value: 'altes-jwt');
      final repository = repositoryFor((request) async {
        throw UnimplementedError('sollte hier nicht aufgerufen werden');
      });

      await repository.logout();

      expect(await storage.read(key: 'cockpit_auth_token'), isNull);
    });
  });
}
