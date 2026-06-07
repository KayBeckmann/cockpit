import 'dart:convert';
import 'dart:io';

import 'package:cockpit/core/constants/app_constants.dart';
import 'package:cockpit/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('GET liefert dekodiertes JSON von Basis-URL + Pfad', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode([
              {'id': '1'},
            ]),
            HttpStatus.ok,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await client.get('/tasks');

      expect(captured.method, equals('GET'));
      expect(captured.url.toString(), equals('${AppConstants.apiBaseUrl}/tasks'));
      expect(result, equals([{'id': '1'}]));
    });

    test('GET hängt Query-Parameter an die URL an', () async {
      late Uri requestedUri;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response('[]', HttpStatus.ok);
        }),
      );

      await client.get('/tasks', queryParameters: {'status': 'inbox'});

      expect(requestedUri.queryParameters, equals({'status': 'inbox'}));
    });

    test('POST kodiert den Body als JSON mit Content-Type-Header', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'id': '1'}),
            HttpStatus.created,
          );
        }),
      );

      final result = await client.post('/tasks', body: {'titel': 'Test'});

      expect(captured.method, equals('POST'));
      expect(captured.headers['content-type'], equals('application/json'));
      expect(jsonDecode(captured.body), equals({'titel': 'Test'}));
      expect(result, equals({'id': '1'}));
    });

    test('PUT und DELETE senden die jeweils passende HTTP-Methode', () async {
      final methods = <String>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          methods.add(request.method);
          return http.Response('', HttpStatus.noContent);
        }),
      );

      await client.put('/tasks/1', body: {'status': 'aktiv'});
      await client.delete('/tasks/1');

      expect(methods, equals(['PUT', 'DELETE']));
    });

    test('hängt Authorization-Header an, wenn ein Token vorhanden ist', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('[]', HttpStatus.ok);
        }),
        tokenProvider: () async => 'mein-jwt',
      );

      await client.get('/tasks');

      expect(captured.headers['authorization'], equals('Bearer mein-jwt'));
    });

    test('lässt den Authorization-Header weg, wenn kein Token vorliegt', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('[]', HttpStatus.ok);
        }),
        tokenProvider: () async => null,
      );

      await client.get('/tasks');

      expect(captured.headers.containsKey('authorization'), isFalse);
    });

    test('wirft ApiException mit Backend-Fehlermeldung bei 4xx/5xx', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'error': 'Ungültiges oder abgelaufenes Token'}),
            HttpStatus.unauthorized,
          );
        }),
      );

      await expectLater(
        client.get('/tasks'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', HttpStatus.unauthorized)
              .having((e) => e.message, 'message', 'Ungültiges oder abgelaufenes Token'),
        ),
      );
    });

    test('wirft ApiException mit generischer Meldung ohne error-Feld', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          return http.Response('Internal Server Error', HttpStatus.internalServerError);
        }),
      );

      await expectLater(
        client.get('/tasks'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

    test('wirft ApiNetworkException bei Transportfehlern', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          throw const SocketException('Verbindung fehlgeschlagen');
        }),
      );

      await expectLater(client.get('/tasks'), throwsA(isA<ApiNetworkException>()));
    });
  });
}
