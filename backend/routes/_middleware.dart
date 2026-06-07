import 'package:backend/src/db/database.dart';
import 'package:backend/src/env/env.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Handler middleware(Handler handler) {
  final env = loadEnv();
  final config = DatabaseConfig.fromEnv(env);

  return handler.use(
    provider<Future<Connection>>((context) => openConnection(config)),
  );
}
