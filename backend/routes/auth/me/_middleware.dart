import 'package:backend/src/auth/auth_middleware.dart';
import 'package:dart_frog/dart_frog.dart';

/// Schützt alle Routen unter `/auth/me` mit der JWT-Middleware.
Handler middleware(Handler handler) => handler.use(requireAuth());
