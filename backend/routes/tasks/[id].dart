import 'dart:io';

import 'package:backend/src/http/request_json.dart';
import 'package:backend/src/tasks/task_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `GET|PUT|DELETE /tasks/:id`.
Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;
  if (method == HttpMethod.get) return _show(context, id);
  if (method == HttpMethod.put) return _update(context, id);
  if (method == HttpMethod.delete) return _delete(context, id);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _show(RequestContext context, String id) async {
  final repository = await context.read<Future<TaskRepository>>();
  final task = await repository.find(id);
  return task == null ? _notFound() : Response.json(body: task.toJson());
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
    'beschreibung': 'beschreibung',
    'prioritaet': 'prioritaet',
    'status': 'status',
    'projektId': 'projekt_id',
    'kontext': 'kontext',
    'energieLevel': 'energie_level',
  }.entries) {
    if (body.containsKey(entry.key)) changes[entry.value] = body[entry.key];
  }
  if (body.containsKey('deadline')) {
    changes['deadline'] = parseDateTime(body['deadline']);
  }
  if (body.containsKey('tags')) {
    changes['tags'] = (body['tags'] as List?)?.cast<String>();
  }

  final repository = await context.read<Future<TaskRepository>>();
  final task = await repository.update(id, changes);
  return task == null ? _notFound() : Response.json(body: task.toJson());
}

Future<Response> _delete(RequestContext context, String id) async {
  final repository = await context.read<Future<TaskRepository>>();
  final deleted = await repository.delete(id);
  return deleted ? Response(statusCode: HttpStatus.noContent) : _notFound();
}

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  body: {'error': 'Task nicht gefunden'},
);
