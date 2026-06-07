import 'package:backend/src/links/link.dart';
import 'package:postgres/postgres.dart';

/// Datenzugriff für universelle Verknüpfungen — kapselt SQL und
/// Zeilen-Mapping, damit die `/links`-Routen sich auf HTTP konzentrieren.
class LinkRepository {
  /// Erstellt das Repository auf einer bestehenden Datenbankverbindung.
  const LinkRepository(this._connection);

  final Connection _connection;

  static const _columns =
      'id, von_typ, von_id, zu_typ, zu_id, beziehung, created_at';

  /// Listet alle Verknüpfungen einer Entität — unabhängig davon, ob sie als
  /// Quelle (`von`) oder Ziel (`zu`) auftritt — neueste zuerst.
  Future<List<Link>> listForObject(String typ, String id) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT $_columns FROM links
        WHERE (von_typ = @typ AND von_id = @id)
           OR (zu_typ = @typ AND zu_id = @id)
        ORDER BY created_at DESC
      '''),
      parameters: {'typ': typ, 'id': id},
    );
    return result.map(Link.fromRow).toList();
  }

  /// Erstellt eine neue Verknüpfung zwischen zwei Entitäten.
  Future<Link> create({
    required String vonTyp,
    required String vonId,
    required String zuTyp,
    required String zuId,
    String? beziehung,
  }) async {
    final result = await _connection.execute(
      Sql.named('''
        INSERT INTO links (von_typ, von_id, zu_typ, zu_id, beziehung)
        VALUES (@vonTyp, @vonId, @zuTyp, @zuId, @beziehung)
        RETURNING $_columns
      '''),
      parameters: {
        'vonTyp': vonTyp,
        'vonId': vonId,
        'zuTyp': zuTyp,
        'zuId': zuId,
        'beziehung': beziehung,
      },
    );
    return Link.fromRow(result.first);
  }

  /// Löscht eine Verknüpfung. Liefert `true`, wenn eine Zeile betroffen war.
  Future<bool> delete(String id) async {
    final result = await _connection.execute(
      Sql.named('DELETE FROM links WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }
}
