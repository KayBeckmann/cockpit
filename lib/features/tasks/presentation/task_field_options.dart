/// Geteilte Auswahllisten für Aufgaben-Formulare ([TaskDetailScreen],
/// [TaskCreateSheet]) — gespiegelt von der Validierung der `/tasks`-Routes
/// im Backend, damit beide Formulare dieselben Optionen anbieten.
const List<String> taskStatusOptions = ['inbox', 'aktiv', 'erledigt', 'archiviert'];

/// `null` steht für „kein Kontext" (z. B. frische Inbox-Einträge).
const List<String> taskKontextOptions = ['privat', 'arbeit', 'beides'];

const List<String> taskEnergyLevelOptions = ['hoch', 'niedrig'];

/// Priorität: 1 = niedrig … 4 = kritisch.
const List<int> taskPriorityOptions = [1, 2, 3, 4];

const Map<int, String> taskPriorityLabels = {
  1: '1 – Niedrig',
  2: '2 – Mittel',
  3: '3 – Hoch',
  4: '4 – Kritisch',
};

/// Gespiegelt von `Wiederholung.typen` im Backend (siehe `wiederholung.dart`).
const List<String> taskWiederholungTypOptions = [
  'taeglich',
  'woechentlich',
  'monatlich',
  'jaehrlich',
];

const Map<String, String> taskWiederholungTypLabels = {
  'taeglich': 'Täglich',
  'woechentlich': 'Wöchentlich',
  'monatlich': 'Monatlich',
  'jaehrlich': 'Jährlich',
};
