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
/// Verknüpfungen bleiben hier bewusst außen vor — eine eigene Oberfläche
/// dafür entsteht mit der „Universellen Verlinkung" (M6), um Datenschicht
/// und UI nicht doppelt aufzubauen.
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
  final _neueTeilaufgabeController = TextEditingController();
  late DateTime? _deadline;
  late int? _prioritaet;
  late String _status;
  late String? _kontext;
  late String? _energieLevel;
  late bool _wiederkehrend;
  late String _wiederholungTyp;
  late int _wiederholungIntervall;
  late DateTime? _wiederholungBis;
  late List<_Teilaufgabe> _teilaufgaben;
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

    final wiederholung = task.wiederholung;
    _wiederkehrend = wiederholung != null;
    _wiederholungTyp = wiederholung?['typ'] as String? ?? taskWiederholungTypOptions.first;
    _wiederholungIntervall = wiederholung?['intervall'] as int? ?? 1;
    _wiederholungBis = _parseOptionalDate(wiederholung?['bis']);

    _teilaufgaben = _parseTeilaufgaben(task.teilaufgaben);
  }

  @override
  void dispose() {
    _titelController.dispose();
    _beschreibungController.dispose();
    _tagsController.dispose();
    _neueTeilaufgabeController.dispose();
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

  Future<void> _pickWiederholungBis() async {
    final initial = _wiederholungBis ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 10),
    );
    if (picked != null) setState(() => _wiederholungBis = picked);
  }

  void _addTeilaufgabe() {
    final titel = _neueTeilaufgabeController.text.trim();
    if (titel.isEmpty) return;
    setState(() {
      _teilaufgaben.add(_Teilaufgabe(titel: titel));
      _neueTeilaufgabeController.clear();
    });
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
      'wiederholung': _wiederkehrend
          ? {
              'typ': _wiederholungTyp,
              'intervall': _wiederholungIntervall,
              if (_wiederholungBis != null) 'bis': _wiederholungBis!.toIso8601String(),
            }
          : null,
      'teilaufgaben': _teilaufgaben.isEmpty
          ? null
          : [for (final teilaufgabe in _teilaufgaben) teilaufgabe.toJson()],
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
            Text('Wiederholung', style: Theme.of(context).textTheme.titleMedium),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wiederkehrend'),
              value: _wiederkehrend,
              onChanged: (value) => setState(() => _wiederkehrend = value),
            ),
            if (_wiederkehrend) ...[
              DropdownButtonFormField<String>(
                initialValue: _wiederholungTyp,
                decoration: const InputDecoration(labelText: 'Rhythmus'),
                items: [
                  for (final typ in taskWiederholungTypOptions)
                    DropdownMenuItem(value: typ, child: Text(taskWiederholungTypLabels[typ]!)),
                ],
                onChanged: (value) => setState(() => _wiederholungTyp = value!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Intervall'),
                subtitle: Text('Alle $_wiederholungIntervall Einheiten'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Intervall verkleinern',
                      onPressed: _wiederholungIntervall > 1
                          ? () => setState(() => _wiederholungIntervall--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Intervall vergrößern',
                      onPressed: () => setState(() => _wiederholungIntervall++),
                    ),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Endet am'),
                subtitle: Text(
                  _wiederholungBis == null ? 'Kein Enddatum' : formatTaskDate(_wiederholungBis!),
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_outlined),
                      tooltip: 'Enddatum wählen',
                      onPressed: _pickWiederholungBis,
                    ),
                    if (_wiederholungBis != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Enddatum entfernen',
                        onPressed: () => setState(() => _wiederholungBis = null),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Teilaufgaben', style: Theme.of(context).textTheme.titleMedium),
            for (var index = 0; index < _teilaufgaben.length; index++)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(_teilaufgaben[index].titel),
                value: _teilaufgaben[index].erledigt,
                onChanged: (checked) =>
                    setState(() => _teilaufgaben[index].erledigt = checked ?? false),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Teilaufgabe entfernen',
                  onPressed: () => setState(() => _teilaufgaben.removeAt(index)),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _neueTeilaufgabeController,
                    decoration: const InputDecoration(labelText: 'Neue Teilaufgabe'),
                    onFieldSubmitted: (_) => _addTeilaufgabe(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Teilaufgabe hinzufügen',
                  onPressed: _addTeilaufgabe,
                ),
              ],
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

DateTime? _parseOptionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<_Teilaufgabe> _parseTeilaufgaben(Object? raw) {
  if (raw is! List) return [];
  return [
    for (final entry in raw)
      if (entry is Map)
        _Teilaufgabe(
          titel: (entry['titel'] as String?) ?? '',
          erledigt: entry['erledigt'] == true,
        ),
  ];
}

/// Ein Eintrag der Teilaufgaben-Checkliste — entspricht dem rohen
/// `{titel, erledigt}`-JSON, das das Backend unter `teilaufgaben` speichert.
class _Teilaufgabe {
  _Teilaufgabe({required this.titel, this.erledigt = false});

  String titel;
  bool erledigt;

  Map<String, Object?> toJson() => {'titel': titel, 'erledigt': erledigt};
}
