import 'dart:io';

import 'package:backend/src/auth/jwt_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Repräsentiert den per Bearer-Token authentifizierten Benutzer.
/// Geschützte Routen lesen ihn per `context.read<AuthenticatedUser>()`.
class AuthenticatedUser {
  /// Erstellt den authentifizierten Benutzer mit seiner [id].
  const AuthenticatedUser({required this.id});

  /// ID des Benutzers (entspricht `users.id`).
  final String id;
}

/// Middleware, das eingehende Requests anhand eines `Authorization:
/// Bearer <token>`-Headers prüft. Bei gültigem Token steht
/// [AuthenticatedUser] im Kontext der nachgelagerten Handler zur
/// Verfügung; andernfalls antwortet es direkt mit 401, ohne den
/// eigentlichen Handler aufzurufen.
///
/// Liest den [JwtService] aus dem Kontext (bereitgestellt von der
/// globalen `routes/_middleware.dart`). Gedacht zum Einsatz in
/// `_middleware.dart` von Routengruppen, die Authentifizierung
/// benötigen (ab M1, z.B. `routes/tasks/`).
Middleware requireAuth() {
  return (handler) {
    return (context) async {
      final token = _bearerToken(context.request.headers['authorization']);
      if (token == null) {
        return _unauthorized('Authentifizierung erforderlich');
      }

      final jwtService = context.read<JwtService>();
      final userId = jwtService.verifyToken(token);
      if (userId == null) {
        return _unauthorized('Ungültiges oder abgelaufenes Token');
      }

      return handler(
        context.provide<AuthenticatedUser>(
          () => AuthenticatedUser(id: userId),
        ),
      );
    };
  };
}

String? _bearerToken(String? header) {
  const prefix = 'Bearer ';
  if (header == null || !header.startsWith(prefix)) return null;

  final token = header.substring(prefix.length).trim();
  return token.isEmpty ? null : token;
}

Response _unauthorized(String message) => Response.json(
  statusCode: HttpStatus.unauthorized,
  body: {'error': message},
);
