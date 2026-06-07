import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/projects/data/project_model.dart';
import 'package:cockpit/features/projects/presentation/project_detail_screen.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:cockpit/features/tasks/presentation/task_date_format.dart';
import 'package:cockpit/features/tasks/presentation/task_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTaskRepository taskRepository;

  final project = Project(
    id: 'pppppppp-pppp-pppp-pppp-pppppppppppp',
    titel: 'Gartenhaus bauen',
    typ: 'hobby',
    status: 'aktiv',
    fortschritt: 50,
    kontext: 'privat',
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 1),
  );

  final deadline = DateTime.utc(2026, 8, 1, 10);

  Task buildTask({required String id, required String titel, required String status, DateTime? deadline}) {
    final timestamp = DateTime.utc(2026, 6, 1);
    return Task(
      id: id,
      titel: titel,
      status: status,
      deadline: deadline,
      projektId: project.id,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(taskRepository)],
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    taskRepository = _FakeTaskRepository();
  });

  testWidgets('zeigt Stammdaten, Fortschritt und Aufgaben des Projekts an', (tester) async {
    taskRepository.listResult = Ok([
      buildTask(id: '1', titel: 'Fundament gießen', status: 'erledigt'),
      buildTask(id: '2', titel: 'Wände aufstellen', status: 'aktiv', deadline: deadline),
      buildTask(id: '3', titel: 'Dach decken', status: 'inbox'),
      buildTask(id: '4', titel: 'Altlast entsorgen', status: 'archiviert'),
    ]);

    await pumpScreen(tester);

    expect(find.text('Gartenhaus bauen'), findsWidgets);
    expect(find.text('Aktiv'), findsOneWidget);
    expect(find.text('hobby'), findsOneWidget);
    expect(find.text('Kontext: privat'), findsOneWidget);

    // 2 von 4 Aufgaben gelten als erledigt (erledigt + archiviert).
    expect(find.text('50 % erledigt (2 von 4 Aufgaben)'), findsOneWidget);

    expect(find.text('Fundament gießen'), findsOneWidget);
    expect(find.text('Wände aufstellen'), findsOneWidget);
    expect(find.text('Fällig: ${formatTaskDate(deadline)}'), findsOneWidget);
    expect(find.text('Dach decken'), findsOneWidget);
    expect(find.text('Altlast entsorgen'), findsOneWidget);

    expect(taskRepository.lastProjektId, equals(project.id));
  });

  testWidgets('zeigt einen Hinweis, wenn dem Projekt keine Aufgaben zugeordnet sind', (
    tester,
  ) async {
    taskRepository.listResult = const Ok([]);

    await pumpScreen(tester);

    expect(find.text('Noch keine Aufgaben verknüpft'), findsOneWidget);
    expect(find.text('Diesem Projekt sind noch keine Aufgaben zugeordnet.'), findsOneWidget);
  });

  testWidgets('zeigt eine Fehlermeldung mit Wiederholen-Button bei einem Fehlschlag', (
    tester,
  ) async {
    taskRepository.listResult = const Err(ServerFailure('Authentifizierung erforderlich'));

    await pumpScreen(tester);

    expect(find.text('Authentifizierung erforderlich'), findsOneWidget);

    taskRepository.listResult = const Ok([]);
    await tester.tap(find.widgetWithText(FilledButton, 'Erneut versuchen'));
    await tester.pumpAndSettle();

    expect(find.text('Authentifizierung erforderlich'), findsNothing);
    expect(find.text('Noch keine Aufgaben verknüpft'), findsOneWidget);
  });
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
