import 'package:postgres/postgres.dart';

/// Eine Aufgabe (GTD-Kern). `kontext` ist absichtlich nullable — Quick-Capture
/// legt Tasks ohne Kontext in die Inbox, die GTD-Triage ordnet sie später ein.
class Task {
  /// Erstellt eine Aufgabe aus ihren Einzelfeldern.
  const Task({
    required this.id,
    required this.titel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.beschreibung,
    this.deadline,
    this.prioritaet,
    this.projektId,
    this.kontext,
    this.wiederholung,
    this.energieLevel,
    this.tags,
    this.teilaufgaben,
  });

  /// Baut eine Aufgabe aus einer Datenbankzeile. Erwartet die Spalten in
  /// der Reihenfolge `id, titel, beschreibung, deadline, prioritaet,
  /// status, projekt_id, kontext, wiederholung, energie_level, tags,
  /// teilaufgaben, created_at, updated_at` (siehe `TaskRepository`).
  factory Task.fromRow(ResultRow row) => Task(
    id: row[0]! as String,
    titel: row[1]! as String,
    beschreibung: row[2] as String?,
    deadline: row[3] as DateTime?,
    prioritaet: row[4] as int?,
    status: row[5]! as String,
    projektId: row[6] as String?,
    kontext: row[7] as String?,
    wiederholung: row[8],
    energieLevel: row[9] as String?,
    tags: (row[10] as List?)?.cast<String>(),
    teilaufgaben: row[11],
    createdAt: row[12]! as DateTime,
    updatedAt: row[13]! as DateTime,
  );

  /// Eindeutige ID (UUID).
  final String id;

  /// Titel der Aufgabe.
  final String titel;

  /// Optionale Langbeschreibung.
  final String? beschreibung;

  /// Fälligkeitszeitpunkt, falls gesetzt.
  final DateTime? deadline;

  /// Priorität: 1 = niedrig … 4 = kritisch.
  final int? prioritaet;

  /// Status: `inbox` | `aktiv` | `erledigt` | `archiviert`.
  final String status;

  /// Verknüpftes Projekt, falls vorhanden.
  final String? projektId;

  /// Kontext: `privat` | `arbeit` | `beides` — `null` bei Inbox-Einträgen
  /// aus Quick-Capture, bis die GTD-Triage ihn zuweist.
  final String? kontext;

  /// Wiederholungsregel als JSON (`{typ, intervall, bis}`), falls gesetzt.
  final Object? wiederholung;

  /// Energie-Level: `hoch` | `niedrig`.
  final String? energieLevel;

  /// Freie Schlagworte.
  final List<String>? tags;

  /// Checkliste mit Teilaufgaben als JSON.
  final Object? teilaufgaben;

  /// Erstellungszeitpunkt.
  final DateTime createdAt;

  /// Zeitpunkt der letzten Änderung.
  final DateTime updatedAt;

  /// JSON-Repräsentation für API-Antworten (camelCase-Schlüssel).
  Map<String, Object?> toJson() => {
    'id': id,
    'titel': titel,
    'beschreibung': beschreibung,
    'deadline': deadline?.toIso8601String(),
    'prioritaet': prioritaet,
    'status': status,
    'projektId': projektId,
    'kontext': kontext,
    'wiederholung': wiederholung,
    'energieLevel': energieLevel,
    'tags': tags,
    'teilaufgaben': teilaufgaben,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
