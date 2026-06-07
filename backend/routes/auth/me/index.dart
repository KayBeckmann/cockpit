import 'dart:io';

import 'package:backend/src/auth/auth_middleware.dart';
import 'package:dart_frog/dart_frog.dart';

/// `GET /auth/me` — liefert die ID des per Token authentifizierten
/// Benutzers zurück. Dient als Beispiel- und Test-Route für die
/// JWT-Middleware, bis ab M1 echte geschützte Ressourcen folgen.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final user = context.read<AuthenticatedUser>();
  return Response.json(body: {'id': user.id});
}
