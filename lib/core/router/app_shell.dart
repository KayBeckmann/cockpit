import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../context/app_context.dart';
import '../context/context_switch_provider.dart';

/// Gemeinsamer Rahmen für alle Module: Navigationsmenü + globaler
/// Kontext-Schalter, sichtbar auf jedem Screen (M0-Deliverable).
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _Destination('Dashboard', Icons.dashboard_outlined, '/'),
    _Destination('Aufgaben', Icons.check_box_outlined, '/tasks'),
    _Destination('Projekte', Icons.view_kanban_outlined, '/projects'),
    _Destination('Kalender', Icons.calendar_month_outlined, '/events'),
    _Destination('Kontakte', Icons.people_outline, '/contacts'),
    _Destination('Erinnerungen', Icons.notifications_outlined, '/reminders'),
    _Destination('Finanzen', Icons.account_balance_outlined, '/finance'),
    _Destination('Wiki', Icons.menu_book_outlined, '/wiki'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appContext = ref.watch(contextSwitchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[navigationShell.currentIndex].label),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: SegmentedButton<AppContext>(
                segments: AppContext.values
                    .map(
                      (c) => ButtonSegment(value: c, label: Text(c.label)),
                    )
                    .toList(),
                selected: {appContext},
                onSelectionChanged: (selection) => ref
                    .read(contextSwitchProvider.notifier)
                    .setContext(selection.first),
              ),
            ),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        children: [
          for (final destination in _destinations)
            NavigationDrawerDestination(
              icon: Icon(destination.icon),
              label: Text(destination.label),
            ),
        ],
      ),
      body: navigationShell,
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
