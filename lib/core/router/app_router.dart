import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/wiki/presentation/wiki_screen.dart';
import 'app_shell.dart';

/// Zentrale Router-Konfiguration. Jedes Modul lebt in einem eigenen
/// Branch des `StatefulShellRoute` — `AppShell` stellt Menü und
/// Kontext-Schalter bereit (siehe M0-Deliverable).
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _branch('/', const DashboardScreen()),
          _branch('/tasks', const TasksScreen()),
          _branch('/projects', const ProjectsScreen()),
          _branch('/events', const EventsScreen()),
          _branch('/contacts', const ContactsScreen()),
          _branch('/reminders', const RemindersScreen()),
          _branch('/finance', const FinanceScreen()),
          _branch('/wiki', const WikiScreen()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen)],
  );
}
