import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../data/task_model.dart';
import 'task_create_sheet.dart';
import 'task_date_format.dart';
import 'task_list_provider.dart';

const _activeStatuses = {'inbox', 'aktiv'};

/// Aufgabenübersicht mit drei Ansichten — der globale Kontext-Filter wird
/// bereits serverseitig durch [taskListProvider] angewendet (siehe
/// [[Cockpit/Entscheidungen/ADR-0006_kontext_trennungslogik_bestaetigt|ADR-0006]]).
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => TaskCreateSheet.show(context),
        tooltip: 'Aufgabe erfassen',
        child: const Icon(Icons.add),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const Material(
              child: TabBar(
                tabs: [
                  Tab(text: 'Inbox'),
                  Tab(text: 'Heute'),
                  Tab(text: 'Alle'),
                ],
              ),
            ),
            Expanded(
              child: switch (tasks) {
                AsyncData(:final value) => TabBarView(
                  children: [
                    _TaskList(tasks: _inboxTasks(value), emptyHint: _inboxEmptyHint),
                    _TaskList(tasks: _todayTasks(value), emptyHint: _todayEmptyHint),
                    _TaskList(tasks: value, emptyHint: _allEmptyHint),
                  ],
                ),
                AsyncError(:final error) => _ErrorView(
                  message: error is Failure
                      ? error.message
                      : 'Aufgaben konnten nicht geladen werden.',
                  onRetry: () => ref.read(taskListProvider.notifier).refresh(),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

const _inboxEmptyHint = 'Inbox ist leer — neu erfasste Aufgaben landen hier zur Triage.';
const _todayEmptyHint = 'Für heute steht nichts an.';
const _allEmptyHint = 'Noch keine Aufgaben vorhanden.';

List<Task> _inboxTasks(List<Task> tasks) {
  final inbox = tasks.where((task) => task.status == 'inbox').toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return inbox;
}

List<Task> _todayTasks(List<Task> tasks) {
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final today =
      tasks.where((task) {
          final deadline = task.deadline;
          return deadline != null &&
              !deadline.isAfter(endOfToday) &&
              _activeStatuses.contains(task.status);
        }).toList()
        ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  return today;
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.emptyHint});

  final List<Task> tasks;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyHint, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _TaskTile(task: tasks[index]),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final deadline = task.deadline;

    return ListTile(
      leading: Icon(_statusIcon(task.status)),
      title: Text(task.titel),
      subtitle: deadline != null ? Text('Fällig: ${formatTaskDate(deadline)}') : null,
      trailing: task.energieLevel != null ? Chip(label: Text(task.energieLevel!)) : null,
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
