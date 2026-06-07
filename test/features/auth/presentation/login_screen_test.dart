import 'dart:async';

import 'package:cockpit/core/auth/auth_provider.dart';
import 'package:cockpit/core/auth/auth_repository.dart';
import 'package:cockpit/core/errors/failures.dart';
import 'package:cockpit/core/errors/result.dart';
import 'package:cockpit/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAuthRepository repository;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _FakeAuthRepository();
  });

  testWidgets('zeigt Validierungsfehler bei leerem Formular', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pumpAndSettle();

    expect(find.text('Bitte E-Mail eingeben'), findsOneWidget);
    expect(find.text('Bitte Passwort eingeben'), findsOneWidget);
    expect(repository.loginCalls, isEmpty);
  });

  testWidgets('meldet mit eingegebenen Daten an', (tester) async {
    repository.loginHandler = (_, _) async => const Ok('mein-jwt');
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'kay@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      'geheim',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pumpAndSettle();

    expect(repository.loginCalls, equals([('kay@example.com', 'geheim')]));
  });

  testWidgets('zeigt einen Ladeindikator während des Logins', (tester) async {
    final completer = Completer<Result<String>>();
    repository.loginHandler = (_, _) => completer.future;
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'kay@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      'geheim',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Anmelden'), findsNothing);

    completer.complete(const Ok('mein-jwt'));
    await tester.pumpAndSettle();
  });

  testWidgets('zeigt die Fehlermeldung der letzten fehlgeschlagenen Anmeldung', (
    tester,
  ) async {
    repository.loginHandler =
        (_, _) async => const Err(ServerFailure('Ungültige Zugangsdaten'));
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'kay@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      'falsch',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pumpAndSettle();

    expect(find.text('Ungültige Zugangsdaten'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final List<(String, String)> loginCalls = [];
  Future<Result<String>> Function(String email, String password)? loginHandler;
  String? token;
  bool loggedOut = false;

  @override
  Future<Result<String>> login(String email, String password) {
    loginCalls.add((email, password));
    return loginHandler?.call(email, password) ??
        Future.value(const Err(ServerFailure('kein loginHandler gesetzt')));
  }

  @override
  Future<String?> loadToken() async => token;

  @override
  Future<void> logout() async {
    loggedOut = true;
    token = null;
  }
}
