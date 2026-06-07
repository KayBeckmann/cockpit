import 'dart:io';

import 'package:backend/src/http/request_json.dart';
import 'package:backend/src/tasks/task_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `GET /tasks` (mit `?kontext=`, `?status=`, `?projekt_id=`) und
/// `POST /tasks`.
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method == HttpMethod.get) return _list(context);
  if (method == HttpMethod.post) return _create(context);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _list(RequestContext context) async {
  final params = context.request.uri.queryParameters;
  final repository = await context.read<Future<TaskRepository>>();
  final tasks = await repository.list(
    kontext: params['kontext'],
    status: params['status'],
    projektId: params['projekt_id'],
  );
  return Response.json(body: tasks.map((task) => task.toJson()).toList());
}

Future<Response> _create(RequestContext context) async {
  final body = await readJsonObject(context.request);
  final titel = body?['titel'];
  if (titel is! String || titel.trim().isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'titel ist erforderlich'},
    );
  }

  final repository = await context.read<Future<TaskRepository>>();
  final task = await repository.create(
    titel: titel,
    beschreibung: body?['beschreibung'] as String?,
    deadline: parseDateTime(body?['deadline']),
    prioritaet: body?['prioritaet'] as int?,
    status: body?['status'] as String?,
    projektId: body?['projektId'] as String?,
    kontext: body?['kontext'] as String?,
    energieLevel: body?['energieLevel'] as String?,
    tags: (body?['tags'] as List?)?.cast<String>(),
  );
  return Response.json(statusCode: HttpStatus.created, body: task.toJson());
}
