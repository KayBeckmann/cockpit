import 'dart:io';

import 'package:backend/src/http/request_json.dart';
import 'package:backend/src/projects/project_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `GET /projects` (mit `?kontext=`, `?status=`) und `POST /projects`.
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method == HttpMethod.get) return _list(context);
  if (method == HttpMethod.post) return _create(context);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _list(RequestContext context) async {
  final params = context.request.uri.queryParameters;
  final repository = await context.read<Future<ProjectRepository>>();
  final projects = await repository.list(
    kontext: params['kontext'],
    status: params['status'],
  );
  return Response.json(
    body: projects.map((project) => project.toJson()).toList(),
  );
}

Future<Response> _create(RequestContext context) async {
  final body = await readJsonObject(context.request);
  final titel = body?['titel'];
  final kontext = body?['kontext'];
  if (titel is! String || titel.trim().isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'titel ist erforderlich'},
    );
  }
  if (kontext is! String || kontext.trim().isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'kontext ist erforderlich'},
    );
  }

  final repository = await context.read<Future<ProjectRepository>>();
  final project = await repository.create(
    titel: titel,
    kontext: kontext,
    typ: body?['typ'] as String?,
    status: body?['status'] as String?,
    fortschritt: body?['fortschritt'] as int?,
    meilensteine: body?['meilensteine'],
    ressourcen: body?['ressourcen'],
    obsidianUri: body?['obsidianUri'] as String?,
  );
  return Response.json(statusCode: HttpStatus.created, body: project.toJson());
}
