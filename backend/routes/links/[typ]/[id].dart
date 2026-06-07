import 'dart:io';

import 'package:backend/src/links/link_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `GET /links/:typ/:id` — alle Verknüpfungen einer Entität, unabhängig
/// davon, ob sie als Quelle oder Ziel auftritt.
Future<Response> onRequest(
  RequestContext context,
  String typ,
  String id,
) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final repository = await context.read<Future<LinkRepository>>();
  final links = await repository.listForObject(typ, id);
  return Response.json(body: links.map((link) => link.toJson()).toList());
}
