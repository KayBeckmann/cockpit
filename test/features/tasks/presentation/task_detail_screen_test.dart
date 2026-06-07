import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:cockpit/features/tasks/presentation/task_detail_screen.dart';
import 'package:cockpit/features/tasks/presentation/task_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTaskRepository repository;

  final task = Task(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    titel: 'Wäsche waschen',
    beschreibung: 'Bunte und weiße Wäsche getrennt',
    status: 'aktiv',
    prioritaet: 2,
    kontext: 'privat',
    energieLevel: 'niedrig',
    tags: const ['haushalt', 'wöchentlich'],
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 1),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    // Großes Surface, damit das gesamte Formular (inkl. Tags-Feld und
    // Speichern-Button am Ende der ListView) ohne Scrollen aufgebaut wird —
    // sonst erstellt die Sliver-Liste die unteren Felder gar nicht erst.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: TaskDetailScreen(task: task)),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _FakeTaskRepository();
  });

  testWidgets('zeigt die aktuellen Werte der Aufgabe vorausgefüllt an', (tester) async {
    await pumpScreen(tester);

    expect(find.widgetWithText(TextFormField, 'Wäsche waschen'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Bunte und weiße Wäsche getrennt'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'haushalt, wöchentlich'), findsOneWidget);
  });

  testWidgets('verlangt einen Titel', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Wäsche waschen'), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Bitte einen Titel eingeben'), findsOneWidget);
    expect(repository.updateCalls, isEmpty);
  });

  testWidgets('speichert die geänderten Felder und schließt den Bildschirm', (tester) async {
    repository.updateResult = Ok(task);
    await pumpScreen(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Wäsche waschen'), 'Wäsche aufhängen');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, hasLength(1));
    final (id, changes) = repository.updateCalls.single;
    expect(id, equals(task.id));
    expect(changes['titel'], equals('Wäsche aufhängen'));
    expect(changes['beschreibung'], equals('Bunte und weiße Wäsche getrennt'));
    expect(changes['status'], equals('aktiv'));
    expect(changes['kontext'], equals('privat'));
    expect(changes['energieLevel'], equals('niedrig'));
    expect(changes['tags'], equals(['haushalt', 'wöchentlich']));
    expect(find.byType(TaskDetailScreen), findsNothing);
  });

  testWidgets('zeigt die Fehlermeldung bei einem Fehlschlag und bleibt offen', (tester) async {
    repository.updateResult = const Err(ServerFailure('Aufgabe konnte nicht gespeichert werden'));
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Aufgabe konnte nicht gespeichert werden'), findsOneWidget);
    expect(find.byType(TaskDetailScreen), findsOneWidget);
  });
}

class _FakeTaskRepository implements TaskRepository {
  final List<(String, Map<String, Object?>)> updateCalls = [];
  Result<Task>? updateResult;

  @override
  Future<Result<Task>> update(String id, Map<String, Object?> changes) async {
    updateCalls.add((id, changes));
    return updateResult ?? const Err(ServerFailure('kein updateResult gesetzt'));
  }

  @override
  Future<Result<List<Task>>> list({
    String? kontext,
    String? status,
    String? projektId,
  }) async => const Ok([]);

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
  Future<Result<void>> delete(String id) async =>
      const Err(ServerFailure('nicht implementiert'));
}
