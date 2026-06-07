import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cockpit/main.dart';
import 'package:cockpit/core/constants/app_constants.dart';

void main() {
  testWidgets('App startet auf dem Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CockpitApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text('Dashboard — folgt in M2'), findsOneWidget);
  });
}
