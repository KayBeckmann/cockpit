import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Stellt JWTs für Benutzer aus und prüft eingehende Tokens.
/// Das Signier-Secret kommt aus `JWT_SECRET` in der `.env`.
class JwtService {
  /// Erstellt den Service mit dem Signier-Secret aus der Umgebung.
  const JwtService(this._secret);

  final String _secret;

  /// Gültigkeitsdauer ausgestellter Tokens.
  static const tokenLifetime = Duration(days: 7);

  /// Erstellt ein signiertes Token, das die Benutzer-ID als `sub` trägt.
  String issueToken(String userId) {
    final jwt = JWT({'sub': userId});
    return jwt.sign(SecretKey(_secret), expiresIn: tokenLifetime);
  }

  /// Prüft [token] und liefert die enthaltene Benutzer-ID zurück, oder
  /// `null`, wenn das Token ungültig, abgelaufen oder falsch signiert ist.
  String? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      final payload = jwt.payload;
      if (payload is Map && payload['sub'] is String) {
        return payload['sub'] as String;
      }
      return null;
    } on JWTException {
      return null;
    }
  }
}
