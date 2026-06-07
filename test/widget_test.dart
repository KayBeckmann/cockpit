import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cockpit/core/context/app_context.dart';
import 'package:cockpit/main.dart';

void main() {
  testWidgets('App startet auf dem Dashboard mit Menü und Kontext-Schalter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CockpitApp()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Willkommen bei Cockpit'), findsOneWidget);
    expect(find.byType(SegmentedButton<AppContext>), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(NavigationDrawerDestination, 'Aufgaben'), findsOneWidget);
    expect(find.widgetWithText(NavigationDrawerDestination, 'Finanzen'), findsOneWidget);
  });
}
