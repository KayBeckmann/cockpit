import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/failures.dart';
import '../errors/result.dart';
import '../network/api_client.dart';

/// Schlüssel, unter dem das JWT im sicheren Speicher abgelegt wird.
const _tokenStorageKey = 'cockpit_auth_token';

/// Übernimmt Login und Token-Verwaltung gegenüber dem Backend.
///
/// Speichert das JWT nach erfolgreichem Login in [FlutterSecureStorage]
/// und stellt es sowohl für nachfolgende Requests (über [ApiClient.new]s
/// `tokenProvider`) als auch für die Wiederherstellung des Login-Zustands
/// beim App-Start bereit.
class AuthRepository {
  /// Erstellt das Repository. [storage] ist für Tests austauschbar.
  AuthRepository({required ApiClient apiClient, FlutterSecureStorage? storage})
    : _apiClient = apiClient,
      _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  /// Meldet sich mit [email] und [password] an. Speichert das JWT bei
  /// Erfolg sicher und liefert es zurück; andernfalls die aufgetretene
  /// [Failure].
  Future<Result<String>> login(String email, String password) async {
    final Object? response;
    try {
      response = await _apiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
    } on ApiException catch (error) {
      return Err(ServerFailure(error.message));
    } on ApiNetworkException catch (error) {
      return Err(NetworkFailure(error.message));
    }

    final token = response is Map ? response['token'] : null;
    if (token is! String) {
      return const Err(ServerFailure('Antwort enthielt kein gültiges Token'));
    }

    await _storage.write(key: _tokenStorageKey, value: token);
    return Ok(token);
  }

  /// Liefert das gespeicherte JWT, oder `null`, wenn niemand eingeloggt ist.
  Future<String?> loadToken() => _storage.read(key: _tokenStorageKey);

  /// Löscht das gespeicherte JWT (Logout).
  Future<void> logout() => _storage.delete(key: _tokenStorageKey);
}
