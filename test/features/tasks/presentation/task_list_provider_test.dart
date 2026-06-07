import 'package:cockpit/core/context/app_context.dart';
import 'package:cockpit/core/context/context_switch_provider.dart';
import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:cockpit/features/tasks/presentation/task_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTaskRepository repository;
  late ProviderContainer container;

  final task = Task(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    titel: 'Wäsche waschen',
    status: 'inbox',
    createdAt: DateTime.utc(2026, 6, 7, 8),
    updatedAt: DateTime.utc(2026, 6, 7, 8),
  );

  setUp(() {
    repository = _FakeTaskRepository();
    container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('build', () {
    test('lädt ungefiltert, wenn der Kontext-Schalter auf "alles" steht', () async {
      repository.listResult = Ok([task]);

      final result = await container.read(taskListProvider.future);

      expect(result, equals([task]));
      expect(repository.lastKontext, isNull);
    });

    test('filtert nach dem aktiven Kontext, wenn dieser nicht "alles" ist', () async {
      repository.listResult = Ok([task]);
      container.read(contextSwitchProvider.notifier).setContext(AppContext.privat);

      await container.read(taskListProvider.future);

      expect(repository.lastKontext, equals('privat'));
    });

    test('lädt neu, wenn sich der Kontext-Schalter ändert', () async {
      repository.listResult = Ok([task]);
      await container.read(taskListProvider.future);
      expect(repository.lastKontext, isNull);

      container.read(contextSwitchProvider.notifier).setContext(AppContext.arbeit);
      await container.read(taskListProvider.future);

      expect(repository.lastKontext, equals('arbeit'));
    });

    test('liefert AsyncError mit der Failure, wenn das Repository fehlschlägt', () async {
      const failure = ServerFailure('Authentifizierung erforderlich');
      repository.listResult = const Err(failure);

      Object? caught;
      try {
        await container.read(taskListProvider.future);
      } catch (error) {
        caught = error;
      }

      expect(caught, same(failure));
      expect(container.read(taskListProvider).error, same(failure));
    });
  });

  group('refresh', () {
    test('lädt die Liste neu', () async {
      repository.listResult = Ok([task]);
      await container.read(taskListProvider.future);
      expect(repository.listCallCount, equals(1));

      await container.read(taskListProvider.notifier).refresh();

      expect(repository.listCallCount, equals(2));
    });
  });
}

class _FakeTaskRepository implements TaskRepository {
  Result<List<Task>>? listResult;
  String? lastKontext;
  int listCallCount = 0;

  @override
  Future<Result<List<Task>>> list({
    String? kontext,
    String? status,
    String? projektId,
  }) async {
    lastKontext = kontext;
    listCallCount++;
    return listResult ?? const Err(ServerFailure('kein listResult gesetzt'));
  }

  @override
  Future<Result<Task>> find(String id) async =>
      const Err(ServerFailure('nicht implementiert'));

  @override
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
  }) async => const Err(ServerFailure('nicht implementiert'));

  @override
  Future<Result<Task>> update(String id, Map<String, Object?> changes) async =>
      const Err(ServerFailure('nicht implementiert'));

  @override
  Future<Result<void>> delete(String id) async =>
      const Err(ServerFailure('nicht implementiert'));
}
