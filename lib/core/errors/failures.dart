/// Basisklasse für fachliche Fehler, die von Repositories an die
/// Presentation-Schicht durchgereicht werden (Clean Architecture:
/// keine Exceptions über Schichtgrenzen hinweg).
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
