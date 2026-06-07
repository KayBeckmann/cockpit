import 'package:dart_frog/dart_frog.dart';

/// Liest den Request-Body als JSON-Objekt. Liefert `null`, wenn der Body
/// fehlt, kein gültiges JSON ist oder kein Objekt enthält — die aufrufende
/// Route antwortet darauf einheitlich mit `400 Bad Request`.
Future<Map<String, Object?>?> readJsonObject(Request request) async {
  Object? body;
  try {
    body = await request.json();
  } on FormatException {
    return null;
  }
  return body is Map<String, Object?> ? body : null;
}

/// Parst einen ISO-8601-Zeitstempel aus dem JSON-Body. Liefert `null` bei
/// fehlendem oder nicht parsbarem Wert (z. B. `null`, falscher Typ, leer).
DateTime? parseDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
