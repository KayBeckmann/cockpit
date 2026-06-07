import 'package:postgres/postgres.dart';

/// Ein Projekt (Hobby- oder Arbeitsvorhaben mit Aufgaben, Meilensteinen und
/// Ressourcen).
class Project {
  /// Erstellt ein Projekt aus seinen Einzelfeldern.
  const Project({
    required this.id,
    required this.titel,
    required this.status,
    required this.fortschritt,
    required this.kontext,
    required this.createdAt,
    required this.updatedAt,
    this.typ,
    this.meilensteine,
    this.ressourcen,
    this.obsidianUri,
  });

  /// Baut ein Projekt aus einer Datenbankzeile. Erwartet die Spalten in der
  /// Reihenfolge `id, titel, typ, status, fortschritt, meilensteine,
  /// ressourcen, kontext, obsidian_uri, created_at, updated_at` (siehe
  /// `ProjectRepository`).
  factory Project.fromRow(ResultRow row) => Project(
    id: row[0]! as String,
    titel: row[1]! as String,
    typ: row[2] as String?,
    status: row[3]! as String,
    fortschritt: row[4]! as int,
    meilensteine: row[5],
    ressourcen: row[6],
    kontext: row[7]! as String,
    obsidianUri: row[8] as String?,
    createdAt: row[9]! as DateTime,
    updatedAt: row[10]! as DateTime,
  );

  /// Eindeutige ID des Projekts.
  final String id;

  /// Titel des Projekts.
  final String titel;

  /// Optionale Kategorisierung, z. B. `hobby` oder `arbeit`.
  final String? typ;

  /// Status, z. B. `aktiv`, `pausiert` oder `archiviert`.
  final String status;

  /// Fortschritt in Prozent (0–100).
  final int fortschritt;

  /// Meilensteine als JSON-Liste.
  final Object? meilensteine;

  /// Ressourcen/Stücklisten als JSON-Struktur.
  final Object? ressourcen;

  /// Kontext (`privat`, `arbeit`, …) — steuert den globalen App-Filter.
  final String kontext;

  /// Optionale URI zur zugehörigen Obsidian-Notiz.
  final String? obsidianUri;

  /// Zeitpunkt der Erstellung.
  final DateTime createdAt;

  /// Zeitpunkt der letzten Änderung.
  final DateTime updatedAt;

  /// JSON-Repräsentation für API-Antworten (camelCase-Schlüssel).
  Map<String, Object?> toJson() => {
    'id': id,
    'titel': titel,
    'typ': typ,
    'status': status,
    'fortschritt': fortschritt,
    'meilensteine': meilensteine,
    'ressourcen': ressourcen,
    'kontext': kontext,
    'obsidianUri': obsidianUri,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
