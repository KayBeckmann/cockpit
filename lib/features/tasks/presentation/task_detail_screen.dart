import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../data/task_model.dart';
import 'task_date_format.dart';
import 'task_field_options.dart';
import 'task_list_provider.dart';

/// Bearbeitet eine bestehende Aufgabe. Erhält die Aufgabe direkt von der
/// aufrufenden Liste (`extra` der Route) — ein zusätzlicher Ladevorgang
/// entfällt, weil [TaskListScreen] die Daten bereits hält.
///
/// Wiederholungsregeln und Teilaufgaben werden hier bewusst nicht
/// bearbeitet — eigene Oberflächen dafür entstehen mit Roadmap-Punkt
/// „Wiederkehrende Aufgaben + Teilaufgaben".
class TaskDetailScreen extends ConsumerStatefulWidget {
  /// Erstellt den Bearbeiten-Bildschirm für [task].
  const TaskDetailScreen({required this.task, super.key});

  /// Die zu bearbeitende Aufgabe (aktueller Stand aus der Liste).
  final Task task;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titelController;
  late final TextEditingController _beschreibungController;
  late final TextEditingController _tagsController;
  late DateTime? _deadline;
  late int? _prioritaet;
  late String _status;
  late String? _kontext;
  late String? _energieLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titelController = TextEditingController(text: task.titel);
    _beschreibungController = TextEditingController(text: task.beschreibung ?? '');
    _tagsController = TextEditingController(text: (task.tags ?? const []).join(', '));
    _deadline = task.deadline;
    _prioritaet = task.prioritaet;
    _status = task.status;
    _kontext = task.kontext;
    _energieLevel = task.energieLevel;
  }

  @override
  void dispose() {
    _titelController.dispose();
    _beschreibungController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final initial = _deadline ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 5),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final beschreibung = _beschreibungController.text.trim();

    final result = await ref.read(taskRepositoryProvider).update(widget.task.id, {
      'titel': _titelController.text.trim(),
      'beschreibung': beschreibung.isEmpty ? null : beschreibung,
      'deadline': _deadline?.toIso8601String(),
      'prioritaet': _prioritaet,
      'status': _status,
      'kontext': _kontext,
      'energieLevel': _energieLevel,
      'tags': tags,
    });

    if (!mounted) return;

    switch (result) {
      case Ok():
        await ref.read(taskListProvider.notifier).refresh();
        if (mounted) Navigator.of(context).pop();
      case Err(:final failure):
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aufgabe bearbeiten')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titelController,
              decoration: const InputDecoration(labelText: 'Titel'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Bitte einen Titel eingeben'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beschreibungController,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fällig am'),
              subtitle: Text(_deadline == null ? 'Keine Deadline gesetzt' : formatTaskDate(_deadline!)),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined),
                    tooltip: 'Datum wählen',
                    onPressed: _pickDeadline,
                  ),
                  if (_deadline != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Deadline entfernen',
                      onPressed: () => setState(() => _deadline = null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in taskStatusOptions)
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _prioritaet,
              decoration: const InputDecoration(labelText: 'Priorität'),
              items: [
                const DropdownMenuItem<int?>(child: Text('Keine')),
                for (final priority in taskPriorityOptions)
                  DropdownMenuItem(value: priority, child: Text(taskPriorityLabels[priority]!)),
              ],
              onChanged: (value) => setState(() => _prioritaet = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _kontext,
              decoration: const InputDecoration(labelText: 'Kontext'),
              items: [
                const DropdownMenuItem<String?>(child: Text('Kein Kontext (Inbox)')),
                for (final kontext in taskKontextOptions)
                  DropdownMenuItem(value: kontext, child: Text(kontext)),
              ],
              onChanged: (value) => setState(() => _kontext = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _energieLevel,
              decoration: const InputDecoration(labelText: 'Energie-Level'),
              items: [
                const DropdownMenuItem<String?>(child: Text('Kein Energie-Level')),
                for (final level in taskEnergyLevelOptions)
                  DropdownMenuItem(value: level, child: Text(level)),
              ],
              onChanged: (value) => setState(() => _energieLevel = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (mit Komma getrennt)',
                hintText: 'z. B. haushalt, dringend',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
