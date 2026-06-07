import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/tasks/data/task_model.dart';
import 'package:cockpit/features/tasks/data/task_repository.dart';
import 'package:cockpit/features/tasks/presentation/task_date_format.dart';
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

  final wiederholungBis = DateTime.parse('2026-12-31T12:00:00.000Z');
  final taskMitWiederholungUndTeilaufgaben = Task(
    id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
    titel: 'Wöchentliches Update schreiben',
    status: 'aktiv',
    wiederholung: {
      'typ': 'woechentlich',
      'intervall': 2,
      'bis': wiederholungBis.toIso8601String(),
    },
    teilaufgaben: const [
      {'titel': 'Entwurf schreiben', 'erledigt': true},
      {'titel': 'Review einholen', 'erledigt': false},
    ],
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 1),
  );

  Future<void> pumpScreen(WidgetTester tester, {Task? taskOverride}) async {
    // Großes Surface, damit das gesamte Formular (inkl. Wiederholung,
    // Teilaufgaben und Speichern-Button am Ende der ListView) ohne Scrollen
    // aufgebaut wird — sonst erstellt die Sliver-Liste die unteren Felder
    // gar nicht erst.
    tester.view.physicalSize = const Size(800, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: TaskDetailScreen(task: taskOverride ?? task)),
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

  testWidgets('zeigt Wiederholung und Teilaufgaben einer Aufgabe vorausgefüllt an', (tester) async {
    await pumpScreen(tester, taskOverride: taskMitWiederholungUndTeilaufgaben);

    final wiederkehrendSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Wiederkehrend'),
    );
    expect(wiederkehrendSwitch.value, isTrue);
    expect(find.text('Wöchentlich'), findsOneWidget);
    expect(find.text('Alle 2 Einheiten'), findsOneWidget);
    expect(find.text(formatTaskDate(wiederholungBis)), findsOneWidget);

    final entwurf = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Entwurf schreiben'),
    );
    expect(entwurf.value, isTrue);
    final review = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Review einholen'),
    );
    expect(review.value, isFalse);
  });

  testWidgets('aktiviert eine Wiederholungsregel und speichert sie', (tester) async {
    repository.updateResult = Ok(task);
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Wiederkehrend'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Rhythmus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monatlich').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Intervall vergrößern'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    final (_, changes) = repository.updateCalls.single;
    expect(changes['wiederholung'], equals({'typ': 'monatlich', 'intervall': 2}));
  });

  testWidgets('deaktiviert eine bestehende Wiederholungsregel beim Speichern', (tester) async {
    repository.updateResult = Ok(taskMitWiederholungUndTeilaufgaben);
    await pumpScreen(tester, taskOverride: taskMitWiederholungUndTeilaufgaben);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Wiederkehrend'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    final (_, changes) = repository.updateCalls.single;
    expect(changes['wiederholung'], isNull);
  });

  testWidgets('verwaltet die Teilaufgaben-Checkliste: abhaken, entfernen, hinzufügen', (
    tester,
  ) async {
    repository.updateResult = Ok(taskMitWiederholungUndTeilaufgaben);
    await pumpScreen(tester, taskOverride: taskMitWiederholungUndTeilaufgaben);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Review einholen'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, 'Entwurf schreiben'),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Neue Teilaufgabe'), 'Veröffentlichen');
    await tester.tap(find.byTooltip('Teilaufgabe hinzufügen'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    final (_, changes) = repository.updateCalls.single;
    expect(
      changes['teilaufgaben'],
      equals([
        {'titel': 'Review einholen', 'erledigt': true},
        {'titel': 'Veröffentlichen', 'erledigt': false},
      ]),
    );
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
