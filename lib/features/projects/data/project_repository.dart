import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import 'project_model.dart';

/// Datenschicht für Projekte (`/projects`-Routen des Backends).
///
/// Übersetzt Transport-/HTTP-Fehler des [ApiClient] in [Failure]s, damit
/// die Presentation-Schicht ausschließlich mit [Result] arbeitet (Clean
/// Architecture: keine Exceptions über Schichtgrenzen hinweg).
class ProjectRepository {
  /// Erstellt das Repository mit dem zu verwendenden [ApiClient].
  const ProjectRepository(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /projects`, optional gefiltert nach [kontext] und [status]
  /// (jeweils als Query-Parameter).
  Future<Result<List<Project>>> list({String? kontext, String? status}) {
    return _send(
      () => _apiClient.get(
        '/projects',
        queryParameters: {'kontext': ?kontext, 'status': ?status},
      ),
      (data) => (data! as List)
          .map((item) => Project.fromJson(item as Map<String, Object?>))
          .toList(),
    );
  }

  /// `GET /projects/:id`.
  Future<Result<Project>> find(String id) {
    return _send(() => _apiClient.get('/projects/$id'), _projectFrom);
  }

  /// `POST /projects`. [titel] und [kontext] sind erforderlich; alle
  /// anderen Felder werden nur bei Angabe in den Request-Body aufgenommen.
  Future<Result<Project>> create({
    required String titel,
    required String kontext,
    String? typ,
    String? status,
    int? fortschritt,
    Object? meilensteine,
    Object? ressourcen,
    String? obsidianUri,
  }) {
    return _send(
      () => _apiClient.post(
        '/projects',
        body: {
          'titel': titel,
          'kontext': kontext,
          'typ': ?typ,
          'status': ?status,
          'fortschritt': ?fortschritt,
          'meilensteine': ?meilensteine,
          'ressourcen': ?ressourcen,
          'obsidianUri': ?obsidianUri,
        },
      ),
      _projectFrom,
    );
  }

  /// `PUT /projects/:id` mit PATCH-Semantik — nur die in [changes]
  /// enthaltenen Schlüssel werden aktualisiert; ein expliziter
  /// `null`-Wert löscht das jeweilige Feld.
  Future<Result<Project>> update(String id, Map<String, Object?> changes) {
    return _send(() => _apiClient.put('/projects/$id', body: changes), _projectFrom);
  }

  /// `DELETE /projects/:id`.
  Future<Result<void>> delete(String id) {
    return _send(() => _apiClient.delete('/projects/$id'), (_) {});
  }

  Project _projectFrom(Object? data) =>
      Project.fromJson(data! as Map<String, Object?>);

  Future<Result<T>> _send<T>(
    Future<Object?> Function() call,
    T Function(Object? data) map,
  ) async {
    try {
      return Ok(map(await call()));
    } on ApiException catch (error) {
      return Err(ServerFailure(error.message));
    } on ApiNetworkException catch (error) {
      return Err(NetworkFailure(error.message));
    }
  }
}
