import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// Health-Check: prüft, ob die API läuft und die Datenbank erreichbar ist.
/// Dient u. a. dem M0-Deliverable ("Backend antwortet auf /health").
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final connection = await context.read<Future<Connection>>();
    await connection.execute('SELECT 1');
    return Response.json(body: {'status': 'ok', 'database': 'connected'});
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.serviceUnavailable,
      body: {'status': 'error', 'database': 'unreachable'},
    );
  }
}
