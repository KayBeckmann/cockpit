import 'dart:io';

import 'package:backend/src/http/request_json.dart';
import 'package:backend/src/projects/project_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `GET|PUT|DELETE /projects/:id`.
Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;
  if (method == HttpMethod.get) return _show(context, id);
  if (method == HttpMethod.put) return _update(context, id);
  if (method == HttpMethod.delete) return _delete(context, id);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _show(RequestContext context, String id) async {
  final repository = await context.read<Future<ProjectRepository>>();
  final project = await repository.find(id);
  return project == null
      ? _notFound()
      : Response.json(body: project.toJson());
}

Future<Response> _update(RequestContext context, String id) async {
  final body = await readJsonObject(context.request);
  if (body == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Ungültiger JSON-Body'},
    );
  }

  final changes = <String, Object?>{};
  for (final entry in const {
    'titel': 'titel',
    'typ': 'typ',
    'status': 'status',
    'fortschritt': 'fortschritt',
    'meilensteine': 'meilensteine',
    'ressourcen': 'ressourcen',
    'kontext': 'kontext',
    'obsidianUri': 'obsidian_uri',
  }.entries) {
    if (body.containsKey(entry.key)) changes[entry.value] = body[entry.key];
  }

  final repository = await context.read<Future<ProjectRepository>>();
  final project = await repository.update(id, changes);
  return project == null
      ? _notFound()
      : Response.json(body: project.toJson());
}

Future<Response> _delete(RequestContext context, String id) async {
  final repository = await context.read<Future<ProjectRepository>>();
  final deleted = await repository.delete(id);
  return deleted ? Response(statusCode: HttpStatus.noContent) : _notFound();
}

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  body: {'error': 'Projekt nicht gefunden'},
);
