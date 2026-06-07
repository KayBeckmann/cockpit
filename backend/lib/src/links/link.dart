import 'package:postgres/postgres.dart';

/// Eine universelle Verknüpfung zwischen zwei beliebigen Entitäten (z. B.
/// Task ↔ Projekt, Kontakt ↔ Termin) — der Schlüssel zum vernetzten System.
class Link {
  /// Erstellt eine Verknüpfung aus ihren Einzelfeldern.
  const Link({
    required this.id,
    required this.vonTyp,
    required this.vonId,
    required this.zuTyp,
    required this.zuId,
    required this.createdAt,
    this.beziehung,
  });

  /// Baut eine Verknüpfung aus einer Datenbankzeile. Erwartet die Spalten in
  /// der Reihenfolge `id, von_typ, von_id, zu_typ, zu_id, beziehung,
  /// created_at` (siehe `LinkRepository`).
  factory Link.fromRow(ResultRow row) => Link(
    id: row[0]! as String,
    vonTyp: row[1]! as String,
    vonId: row[2]! as String,
    zuTyp: row[3]! as String,
    zuId: row[4]! as String,
    beziehung: row[5] as String?,
    createdAt: row[6]! as DateTime,
  );

  /// Eindeutige ID der Verknüpfung.
  final String id;

  /// Typ der Quell-Entität, z. B. `task`, `event`, `contact`, `project`.
  final String vonTyp;

  /// ID der Quell-Entität.
  final String vonId;

  /// Typ der Ziel-Entität.
  final String zuTyp;

  /// ID der Ziel-Entität.
  final String zuId;

  /// Optionale Beschreibung der Beziehung, z. B. `gehört zu`, `blockiert`.
  final String? beziehung;

  /// Zeitpunkt der Erstellung.
  final DateTime createdAt;

  /// JSON-Repräsentation für API-Antworten (camelCase-Schlüssel).
  Map<String, Object?> toJson() => {
    'id': id,
    'vonTyp': vonTyp,
    'vonId': vonId,
    'zuTyp': zuTyp,
    'zuId': zuId,
    'beziehung': beziehung,
    'createdAt': createdAt.toIso8601String(),
  };
}
