import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:cockpit/features/tasks/presentation/task_create_sheet.dart';
import 'package:cockpit/features/tasks/presentation/task_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTaskRepository repository;

  final created = Task(
    id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    titel: 'Neue Aufgabe',
    status: 'inbox',
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 1),
  );

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => TaskCreateSheet.show(context),
                  child: const Text('Öffnen'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _FakeTaskRepository();
  });

  testWidgets('verlangt einen Titel', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Erfassen'));
    await tester.pumpAndSettle();

    expect(find.text('Bitte einen Titel eingeben'), findsOneWidget);
    expect(repository.createCalls, isEmpty);
  });

  testWidgets('erfasst eine Aufgabe mit Titel und schließt das Sheet', (tester) async {
    repository.createResult = Ok(created);
    await pumpSheet(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Titel'), 'Neue Aufgabe');
    await tester.tap(find.widgetWithText(FilledButton, 'Erfassen'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, hasLength(1));
    final call = repository.createCalls.single;
    expect(call.titel, equals('Neue Aufgabe'));
    expect(call.beschreibung, isNull);
    expect(call.deadline, isNull);
    expect(call.kontext, isNull);
    expect(call.energieLevel, isNull);
    expect(find.byType(TaskCreateSheet), findsNothing);
  });

  testWidgets('übergibt optionale Felder wie Beschreibung, Kontext und Energie-Level', (
    tester,
  ) async {
    repository.createResult = Ok(created);
    await pumpSheet(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Titel'), 'Wocheneinkauf');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Beschreibung (optional)'),
      'Liste vorher schreiben',
    );

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Kontext'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('privat').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Energie-Level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('niedrig').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Erfassen'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, hasLength(1));
    final call = repository.createCalls.single;
    expect(call.titel, equals('Wocheneinkauf'));
    expect(call.beschreibung, equals('Liste vorher schreiben'));
    expect(call.kontext, equals('privat'));
    expect(call.energieLevel, equals('niedrig'));
  });

  testWidgets('zeigt die Fehlermeldung bei einem Fehlschlag und lässt das Sheet offen', (
    tester,
  ) async {
    repository.createResult = const Err(ServerFailure('Aufgabe konnte nicht erfasst werden'));
    await pumpSheet(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Titel'), 'Neue Aufgabe');
    await tester.tap(find.widgetWithText(FilledButton, 'Erfassen'));
    await tester.pumpAndSettle();

    expect(find.text('Aufgabe konnte nicht erfasst werden'), findsOneWidget);
    expect(find.byType(TaskCreateSheet), findsOneWidget);
  });
}

class _CreateCall {
  _CreateCall({
    required this.titel,
    required this.beschreibung,
    required this.deadline,
    required this.kontext,
    required this.energieLevel,
  });

  final String titel;
  final String? beschreibung;
  final DateTime? deadline;
  final String? kontext;
  final String? energieLevel;
}

class _FakeTaskRepository implements TaskRepository {
  final List<_CreateCall> createCalls = [];
  Result<Task>? createResult;

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
  }) async {
    createCalls.add(
      _CreateCall(
        titel: titel,
        beschreibung: beschreibung,
        deadline: deadline,
        kontext: kontext,
        energieLevel: energieLevel,
      ),
    );
    return createResult ?? const Err(ServerFailure('kein createResult gesetzt'));
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
  Future<Result<Task>> update(String id, Map<String, Object?> changes) async =>
      const Err(ServerFailure('nicht implementiert'));

  @override
  Future<Result<void>> delete(String id) async =>
      const Err(ServerFailure('nicht implementiert'));
}
