import 'package:cockpit/core/auth/auth_provider.dart';
import 'package:cockpit/core/auth/auth_repository.dart';
import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('build', () {
    test('liefert true, wenn ein Token gespeichert ist', () async {
      repository.token = 'gespeichertes-jwt';

      final result = await container.read(authProvider.future);

      expect(result, isTrue);
    });

    test('liefert false, wenn kein Token gespeichert ist', () async {
      final result = await container.read(authProvider.future);

      expect(result, isFalse);
    });
  });

  group('login', () {
    test('setzt den Status bei Erfolg auf eingeloggt', () async {
      await container.read(authProvider.future);
      repository.loginResult = const Ok('neues-jwt');

      await container.read(authProvider.notifier).login('kay@example.com', 'geheim');

      expect(container.read(authProvider), equals(const AsyncData<bool>(true)));
    });

    test('setzt den Status bei Fehlschlag auf AsyncError mit der Failure', () async {
      await container.read(authProvider.future);
      const failure = ServerFailure('Ungültige Zugangsdaten');
      repository.loginResult = const Err(failure);

      await container.read(authProvider.notifier).login('kay@example.com', 'falsch');

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error, same(failure));
    });
  });

  group('logout', () {
    test('meldet ab und setzt den Status auf nicht eingeloggt', () async {
      repository.token = 'gespeichertes-jwt';
      await container.read(authProvider.future);

      await container.read(authProvider.notifier).logout();

      expect(repository.loggedOut, isTrue);
      expect(container.read(authProvider), equals(const AsyncData<bool>(false)));
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  String? token;
  Result<String>? loginResult;
  bool loggedOut = false;

  @override
  Future<Result<String>> login(String email, String password) async {
    return loginResult ?? const Err(ServerFailure('kein loginResult gesetzt'));
  }

  @override
  Future<String?> loadToken() async => token;

  @override
  Future<void> logout() async {
    loggedOut = true;
    token = null;
  }
}
