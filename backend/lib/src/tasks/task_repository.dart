import 'package:backend/src/tasks/task.dart';
import 'package:postgres/postgres.dart';

/// Datenzugriff für Tasks — kapselt SQL und Zeilen-Mapping, damit die
/// CRUD-Routes (`/tasks`, `/quick-capture`) sich auf HTTP konzentrieren.
class TaskRepository {
  /// Erstellt das Repository auf einer bestehenden Datenbankverbindung.
  const TaskRepository(this._connection);

  final Connection _connection;

  static const _columns =
      'id, titel, beschreibung, deadline, prioritaet, status, projekt_id, '
      'kontext, wiederholung, energie_level, tags, teilaufgaben, '
      'created_at, updated_at';

  /// Listet Aufgaben, optional gefiltert nach `kontext`, `status` und/oder
  /// `projekt_id` — neueste zuerst.
  Future<List<Task>> list({
    String? kontext,
    String? status,
    String? projektId,
  }) async {
    final conditions = <String>[];
    final parameters = <String, Object?>{};

    if (kontext != null) {
      conditions.add('kontext = @kontext');
      parameters['kontext'] = kontext;
    }
    if (status != null) {
      conditions.add('status = @status');
      parameters['status'] = status;
    }
    if (projektId != null) {
      conditions.add('projekt_id = @projektId');
      parameters['projektId'] = projektId;
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final result = await _connection.execute(
      Sql.named('SELECT $_columns FROM tasks $where ORDER BY created_at DESC'),
      parameters: parameters,
    );
    return result.map(Task.fromRow).toList();
  }

  /// Sucht eine Aufgabe per ID. Liefert `null`, wenn keine existiert.
  Future<Task?> find(String id) async {
    final result = await _connection.execute(
      Sql.named('SELECT $_columns FROM tasks WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.isEmpty ? null : Task.fromRow(result.first);
  }

  /// Legt eine neue Aufgabe an. `status` fällt mangels Angabe auf `inbox`
  /// zurück (Quick-Capture-Standard).
  Future<Task> create({
    required String titel,
    String? beschreibung,
    DateTime? deadline,
    int? prioritaet,
    String? status,
    String? projektId,
    String? kontext,
    Object? wiederholung,
    String? energieLevel,
    List<String>? tags,
  }) async {
    final result = await _connection.execute(
      Sql.named('''
        INSERT INTO tasks
          (titel, beschreibung, deadline, prioritaet, status, projekt_id,
           kontext, wiederholung, energie_level, tags)
        VALUES
          (@titel, @beschreibung, @deadline, @prioritaet,
           COALESCE(@status, 'inbox'), @projektId, @kontext, @wiederholung,
           @energieLevel, @tags)
        RETURNING $_columns
      '''),
      parameters: {
        'titel': titel,
        'beschreibung': beschreibung,
        'deadline': deadline,
        'prioritaet': prioritaet,
        'status': status,
        'projektId': projektId,
        'kontext': kontext,
        'wiederholung': wiederholung,
        'energieLevel': energieLevel,
        'tags': tags,
      },
    );
    return Task.fromRow(result.first);
  }

  /// Aktualisiert nur die im `changes`-Set enthaltenen Felder (PATCH-artiges
  /// `PUT`). Ein im Set enthaltener Wert `null` setzt die Spalte bewusst auf
  /// `NULL`; fehlende Schlüssel lassen die Spalte unverändert.
  Future<Task?> update(String id, Map<String, Object?> changes) async {
    if (changes.isEmpty) return find(id);

    const updatable = {
      'titel',
      'beschreibung',
      'deadline',
      'prioritaet',
      'status',
      'projekt_id',
      'kontext',
      'wiederholung',
      'energie_level',
      'tags',
    };

    final columns = changes.keys.where(updatable.contains).toList();
    if (columns.isEmpty) return find(id);

    final assignments = columns.map((column) => '$column = @$column').toList()
      ..add('updated_at = now()');
    final parameters = <String, Object?>{'id': id};
    for (final column in columns) {
      parameters[column] = changes[column];
    }

    final result = await _connection.execute(
      Sql.named('''
        UPDATE tasks SET ${assignments.join(', ')}
        WHERE id = @id
        RETURNING $_columns
      '''),
      parameters: parameters,
    );
    return result.isEmpty ? null : Task.fromRow(result.first);
  }

  /// Löscht eine Aufgabe. Liefert `true`, wenn eine Zeile betroffen war.
  Future<bool> delete(String id) async {
    final result = await _connection.execute(
      Sql.named('DELETE FROM tasks WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }
}
