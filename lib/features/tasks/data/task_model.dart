/// Eine Aufgabe (GTD-Kern). Spiegelt die JSON-Repräsentation des Backends
/// (camelCase-Schlüssel, siehe `Task.toJson` im Backend). `wiederholung`
/// und `teilaufgaben` bleiben als Roh-JSON erhalten — eigene Modelle dafür
/// entstehen mit den entsprechenden Roadmap-Punkten (Wiederholung,
/// Teilaufgaben).
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

  /// Baut eine Aufgabe aus der vom Backend gelieferten JSON-Repräsentation.
  factory Task.fromJson(Map<String, Object?> json) => Task(
    id: json['id']! as String,
    titel: json['titel']! as String,
    beschreibung: json['beschreibung'] as String?,
    deadline: _parseDateTime(json['deadline']),
    prioritaet: json['prioritaet'] as int?,
    status: json['status']! as String,
    projektId: json['projektId'] as String?,
    kontext: json['kontext'] as String?,
    wiederholung: (json['wiederholung'] as Map?)?.cast<String, Object?>(),
    energieLevel: json['energieLevel'] as String?,
    tags: (json['tags'] as List?)?.cast<String>(),
    teilaufgaben: json['teilaufgaben'],
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
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

  /// Wiederholungsregel als Roh-JSON (`{typ, intervall, bis}`), falls gesetzt.
  final Map<String, Object?>? wiederholung;

  /// Energie-Level: `hoch` | `niedrig`.
  final String? energieLevel;

  /// Freie Schlagworte.
  final List<String>? tags;

  /// Checkliste mit Teilaufgaben als Roh-JSON.
  final Object? teilaufgaben;

  /// Erstellungszeitpunkt.
  final DateTime createdAt;

  /// Zeitpunkt der letzten Änderung.
  final DateTime updatedAt;
}

DateTime? _parseDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
