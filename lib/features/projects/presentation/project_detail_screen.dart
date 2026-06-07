import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../tasks/data/task_model.dart';
import '../../tasks/presentation/task_date_format.dart';
import '../data/project_model.dart';
import 'project_field_options.dart';
import 'project_list_provider.dart';

const _erledigtStatuses = {'erledigt', 'archiviert'};

/// Detailansicht eines Projekts: Stammdaten, ein aus den verknüpften
/// Aufgaben berechneter Fortschrittsbalken sowie deren Liste.
///
/// Erhält das Projekt direkt von der aufrufenden Liste (`extra` der Route)
/// — wie bei der Aufgaben-Detailansicht entfällt damit ein zusätzlicher
/// Ladevorgang. Die Aufgaben lädt [projectTasksProvider] serverseitig über
/// `projekt_id`.
class ProjectDetailScreen extends ConsumerWidget {
  /// Erstellt die Detailansicht für [project].
  const ProjectDetailScreen({required this.project, super.key});

  /// Das anzuzeigende Projekt (aktueller Stand aus der Liste).
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(projectTasksProvider(project.id));

    return Scaffold(
      appBar: AppBar(title: Text(project.titel)),
      body: switch (tasks) {
        AsyncData(:final value) => _ProjectDetailBody(project: project, tasks: value),
        AsyncError(:final error) => _ErrorView(
          message: error is Failure
              ? error.message
              : 'Aufgaben konnten nicht geladen werden.',
          onRetry: () => ref.refresh(projectTasksProvider(project.id)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ProjectDetailBody extends StatelessWidget {
  const _ProjectDetailBody({required this.project, required this.tasks});

  final Project project;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final erledigt = tasks.where((task) => _erledigtStatuses.contains(task.status)).length;
    final fortschritt = tasks.isEmpty ? 0.0 : erledigt / tasks.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(projectStatusLabels[project.status] ?? project.status)),
            if (project.typ != null) Chip(label: Text(project.typ!)),
            Chip(label: Text('Kontext: ${project.kontext}')),
          ],
        ),
        const SizedBox(height: 24),
        Text('Fortschritt', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: fortschritt, minHeight: 8),
        ),
        const SizedBox(height: 4),
        Text(
          tasks.isEmpty
              ? 'Noch keine Aufgaben verknüpft'
              : '${(fortschritt * 100).round()} % erledigt ($erledigt von ${tasks.length} Aufgaben)',
        ),
        const SizedBox(height: 24),
        Text('Aufgaben', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Text('Diesem Projekt sind noch keine Aufgaben zugeordnet.')
        else
          for (final task in tasks) _ProjectTaskTile(task: task),
      ],
    );
  }
}

class _ProjectTaskTile extends StatelessWidget {
  const _ProjectTaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final deadline = task.deadline;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_statusIcon(task.status)),
      title: Text(task.titel),
      subtitle: deadline != null ? Text('Fällig: ${formatTaskDate(deadline)}') : null,
      onTap: () => context.push('/tasks/${task.id}', extra: task),
    );
  }

  IconData _statusIcon(String status) => switch (status) {
    'inbox' => Icons.inbox_outlined,
    'aktiv' => Icons.radio_button_unchecked,
    'erledigt' => Icons.check_circle_outline,
    'archiviert' => Icons.archive_outlined,
    _ => Icons.circle_outlined,
  };
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
