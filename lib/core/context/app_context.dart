/// Die drei Zustände des globalen Kontext-Schalters (siehe ADR-0006).
///
/// Jede Entität trägt `kontext ∈ {privat, arbeit, beides}`; der globale
/// Schalter steuert, welche Daten angezeigt werden — `alles` zeigt
/// privat und arbeit gemeinsam.
enum AppContext {
  privat,
  arbeit,
  alles;

  String get label => switch (this) {
    AppContext.privat => 'Privat',
    AppContext.arbeit => 'Arbeit',
    AppContext.alles => 'Alles',
  };
}
