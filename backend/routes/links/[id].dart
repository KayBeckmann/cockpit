import 'dart:io';

import 'package:backend/src/links/link_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `DELETE /links/:id` — entfernt eine Verknüpfung.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final repository = await context.read<Future<LinkRepository>>();
  final deleted = await repository.delete(id);
  return deleted
      ? Response(statusCode: HttpStatus.noContent)
      : Response.json(
          statusCode: HttpStatus.notFound,
          body: {'error': 'Verknüpfung nicht gefunden'},
        );
}
