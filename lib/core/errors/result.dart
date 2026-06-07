import 'failures.dart';

/// Ergebnis einer Repository-Operation: entweder ein Wert vom Typ [T]
/// ([Ok]) oder eine fachliche [Failure] ([Err]). Ergänzt die [Failure]-
/// Hierarchie um die Erfolgsseite, damit Repositories Fehler als Wert
/// zurückgeben statt als Exception über Schichtgrenzen zu werfen.
sealed class Result<T> {
  const Result();
}

/// Erfolgreiches Ergebnis mit dem geladenen/erzeugten [value].
class Ok<T> extends Result<T> {
  /// Erstellt ein erfolgreiches Ergebnis mit [value].
  const Ok(this.value);

  /// Der erfolgreich ermittelte Wert.
  final T value;
}

/// Fehlgeschlagenes Ergebnis mit der aufgetretenen [failure].
class Err<T> extends Result<T> {
  /// Erstellt ein fehlgeschlagenes Ergebnis mit [failure].
  const Err(this.failure);

  /// Der Grund des Fehlschlags.
  final Failure failure;
}
