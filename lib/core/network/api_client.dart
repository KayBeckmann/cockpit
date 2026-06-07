import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

/// Liefert das aktuell gültige JWT oder `null`, wenn niemand eingeloggt ist.
/// Wird von [AuthRepository] bereitgestellt — der Client kennt dessen
/// Storage-Details bewusst nicht, um eine zirkuläre Abhängigkeit zu
/// vermeiden (Login läuft selbst über diesen Client).
typedef TokenProvider = Future<String?> Function();

/// Wird geworfen, wenn das Backend mit einem Fehlerstatus (4xx/5xx)
/// antwortet. Repositories fangen sie und bilden sie auf die passende
/// [Failure] der jeweiligen Schicht ab.
class ApiException implements Exception {
  /// Erstellt die Exception mit HTTP-[statusCode] und einer für Menschen
  /// lesbaren [message] (vom Backend oder generisch generiert).
  const ApiException(this.statusCode, this.message);

  /// HTTP-Statuscode der Antwort.
  final int statusCode;

  /// Fehlermeldung — bevorzugt aus dem `error`-Feld der JSON-Antwort.
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Wird geworfen, wenn der Request das Backend gar nicht erst erreicht
/// (kein Netz, DNS-Fehler, Timeout o.ä.).
class ApiNetworkException implements Exception {
  /// Erstellt die Exception mit einer für Menschen lesbaren [message].
  const ApiNetworkException(this.message);

  /// Beschreibung des Transportfehlers.
  final String message;

  @override
  String toString() => 'ApiNetworkException: $message';
}

/// Generischer HTTP-Wrapper für das Cockpit-Backend.
///
/// Kennt die Basis-URL ([AppConstants.apiBaseUrl]), kodiert/dekodiert JSON
/// und hängt — sofern ein [TokenProvider] gesetzt ist und ein Token liefert —
/// automatisch `Authorization: Bearer <token>` an jeden Request an. Transport-
/// und HTTP-Fehler wirft er als [ApiNetworkException]/[ApiException]; die
/// fachliche Übersetzung in [Failure]-Typen übernehmen die Repositories
/// (Clean Architecture: keine Exceptions über Schichtgrenzen hinweg).
class ApiClient {
  /// Erstellt den Client. [httpClient] und [tokenProvider] sind für Tests
  /// austauschbar — ohne [tokenProvider] werden Requests ohne Auth-Header
  /// gesendet (z. B. für `POST /auth/login`).
  ApiClient({http.Client? httpClient, TokenProvider? tokenProvider})
    : _httpClient = httpClient ?? http.Client(),
      _tokenProvider = tokenProvider;

  final http.Client _httpClient;
  final TokenProvider? _tokenProvider;

  /// `GET <baseUrl><path>`, optional mit Query-Parametern.
  Future<Object?> get(String path, {Map<String, String>? queryParameters}) {
    return _send('GET', path, queryParameters: queryParameters);
  }

  /// `POST <baseUrl><path>` mit JSON-kodiertem [body].
  Future<Object?> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  /// `PUT <baseUrl><path>` mit JSON-kodiertem [body].
  Future<Object?> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  /// `DELETE <baseUrl><path>`.
  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}$path',
    ).replace(queryParameters: queryParameters);
    final headers = await _headers();
    final encodedBody = body == null ? null : jsonEncode(body);

    final http.Response response;
    try {
      response = switch (method) {
        'GET' => await _httpClient.get(uri, headers: headers),
        'POST' => await _httpClient.post(uri, headers: headers, body: encodedBody),
        'PUT' => await _httpClient.put(uri, headers: headers, body: encodedBody),
        'DELETE' => await _httpClient.delete(uri, headers: headers),
        _ => throw ArgumentError('Unbekannte HTTP-Methode: $method'),
      };
    } on SocketException catch (error) {
      throw ApiNetworkException(error.message);
    } on http.ClientException catch (error) {
      throw ApiNetworkException(error.message);
    }

    return _decode(response);
  }

  Future<Map<String, String>> _headers() async {
    final headers = {'content-type': 'application/json'};
    final token = await _tokenProvider?.call();
    if (token != null) headers['authorization'] = 'Bearer $token';
    return headers;
  }

  Object? _decode(http.Response response) {
    final raw = response.body;
    Object? decoded;
    if (raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        decoded = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map && decoded['error'] is String
        ? decoded['error'] as String
        : 'Unerwartete Antwort vom Server (${response.statusCode})';
    throw ApiException(response.statusCode, message);
  }
}
