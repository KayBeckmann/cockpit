import 'package:backend/src/auth/auth_middleware.dart';
import 'package:backend/src/tasks/task_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// Schützt alle `/tasks`-Routen mit der JWT-Middleware und stellt das
/// `TaskRepository` für die Handler bereit.
Handler middleware(Handler handler) => handler
    .use(requireAuth())
    .use(
      provider<Future<TaskRepository>>((context) async {
        final connection = await context.read<Future<Connection>>();
        return TaskRepository(connection);
      }),
    );
