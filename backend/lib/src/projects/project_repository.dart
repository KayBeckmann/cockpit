import 'package:backend/src/projects/project.dart';
import 'package:postgres/postgres.dart';

/// Datenzugriff für Projekte — kapselt SQL und Zeilen-Mapping, damit die
/// CRUD-Routes (`/projects`) sich auf HTTP konzentrieren.
class ProjectRepository {
  /// Erstellt das Repository auf einer bestehenden Datenbankverbindung.
  const ProjectRepository(this._connection);

  final Connection _connection;

  static const _columns =
      'id, titel, typ, status, fortschritt, meilensteine, ressourcen, '
      'kontext, obsidian_uri, created_at, updated_at';

  /// Listet Projekte, optional gefiltert nach `kontext` und/oder `status` —
  /// neueste zuerst.
  Future<List<Project>> list({String? kontext, String? status}) async {
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

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final result = await _connection.execute(
      Sql.named(
        'SELECT $_columns FROM projects $where ORDER BY created_at DESC',
      ),
      parameters: parameters,
    );
    return result.map(Project.fromRow).toList();
  }

  /// Sucht ein Projekt per ID. Liefert `null`, wenn keines existiert.
  Future<Project?> find(String id) async {
    final result = await _connection.execute(
      Sql.named('SELECT $_columns FROM projects WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.isEmpty ? null : Project.fromRow(result.first);
  }

  /// Legt ein neues Projekt an. `status` und `fortschritt` fallen mangels
  /// Angabe auf `aktiv` bzw. `0` zurück.
  Future<Project> create({
    required String titel,
    required String kontext,
    String? typ,
    String? status,
    int? fortschritt,
    Object? meilensteine,
    Object? ressourcen,
    String? obsidianUri,
  }) async {
    final result = await _connection.execute(
      Sql.named('''
        INSERT INTO projects
          (titel, typ, status, fortschritt, meilensteine, ressourcen,
           kontext, obsidian_uri)
        VALUES
          (@titel, @typ, COALESCE(@status, 'aktiv'),
           COALESCE(@fortschritt, 0), @meilensteine, @ressourcen, @kontext,
           @obsidianUri)
        RETURNING $_columns
      '''),
      parameters: {
        'titel': titel,
        'typ': typ,
        'status': status,
        'fortschritt': fortschritt,
        'meilensteine': meilensteine,
        'ressourcen': ressourcen,
        'kontext': kontext,
        'obsidianUri': obsidianUri,
      },
    );
    return Project.fromRow(result.first);
  }

  /// Aktualisiert nur die im `changes`-Set enthaltenen Felder (PATCH-artiges
  /// `PUT`). Ein im Set enthaltener Wert `null` setzt die Spalte bewusst auf
  /// `NULL`; fehlende Schlüssel lassen die Spalte unverändert.
  Future<Project?> update(String id, Map<String, Object?> changes) async {
    if (changes.isEmpty) return find(id);

    const updatable = {
      'titel',
      'typ',
      'status',
      'fortschritt',
      'meilensteine',
      'ressourcen',
      'kontext',
      'obsidian_uri',
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
        UPDATE projects SET ${assignments.join(', ')}
        WHERE id = @id
        RETURNING $_columns
      '''),
      parameters: parameters,
    );
    return result.isEmpty ? null : Project.fromRow(result.first);
  }

  /// Löscht ein Projekt. Liefert `true`, wenn eine Zeile betroffen war.
  Future<bool> delete(String id) async {
    final result = await _connection.execute(
      Sql.named('DELETE FROM projects WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }
}
