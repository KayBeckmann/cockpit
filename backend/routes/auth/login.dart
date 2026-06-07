import 'dart:io';

import 'package:backend/src/auth/jwt_service.dart';
import 'package:backend/src/auth/password_hasher.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// `POST /auth/login` — prüft E-Mail und Passwort gegen die
/// `users`-Tabelle und stellt bei Erfolg ein JWT aus.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final credentials = await _readCredentials(context.request);
  if (credentials == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'email und password sind erforderlich'},
    );
  }

  final connection = await context.read<Future<Connection>>();
  final result = await connection.execute(
    Sql.named('SELECT id, password_hash FROM users WHERE email = @email'),
    parameters: {'email': credentials.email},
  );

  if (result.isEmpty) {
    return _invalidCredentials();
  }

  final row = result.first;
  final userId = row[0]! as String;
  final passwordHash = row[1]! as String;

  if (!PasswordHasher.verify(credentials.password, passwordHash)) {
    return _invalidCredentials();
  }

  final token = context.read<JwtService>().issueToken(userId);
  return Response.json(body: {'token': token});
}

Response _invalidCredentials() => Response.json(
  statusCode: HttpStatus.unauthorized,
  body: {'error': 'E-Mail oder Passwort ist falsch'},
);

Future<_Credentials?> _readCredentials(Request request) async {
  Object? body;
  try {
    body = await request.json();
  } on FormatException {
    return null;
  }

  if (body is! Map || body['email'] is! String || body['password'] is! String) {
    return null;
  }

  return _Credentials(
    email: body['email']! as String,
    password: body['password']! as String,
  );
}

class _Credentials {
  const _Credentials({required this.email, required this.password});

  final String email;
  final String password;
}
