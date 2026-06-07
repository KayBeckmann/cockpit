import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/context/app_context.dart';
import '../../../core/context/context_switch_provider.dart';
import '../../../core/errors/result.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';

/// Datenschicht-Zugriff für Aufgaben.
final Provider<TaskRepository> taskRepositoryProvider =
    Provider<TaskRepository>((ref) {
      return TaskRepository(ref.read(apiClientProvider));
    });

/// Lädt die Aufgabenliste passend zum globalen Kontext-Schalter (siehe
/// [contextSwitchProvider]/ADR-0006): `alles` zeigt unfiltert, `privat`/
/// `arbeit` filtern serverseitig. Ein Fehlschlag landet als [Failure] im
/// `error`-Kanal von [AsyncValue] (Clean Architecture: das Repository
/// liefert [Result], die Presentation-Schicht nutzt Riverpods Async-State).
class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final context = ref.watch(contextSwitchProvider);
    final result = await ref.read(taskRepositoryProvider).list(
      kontext: context == AppContext.alles ? null : context.name,
    );
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Lädt die Liste neu — z. B. nach Pull-to-Refresh oder einer Änderung,
  /// die den aktuellen Datenstand veraltet.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Aktuelle Aufgabenliste, gefiltert nach dem globalen Kontext, siehe
/// [TaskListNotifier].
///
/// `retry: null` deaktiviert Riverpods automatisches Wiederholen mit
/// exponentiellem Backoff: [Failure]s sind bereits übersetzte, fachliche
/// Fehler (kein `Error`), die sonst bis zu zehnmal im Hintergrund erneut
/// versucht würden, bevor sie als [AsyncError] sichtbar werden — die Nutzer
/// sähen minutenlang nur einen Ladeindikator statt der Fehlermeldung.
final AsyncNotifierProvider<TaskListNotifier, List<Task>> taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<Task>>(
      TaskListNotifier.new,
      retry: (_, _) => null,
    );
