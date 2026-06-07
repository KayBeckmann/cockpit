import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import 'task_model.dart';

/// Datenschicht für Aufgaben (`/tasks`-Routen des Backends).
///
/// Übersetzt Transport-/HTTP-Fehler des [ApiClient] in [Failure]s, damit
/// die Presentation-Schicht ausschließlich mit [Result] arbeitet (Clean
/// Architecture: keine Exceptions über Schichtgrenzen hinweg).
class TaskRepository {
  /// Erstellt das Repository mit dem zu verwendenden [ApiClient].
  const TaskRepository(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /tasks`, optional gefiltert nach [kontext], [status] und
  /// [projektId] (jeweils als Query-Parameter).
  Future<Result<List<Task>>> list({
    String? kontext,
    String? status,
    String? projektId,
  }) {
    return _send(
      () => _apiClient.get(
        '/tasks',
        queryParameters: {
          'kontext': ?kontext,
          'status': ?status,
          'projekt_id': ?projektId,
        },
      ),
      (data) => (data! as List)
          .map((item) => Task.fromJson(item as Map<String, Object?>))
          .toList(),
    );
  }

  /// `GET /tasks/:id`.
  Future<Result<Task>> find(String id) {
    return _send(() => _apiClient.get('/tasks/$id'), _taskFrom);
  }

  /// `POST /tasks`. Nur [titel] ist erforderlich; alle anderen Felder
  /// werden nur bei Angabe in den Request-Body aufgenommen.
  Future<Result<Task>> create({
    required String titel,
    String? beschreibung,
    DateTime? deadline,
    int? prioritaet,
    String? status,
    String? projektId,
    String? kontext,
    Map<String, Object?>? wiederholung,
    String? energieLevel,
    List<String>? tags,
  }) {
    return _send(
      () => _apiClient.post(
        '/tasks',
        body: {
          'titel': titel,
          'beschreibung': ?beschreibung,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
          'prioritaet': ?prioritaet,
          'status': ?status,
          'projektId': ?projektId,
          'kontext': ?kontext,
          'wiederholung': ?wiederholung,
          'energieLevel': ?energieLevel,
          'tags': ?tags,
        },
      ),
      _taskFrom,
    );
  }

  /// `PUT /tasks/:id` mit PATCH-Semantik — nur die in [changes] enthaltenen
  /// Schlüssel werden aktualisiert; ein expliziter `null`-Wert löscht das
  /// jeweilige Feld. Schlüssel folgen dem camelCase-Request-Format der
  /// Route (z. B. `projektId`, `energieLevel`, `wiederholung`).
  Future<Result<Task>> update(String id, Map<String, Object?> changes) {
    return _send(() => _apiClient.put('/tasks/$id', body: changes), _taskFrom);
  }

  /// `DELETE /tasks/:id`.
  Future<Result<void>> delete(String id) {
    return _send(() => _apiClient.delete('/tasks/$id'), (_) {});
  }

  Task _taskFrom(Object? data) => Task.fromJson(data! as Map<String, Object?>);

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
