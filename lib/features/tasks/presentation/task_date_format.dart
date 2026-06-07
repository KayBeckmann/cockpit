/// Formatiert ein Datum für die Aufgaben-Oberflächen als `TT.MM.JJJJ`
/// in lokaler Zeitzone — geteilt zwischen Liste, Detailansicht und
/// Erfassungs-Sheet, damit Deadlines überall gleich dargestellt werden.
String formatTaskDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}
