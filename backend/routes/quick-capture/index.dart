import 'dart:io';

import 'package:backend/src/http/request_json.dart';
import 'package:backend/src/tasks/task_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// `POST /quick-capture` — legt eine Aufgabe ohne Kontext in der Inbox an
/// (schnelles Erfassen, z. B. via Matrix-Bot/n8n). Die GTD-Triage ordnet sie
/// später Kontext, Status und ggf. einem Projekt zu.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

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
    status: 'inbox',
  );
  return Response.json(statusCode: HttpStatus.created, body: task.toJson());
}
