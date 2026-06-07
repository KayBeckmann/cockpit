import 'dart:io';

import 'package:backend/src/http/request_json.dart';
import 'package:backend/src/links/link_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `POST /links` — erstellt eine Verknüpfung zwischen zwei Entitäten.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await readJsonObject(context.request);
  final vonTyp = body?['vonTyp'];
  final vonId = body?['vonId'];
  final zuTyp = body?['zuTyp'];
  final zuId = body?['zuId'];
  if (vonTyp is! String ||
      vonId is! String ||
      zuTyp is! String ||
      zuId is! String ||
      vonTyp.trim().isEmpty ||
      vonId.trim().isEmpty ||
      zuTyp.trim().isEmpty ||
      zuId.trim().isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'vonTyp, vonId, zuTyp und zuId sind erforderlich'},
    );
  }

  final repository = await context.read<Future<LinkRepository>>();
  final link = await repository.create(
    vonTyp: vonTyp,
    vonId: vonId,
    zuTyp: zuTyp,
    zuId: zuId,
    beziehung: body?['beziehung'] as String?,
  );
  return Response.json(statusCode: HttpStatus.created, body: link.toJson());
}
