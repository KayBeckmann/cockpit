import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/tasks/data/task_model.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/wiki/presentation/wiki_screen.dart';
import '../auth/auth_provider.dart';
import 'app_shell.dart';

/// Zentrale Router-Konfiguration. Jedes Modul lebt in einem eigenen
/// Branch des `StatefulShellRoute` — `AppShell` stellt Menü und
/// Kontext-Schalter bereit (siehe M0-Deliverable).
///
/// Solange [authProvider] keinen eingeloggten Benutzer liefert, leitet
/// `redirect` auf `/login` um; danach zurück auf die Startseite. Der
/// Provider beobachtet [authProvider], damit der Router bei Login/Logout
/// neu aufgebaut und die Umleitung neu ausgewertet wird.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = authState.value ?? false;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final loggingIn = state.matchedLocation == '/login';
      if (!isAuthenticated) return loggingIn ? null : '/login';
      if (loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _branch('/', const DashboardScreen()),
          _branch(
            '/tasks',
            const TaskListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    TaskDetailScreen(task: state.extra! as Task),
              ),
            ],
          ),
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

StatefulShellBranch _branch(
  String path,
  Widget screen, {
  List<RouteBase> routes = const [],
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(path: path, builder: (context, state) => screen, routes: routes),
    ],
  );
}
