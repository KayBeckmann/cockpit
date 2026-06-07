/// Kanban-Spalten der Projektübersicht in fester Reihenfolge — gespiegelt
/// vom Backend-Kommentar zu `Project.status` (`aktiv`, `pausiert`,
/// `archiviert`).
const List<String> projectKanbanStatuses = ['aktiv', 'pausiert', 'archiviert'];

const Map<String, String> projectStatusLabels = {
  'aktiv': 'Aktiv',
  'pausiert': 'Pausiert',
  'archiviert': 'Archiviert',
};
