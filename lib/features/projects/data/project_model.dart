/// Ein Projekt (Hobby- oder Arbeitsvorhaben). Spiegelt die JSON-Repräsentation
/// des Backends (camelCase-Schlüssel, siehe `Project.toJson` im Backend).
/// `meilensteine` und `ressourcen` bleiben als Roh-JSON erhalten — eigene
/// Modelle dafür entstehen mit den entsprechenden Roadmap-Punkten (M5).
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

  /// Baut ein Projekt aus der vom Backend gelieferten JSON-Repräsentation.
  factory Project.fromJson(Map<String, Object?> json) => Project(
    id: json['id']! as String,
    titel: json['titel']! as String,
    typ: json['typ'] as String?,
    status: json['status']! as String,
    fortschritt: json['fortschritt']! as int,
    meilensteine: json['meilensteine'],
    ressourcen: json['ressourcen'],
    kontext: json['kontext']! as String,
    obsidianUri: json['obsidianUri'] as String?,
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
  );

  /// Eindeutige ID (UUID).
  final String id;

  /// Titel des Projekts.
  final String titel;

  /// Optionale Kategorisierung, z. B. `hobby` oder `arbeit`.
  final String? typ;

  /// Status: `aktiv` | `pausiert` | `archiviert` — bestimmt die
  /// Kanban-Spalte in der Projektübersicht.
  final String status;

  /// Fortschritt in Prozent (0–100), serverseitig gepflegt.
  final int fortschritt;

  /// Meilensteine als Roh-JSON, falls gesetzt.
  final Object? meilensteine;

  /// Ressourcen/Stücklisten als Roh-JSON, falls gesetzt.
  final Object? ressourcen;

  /// Kontext: `privat` | `arbeit` | `beides`.
  final String kontext;

  /// Optionale URI zur zugehörigen Obsidian-Notiz.
  final String? obsidianUri;

  /// Erstellungszeitpunkt.
  final DateTime createdAt;

  /// Zeitpunkt der letzten Änderung.
  final DateTime updatedAt;
}
