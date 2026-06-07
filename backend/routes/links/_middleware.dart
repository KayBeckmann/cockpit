import 'package:backend/src/auth/auth_middleware.dart';
import 'package:backend/src/links/link_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// Schützt alle `/links`-Routen mit der JWT-Middleware und stellt das
/// `LinkRepository` für die Handler bereit.
Handler middleware(Handler handler) => handler
    .use(requireAuth())
    .use(
      provider<Future<LinkRepository>>((context) async {
        final connection = await context.read<Future<Connection>>();
        return LinkRepository(connection);
      }),
    );
