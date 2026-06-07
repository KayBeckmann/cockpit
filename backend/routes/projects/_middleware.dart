import 'package:backend/src/auth/auth_middleware.dart';
import 'package:backend/src/projects/project_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// Schützt alle `/projects`-Routen mit der JWT-Middleware und stellt das
/// `ProjectRepository` für die Handler bereit.
Handler middleware(Handler handler) => handler
    .use(requireAuth())
    .use(
      provider<Future<ProjectRepository>>((context) async {
        final connection = await context.read<Future<Connection>>();
        return ProjectRepository(connection);
      }),
    );
