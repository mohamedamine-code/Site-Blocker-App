import 'dart:math';

class CodeGenerator {
  CodeGenerator._();

  static const _alphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz0123456789';
  static final Random _secureRandom = Random.secure();

  static String generate({int length = 16}) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      final index = _secureRandom.nextInt(_alphabet.length);
      buffer.write(_alphabet[index]);
    }
    return buffer.toString();
  }
}
