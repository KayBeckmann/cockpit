import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/// Hasht und prüft Passwörter mit zufälligem Salt (wiederholtes
/// HMAC-SHA256, PBKDF2-artig). Format des gespeicherten Strings:
/// `<salt-hex>:<hash-hex>`.
abstract final class PasswordHasher {
  static const _iterations = 100000;
  static const _saltLength = 16;

  /// Erzeugt einen neuen Hash inklusive zufälligem Salt für [password].
  static String hash(String password) {
    final salt = _randomBytes(_saltLength);
    final derived = _derive(password, salt);
    return '${hex.encode(salt)}:${hex.encode(derived)}';
  }

  /// Prüft, ob [password] zum gespeicherten [storedHash] passt.
  static bool verify(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;

    final salt = hex.decode(parts[0]);
    final expected = hex.decode(parts[1]);
    final actual = _derive(password, salt);

    return _constantTimeEquals(actual, expected);
  }

  static List<int> _derive(String password, List<int> salt) {
    var data = utf8.encode(password) + salt;
    for (var i = 0; i < _iterations; i++) {
      data = Hmac(sha256, salt).convert(data).bytes;
    }
    return data;
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
