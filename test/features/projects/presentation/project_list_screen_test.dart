import 'dart:async';

import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/projects/data/project_model.dart';
import 'package:cockpit/features/projects/data/project_repository.dart';
import 'package:cockpit/features/projects/presentation/project_list_provider.dart';
import 'package:cockpit/features/projects/presentation/project_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeProjectRepository repository;

  Project buildProject({
    required String id,
    required String titel,
    String status = 'aktiv',
    int fortschritt = 0,
  }) {
    final timestamp = DateTime.utc(2026, 6, 1);
    return Project(
      id: id,
      titel: titel,
      status: status,
      fortschritt: fortschritt,
      kontext: 'privat',
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ProjectListScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _FakeProjectRepository();
  });

  testWidgets('zeigt einen Ladeindikator, während die Liste lädt', (tester) async {
    final completer = Completer<Result<List<Project>>>();
    repository.listHandler = (_, _) => completer.future;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ProjectListScreen())),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const Ok([]));
    await tester.pumpAndSettle();
  });

  testWidgets('ordnet Projekte ihrer Status-Spalte zu und zeigt den Fortschritt', (tester) async {
    repository.listResult = Ok([
      buildProject(id: '1', titel: 'Gartenhaus bauen', fortschritt: 30),
      buildProject(id: '2', titel: 'Steuererklärung', status: 'pausiert', fortschritt: 10),
      buildProject(id: '3', titel: 'Altprojekt', status: 'archiviert', fortschritt: 100),
    ]);

    await pumpScreen(tester);

    expect(find.text('Aktiv (1)'), findsOneWidget);
    expect(find.text('Pausiert (1)'), findsOneWidget);
    expect(find.text('Archiviert (1)'), findsOneWidget);

    expect(find.text('Gartenhaus bauen'), findsOneWidget);
    expect(find.text('30 % erledigt'), findsOneWidget);
    expect(find.text('Steuererklärung'), findsOneWidget);
    expect(find.text('Altprojekt'), findsOneWidget);
  });

  testWidgets('zeigt einen Hinweis in leeren Spalten', (tester) async {
    repository.listResult = Ok([buildProject(id: '1', titel: 'Gartenhaus bauen')]);

    await pumpScreen(tester);

    expect(find.text('Aktiv (1)'), findsOneWidget);
    expect(find.text('Pausiert (0)'), findsOneWidget);
    expect(find.text('Archiviert (0)'), findsOneWidget);
    expect(find.text('Keine Projekte'), findsNWidgets(2));
  });

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

class _FakeProjectRepository implements ProjectRepository {
  Result<List<Project>>? listResult;
  Future<Result<List<Project>>> Function(String? kontext, String? status)? listHandler;
  int listCallCount = 0;

  @override
  Future<Result<List<Project>>> list({String? kontext, String? status}) {
    listCallCount++;
    if (listHandler != null) return listHandler!(kontext, status);
    return Future.value(listResult ?? const Err(ServerFailure('kein listResult gesetzt')));
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
