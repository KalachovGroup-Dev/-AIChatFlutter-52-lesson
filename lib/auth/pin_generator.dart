import 'dart:math';

class PinGenerator {
  /// Генерирует случайный 4-значный PIN (0000..9999).
  static String generate4Digits() {
    final random = Random.secure();
    final value = random.nextInt(10000);
    return value.toString().padLeft(4, '0');
  }
}
