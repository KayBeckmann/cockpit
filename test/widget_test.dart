import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cockpit/core/auth/auth_provider.dart';
import 'package:cockpit/core/context/app_context.dart';
import 'package:cockpit/main.dart';

void main() {
  testWidgets('App startet auf dem Dashboard mit Menü und Kontext-Schalter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        // Login-Redirect umgehen: Diese Smoke-Test prüft das Shell-Skeleton,
        // nicht den Auth-Flow (siehe login_screen_test.dart) — ohne diesen
        // Override hängt der Test an einem MissingPluginException aus
        // flutter_secure_storage, das im Test keinen Platform-Channel hat.
        overrides: [authProvider.overrideWith(() => _LoggedInAuthNotifier())],
        child: const CockpitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Willkommen bei Cockpit'), findsOneWidget);
    expect(find.byType(SegmentedButton<AppContext>), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(NavigationDrawerDestination, 'Aufgaben'), findsOneWidget);
    expect(find.widgetWithText(NavigationDrawerDestination, 'Finanzen'), findsOneWidget);
  });
}

class _LoggedInAuthNotifier extends AuthNotifier {
  @override
  Future<bool> build() async => true;
}
