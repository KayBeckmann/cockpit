import 'package:backend/src/auth/jwt_service.dart';
import 'package:test/test.dart';

const _userId = '11111111-1111-1111-1111-111111111111';

void main() {
  group('JwtService', () {
    const service = JwtService('test-secret');

    test('verifiziert ein selbst ausgestelltes Token', () {
      final token = service.issueToken(_userId);

      expect(service.verifyToken(token), equals(_userId));
    });

    test('lehnt ein mit anderem Secret signiertes Token ab', () {
      const other = JwtService('anderes-secret');
      final token = other.issueToken(_userId);

      expect(service.verifyToken(token), isNull);
    });

    test('lehnt offensichtlich ungültige Tokens ab', () {
      expect(service.verifyToken('kein.gueltiges.token'), isNull);
    });
  });
}
