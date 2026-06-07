import 'dart:async';

import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:cockpit/features/tasks/presentation/task_list_provider.dart';
import 'package:cockpit/features/tasks/presentation/task_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTaskRepository repository;

  final now = DateTime.now();
  final todayNoon = DateTime(now.year, now.month, now.day, 12);
  final yesterdayNoon = todayNoon.subtract(const Duration(days: 1));
  final tomorrowNoon = todayNoon.add(const Duration(days: 1));

  Task buildTask({
    required String id,
    required String titel,
    String status = 'inbox',
    DateTime? deadline,
    DateTime? createdAt,
    int? prioritaet,
    String? energieLevel,
  }) {
    final timestamp = createdAt ?? DateTime.utc(2026, 6, 1);
    return Task(
      id: id,
      titel: titel,
      status: status,
      deadline: deadline,
      prioritaet: prioritaet,
      energieLevel: energieLevel,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: TaskListScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _FakeTaskRepository();
  });

  testWidgets('zeigt einen Ladeindikator, während die Liste lädt', (tester) async {
    final completer = Completer<Result<List<Task>>>();
    repository.listHandler = (_, _, _) => completer.future;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: TaskListScreen())),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const Ok([]));
    await tester.pumpAndSettle();
  });

  testWidgets('Inbox-Tab zeigt nur Inbox-Aufgaben, neueste zuerst', (tester) async {
    repository.listResult = Ok([
      buildTask(id: '1', titel: 'Älterer Capture', createdAt: DateTime.utc(2026, 6, 1)),
      buildTask(id: '2', titel: 'Neuerer Capture', createdAt: DateTime.utc(2026, 6, 5)),
      buildTask(id: '3', titel: 'Schon eingeordnet', status: 'aktiv'),
    ]);

    await pumpScreen(tester);

    expect(find.text('Neuerer Capture'), findsOneWidget);
    expect(find.text('Älterer Capture'), findsOneWidget);
    expect(find.text('Schon eingeordnet'), findsNothing);

    final positionNeu = tester.getTopLeft(find.text('Neuerer Capture')).dy;
    final positionAlt = tester.getTopLeft(find.text('Älterer Capture')).dy;
    expect(positionNeu, lessThan(positionAlt));
  });

  testWidgets('Inbox-Tab zeigt einen Hinweis, wenn die Inbox leer ist', (tester) async {
    repository.listResult = Ok([buildTask(id: '1', titel: 'Aktive Aufgabe', status: 'aktiv')]);

    await pumpScreen(tester);

    expect(find.textContaining('Inbox ist leer'), findsOneWidget);
  });

  testWidgets('Heute-Tab zeigt fällige und überfällige aktive Aufgaben, sortiert nach Fälligkeit', (
    tester,
  ) async {
    repository.listResult = Ok([
      buildTask(id: '1', titel: 'Morgen fällig', status: 'aktiv', deadline: tomorrowNoon),
      buildTask(id: '2', titel: 'Heute fällig', status: 'aktiv', deadline: todayNoon),
      buildTask(id: '3', titel: 'Überfällig', status: 'aktiv', deadline: yesterdayNoon),
      buildTask(id: '4', titel: 'Erledigt, aber heute fällig', status: 'erledigt', deadline: todayNoon),
      buildTask(id: '5', titel: 'Ohne Deadline', status: 'aktiv'),
    ]);

    await pumpScreen(tester);
    await tester.tap(find.text('Heute'));
    await tester.pumpAndSettle();

    expect(find.text('Überfällig'), findsOneWidget);
    expect(find.text('Heute fällig'), findsOneWidget);
    expect(find.text('Morgen fällig'), findsNothing);
    expect(find.text('Erledigt, aber heute fällig'), findsNothing);
    expect(find.text('Ohne Deadline'), findsNothing);

    final positionUeberfaellig = tester.getTopLeft(find.text('Überfällig')).dy;
    final positionHeute = tester.getTopLeft(find.text('Heute fällig')).dy;
    expect(positionUeberfaellig, lessThan(positionHeute));
  });

  testWidgets(
    'Heute-Tab sortiert bei gleicher Fälligkeit nach Priorität (Eisenhower: Dringlichkeit × Wichtigkeit)',
    (tester) async {
      repository.listResult = Ok([
        buildTask(
          id: '1',
          titel: 'Niedrige Priorität',
          status: 'aktiv',
          deadline: todayNoon,
          prioritaet: 1,
        ),
        buildTask(
          id: '2',
          titel: 'Kritische Priorität',
          status: 'aktiv',
          deadline: todayNoon,
          prioritaet: 4,
        ),
        buildTask(id: '3', titel: 'Überfällig, ohne Priorität', status: 'aktiv', deadline: yesterdayNoon),
      ]);

      await pumpScreen(tester);
      await tester.tap(find.text('Heute'));
      await tester.pumpAndSettle();

      final positionUeberfaellig = tester.getTopLeft(find.text('Überfällig, ohne Priorität')).dy;
      final positionKritisch = tester.getTopLeft(find.text('Kritische Priorität')).dy;
      final positionNiedrig = tester.getTopLeft(find.text('Niedrige Priorität')).dy;

      // Dringlichkeit (Fälligkeit) schlägt Wichtigkeit (Priorität): das
      // überfällige Element steht trotz fehlender Priorität ganz oben.
      expect(positionUeberfaellig, lessThan(positionKritisch));
      // Bei gleicher Fälligkeit gewinnt die höhere Priorität.
      expect(positionKritisch, lessThan(positionNiedrig));
    },
  );

  testWidgets('Heute-Tab zeigt einen Hinweis, wenn nichts ansteht', (tester) async {
    repository.listResult = Ok([buildTask(id: '1', titel: 'Ohne Deadline', status: 'aktiv')]);

    await pumpScreen(tester);
    await tester.tap(find.text('Heute'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Für heute steht nichts an'), findsOneWidget);
  });

  testWidgets('Alle-Tab zeigt sämtliche geladenen Aufgaben', (tester) async {
    repository.listResult = Ok([
      buildTask(id: '1', titel: 'Inbox-Eintrag'),
      buildTask(id: '2', titel: 'Aktive Aufgabe', status: 'aktiv', deadline: todayNoon),
      buildTask(id: '3', titel: 'Archivierte Aufgabe', status: 'archiviert'),
    ]);

    await pumpScreen(tester);
    await tester.tap(find.text('Alle'));
    await tester.pumpAndSettle();

    expect(find.text('Inbox-Eintrag'), findsOneWidget);
    expect(find.text('Aktive Aufgabe'), findsOneWidget);
    expect(find.text('Archivierte Aufgabe'), findsOneWidget);
  });

  testWidgets('zeigt das Energie-Level einer Aufgabe als Tag an', (tester) async {
    repository.listResult = Ok([
      buildTask(id: '1', titel: 'Konzentrationsarbeit', energieLevel: 'hoch'),
      buildTask(id: '2', titel: 'Kleinkram', energieLevel: 'niedrig'),
      buildTask(id: '3', titel: 'Ohne Angabe'),
    ]);

    await pumpScreen(tester);
    await tester.tap(find.text('Alle'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Chip), matching: find.text('hoch')), findsOneWidget);
    expect(find.descendant(of: find.byType(Chip), matching: find.text('niedrig')), findsOneWidget);
  });

  testWidgets(
    'Energie-Level-Filter schränkt alle Ansichten auf das gewählte Level ein und lässt sich wieder aufheben',
    (tester) async {
      repository.listResult = Ok([
        buildTask(id: '1', titel: 'Hochenergie-Aufgabe', energieLevel: 'hoch'),
        buildTask(id: '2', titel: 'Niedrigenergie-Aufgabe', energieLevel: 'niedrig'),
        buildTask(id: '3', titel: 'Ohne Energie-Level'),
      ]);

      await pumpScreen(tester);
      await tester.tap(find.text('Alle'));
      await tester.pumpAndSettle();

      expect(find.text('Hochenergie-Aufgabe'), findsOneWidget);
      expect(find.text('Niedrigenergie-Aufgabe'), findsOneWidget);
      expect(find.text('Ohne Energie-Level'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'hoch'));
      await tester.pumpAndSettle();

      expect(find.text('Hochenergie-Aufgabe'), findsOneWidget);
      expect(find.text('Niedrigenergie-Aufgabe'), findsNothing);
      expect(find.text('Ohne Energie-Level'), findsNothing);

      // Erneutes Antippen hebt den Filter wieder auf.
      await tester.tap(find.widgetWithText(FilterChip, 'hoch'));
      await tester.pumpAndSettle();

      expect(find.text('Hochenergie-Aufgabe'), findsOneWidget);
      expect(find.text('Niedrigenergie-Aufgabe'), findsOneWidget);
      expect(find.text('Ohne Energie-Level'), findsOneWidget);
    },
  );

  testWidgets('zeigt eine Fehlermeldung mit Wiederholen-Button bei einem Fehlschlag', (
    tester,
  ) async {
    repository.listResult = const Err(ServerFailure('Authentifizierung erforderlich'));

    await pumpScreen(tester);

    expect(find.text('Authentifizierung erforderlich'), findsOneWidget);

    repository.listResult = const Ok([]);
    await tester.tap(find.widgetWithText(FilledButton, 'Erneut versuchen'));
    await tester.pumpAndSettle();

    expect(find.text('Authentifizierung erforderlich'), findsNothing);
    expect(repository.listCallCount, equals(2));
  });
}

class _FakeTaskRepository implements TaskRepository {
  Result<List<Task>>? listResult;
  Future<Result<List<Task>>> Function(String? kontext, String? status, String? projektId)?
  listHandler;
  int listCallCount = 0;

  @override
  Future<Result<List<Task>>> list({
    String? kontext,
    String? status,
    String? projektId,
  }) {
    listCallCount++;
    if (listHandler != null) return listHandler!(kontext, status, projektId);
    return Future.value(listResult ?? const Err(ServerFailure('kein listResult gesetzt')));
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
