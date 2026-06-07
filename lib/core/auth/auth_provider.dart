import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/result.dart';
import '../network/api_client.dart';
import 'auth_repository.dart';

/// Generischer HTTP-Client. Holt das JWT lazy über [authRepositoryProvider] —
/// ein direkter Konstruktor-Aufruf würde einen Zirkelbezug erzeugen, da
/// [AuthRepository] selbst über diesen Client einloggt.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenProvider: () => ref.read(authRepositoryProvider).loadToken(),
  );
});

/// Login und Token-Verwaltung.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
      return AuthRepository(apiClient: ref.read(apiClientProvider));
    });

/// Authentifizierungsstatus der App: `true` = eingeloggt, `false` = nicht.
/// `AsyncLoading` während Initialisierung/Login, `AsyncError` wenn der
/// letzte Login-Versuch fehlschlug (enthält die jeweilige [Failure]).
class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.read(authRepositoryProvider).loadToken();
    return token != null;
  }

  /// Meldet sich mit [email]/[password] an und aktualisiert den Status.
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).login(email, password);
    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  /// Meldet sich ab und setzt den Status auf "nicht eingeloggt".
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(false);
  }
}

/// Globaler Authentifizierungsstatus, siehe [AuthNotifier].
final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);
