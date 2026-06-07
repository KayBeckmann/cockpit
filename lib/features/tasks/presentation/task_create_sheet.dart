import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import 'task_date_format.dart';
import 'task_field_options.dart';
import 'task_list_provider.dart';

/// Bottom Sheet zum schnellen Erfassen einer neuen Aufgabe (GTD-Capture).
///
/// Bewusst auf die wichtigsten Felder reduziert — Priorität, Status, Tags
/// und Co. lassen sich anschließend über [TaskDetailScreen] ergänzen.
/// Ohne Status-Angabe legt das Backend die Aufgabe als `inbox`-Eintrag an.
class TaskCreateSheet extends ConsumerStatefulWidget {
  const TaskCreateSheet({super.key});

  /// Öffnet das Sheet als modales Bottom Sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TaskCreateSheet(),
    );
  }

  @override
  ConsumerState<TaskCreateSheet> createState() => _TaskCreateSheetState();
}

class _TaskCreateSheetState extends ConsumerState<TaskCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titelController = TextEditingController();
  final _beschreibungController = TextEditingController();
  DateTime? _deadline;
  String? _kontext;
  String? _energieLevel;
  bool _isSaving = false;

  @override
  void dispose() {
    _titelController.dispose();
    _beschreibungController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final beschreibung = _beschreibungController.text.trim();

    final result = await ref
        .read(taskRepositoryProvider)
        .create(
          titel: _titelController.text.trim(),
          beschreibung: beschreibung.isEmpty ? null : beschreibung,
          deadline: _deadline,
          kontext: _kontext,
          energieLevel: _energieLevel,
        );

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
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Neue Aufgabe', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titelController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Titel'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Bitte einen Titel eingeben'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beschreibungController,
              decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fällig am'),
              subtitle: Text(_deadline == null ? 'Keine Deadline' : formatTaskDate(_deadline!)),
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Erfassen'),
            ),
          ],
        ),
      ),
    );
  }
}
