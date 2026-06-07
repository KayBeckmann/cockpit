/// Wiederholungsregel für eine Aufgabe — wird als JSONB in `tasks.wiederholung`
/// gespeichert und von einem n8n-Cron-Workflow gelesen, der fällige
/// Wiederholungen als neue Inbox-Tasks anlegt.
class Wiederholung {
  /// Erstellt eine Wiederholungsregel aus ihren Einzelfeldern.
  const Wiederholung({required this.typ, required this.intervall, this.bis});

  /// Gültige Werte für [typ].
  static const typen = {'taeglich', 'woechentlich', 'monatlich', 'jaehrlich'};

  /// Art der Wiederholung — eines von [typen].
  final String typ;

  /// Abstand zwischen Wiederholungen, z. B. `2` bei „alle 2 Wochen“.
  final int intervall;

  /// Optionales Enddatum, ab dem keine neuen Wiederholungen mehr entstehen.
  final DateTime? bis;

  /// JSON-Repräsentation für Speicherung als JSONB bzw. API-Antworten.
  Map<String, Object?> toJson() => {
    'typ': typ,
    'intervall': intervall,
    if (bis != null) 'bis': bis!.toIso8601String(),
  };
}

/// Parst und validiert eine Wiederholungsregel aus dem JSON-Body. Liefert
/// `null`, wenn `value` `null` ist (= keine Wiederholung). Wirft eine
/// [FormatException] mit verständlicher Meldung, wenn die Struktur nicht dem
/// erwarteten Format `{typ, intervall, bis}` entspricht (siehe Architektur).
Wiederholung? parseWiederholung(Object? value) {
  if (value == null) return null;
  if (value is! Map) {
    throw const FormatException('wiederholung muss ein Objekt sein');
  }

  final typ = value['typ'];
  if (typ is! String || !Wiederholung.typen.contains(typ)) {
    throw FormatException(
      'wiederholung.typ muss eines von ${Wiederholung.typen.join(', ')} sein',
    );
  }

  final intervall = value['intervall'];
  if (intervall is! int || intervall < 1) {
    throw const FormatException('wiederholung.intervall muss >= 1 sein');
  }

  final bisValue = value['bis'];
  DateTime? bis;
  if (bisValue != null) {
    if (bisValue is! String) {
      throw const FormatException('wiederholung.bis muss ISO-8601 sein');
    }
    bis = DateTime.tryParse(bisValue);
    if (bis == null) {
      throw const FormatException('wiederholung.bis muss ISO-8601 sein');
    }
  }

  return Wiederholung(typ: typ, intervall: intervall, bis: bis);
}
