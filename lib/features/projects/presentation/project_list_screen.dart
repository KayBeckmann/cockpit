import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../data/project_model.dart';
import 'project_field_options.dart';
import 'project_list_provider.dart';

/// Projektübersicht als Kanban-Board — eine Spalte je Status (Aktiv /
/// Pausiert / Archiviert), serverseitig bereits nach dem globalen
/// Kontext-Schalter gefiltert (siehe [projectListProvider]/ADR-0006).
///
/// Zwei verschachtelte [SingleChildScrollView]s (vertikal außen, horizontal
/// innen) statt `ListView` je Spalte: die Spalten sind reine [Column]s mit
/// fester Breite, die sich an ihren Inhalt anpassen — das vermeidet die
/// „unbounded height"-Probleme verschachtelter Scrollrichtungen und baut
/// alle Karten sofort auf (kein Lazy-Building wie bei Slivern).
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    return Scaffold(
      body: switch (projects) {
        AsyncData(:final value) => _KanbanBoard(projects: value),
        AsyncError(:final error) => _ErrorView(
          message: error is Failure
              ? error.message
              : 'Projekte konnten nicht geladen werden.',
          onRetry: () => ref.read(projectListProvider.notifier).refresh(),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final status in projectKanbanStatuses)
              _ProjectColumn(
                status: status,
                projects: projects.where((project) => project.status == status).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectColumn extends StatelessWidget {
  const _ProjectColumn({required this.status, required this.projects});

  final String status;
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${projectStatusLabels[status] ?? status} (${projects.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Keine Projekte',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final project in projects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProjectCard(project: project),
                ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(project.titel),
        subtitle: Text('${project.fortschritt} % erledigt'),
        onTap: () => context.push('/projects/${project.id}', extra: project),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}
