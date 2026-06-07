import 'package:cockpit/core/context/app_context.dart';
import 'package:cockpit/core/context/context_switch_provider.dart';
import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/projects/data/project_model.dart';
import 'package:cockpit/features/projects/data/project_repository.dart';
import 'package:cockpit/features/projects/presentation/project_list_provider.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:cockpit/features/tasks/presentation/task_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeProjectRepository projectRepository;
  late _FakeTaskRepository taskRepository;
  late ProviderContainer container;

  final project = Project(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    titel: 'Gartenhaus bauen',
    status: 'aktiv',
    fortschritt: 0,
    kontext: 'privat',
    createdAt: DateTime.utc(2026, 6, 7, 8),
    updatedAt: DateTime.utc(2026, 6, 7, 8),
  );

  setUp(() {
    projectRepository = _FakeProjectRepository();
    taskRepository = _FakeTaskRepository();
    container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(projectRepository),
        taskRepositoryProvider.overrideWithValue(taskRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  group('projectListProvider', () {
    test('lädt ungefiltert, wenn der Kontext-Schalter auf "alles" steht', () async {
      projectRepository.listResult = Ok([project]);

      final result = await container.read(projectListProvider.future);

      expect(result, equals([project]));
      expect(projectRepository.lastKontext, isNull);
    });

    test('filtert nach dem aktiven Kontext, wenn dieser nicht "alles" ist', () async {
      projectRepository.listResult = Ok([project]);
      container.read(contextSwitchProvider.notifier).setContext(AppContext.privat);

      await container.read(projectListProvider.future);

      expect(projectRepository.lastKontext, equals('privat'));
    });

    test('liefert AsyncError mit der Failure, wenn das Repository fehlschlägt', () async {
      const failure = ServerFailure('Authentifizierung erforderlich');
      projectRepository.listResult = const Err(failure);

      Object? caught;
      try {
        await container.read(projectListProvider.future);
      } catch (error) {
        caught = error;
      }

      expect(caught, same(failure));
      expect(container.read(projectListProvider).error, same(failure));
    });
  });

  group('refresh', () {
    test('lädt die Liste neu', () async {
      projectRepository.listResult = Ok([project]);
      await container.read(projectListProvider.future);
      expect(projectRepository.listCallCount, equals(1));

      await container.read(projectListProvider.notifier).refresh();

      expect(projectRepository.listCallCount, equals(2));
    });
  });

  group('projectTasksProvider', () {
    final task = Task(
      id: 'tttttttt-tttt-tttt-tttt-tttttttttttt',
      titel: 'Fundament gießen',
      status: 'aktiv',
      projektId: project.id,
      createdAt: DateTime.utc(2026, 6, 7, 8),
      updatedAt: DateTime.utc(2026, 6, 7, 8),
    );

    test('lädt die Aufgaben des angegebenen Projekts', () async {
      taskRepository.listResult = Ok([task]);

      final result = await container.read(projectTasksProvider(project.id).future);

      expect(result, equals([task]));
      expect(taskRepository.lastProjektId, equals(project.id));
    });

    test('liefert AsyncError mit der Failure, wenn das Repository fehlschlägt', () async {
      const failure = ServerFailure('Authentifizierung erforderlich');
      taskRepository.listResult = const Err(failure);

      Object? caught;
      try {
        await container.read(projectTasksProvider(project.id).future);
      } catch (error) {
        caught = error;
      }

      expect(caught, same(failure));
    });
  });
}

class _FakeProjectRepository implements ProjectRepository {
  Result<List<Project>>? listResult;
  String? lastKontext;
  int listCallCount = 0;

  @override
  Future<Result<List<Project>>> list({String? kontext, String? status}) async {
    lastKontext = kontext;
    listCallCount++;
    return listResult ?? const Err(ServerFailure('kein listResult gesetzt'));
  }

  @override
  Future<Result<Project>> find(String id) async =>
      const Err(ServerFailure('nicht implementiert'));

  @override
  Future<Result<Project>> create({
    required String titel,
    required String kontext,
    String? typ,
    String? status,
    int? fortschritt,
    Object? meilensteine,
    Object? ressourcen,
    String? obsidianUri,
  }) async => const Err(ServerFailure('nicht implementiert'));

  @override
  Future<Result<Project>> update(String id, Map<String, Object?> changes) async =>
      const Err(ServerFailure('nicht implementiert'));

  @override
  Future<Result<void>> delete(String id) async =>
      const Err(ServerFailure('nicht implementiert'));
}

class _FakeTaskRepository implements TaskRepository {
  Result<List<Task>>? listResult;
  String? lastProjektId;

  @override
  Future<Result<List<Task>>> list({
    String? kontext,
    String? status,
    String? projektId,
  }) async {
    lastProjektId = projektId;
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
