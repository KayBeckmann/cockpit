import 'package:backend/src/auth/password_hasher.dart';
import 'package:test/test.dart';

void main() {
  group('PasswordHasher', () {
    test('verifiziert ein korrektes Passwort gegen seinen Hash', () {
      final hash = PasswordHasher.hash('correct horse battery staple');

      expect(
        PasswordHasher.verify('correct horse battery staple', hash),
        isTrue,
      );
    });

    test('lehnt ein falsches Passwort ab', () {
      final hash = PasswordHasher.hash('correct horse battery staple');

      expect(PasswordHasher.verify('falsches-passwort', hash), isFalse);
    });

    test('erzeugt für dasselbe Passwort unterschiedliche Hashes (Salt)', () {
      final first = PasswordHasher.hash('dasselbe-passwort');
      final second = PasswordHasher.hash('dasselbe-passwort');

      expect(first, isNot(equals(second)));
    });

    test('lehnt fehlerhaft formatierte Hashes ab', () {
      expect(
        PasswordHasher.verify('irrelevant', 'kein-gueltiges-format'),
        isFalse,
      );
    });
  });
}
