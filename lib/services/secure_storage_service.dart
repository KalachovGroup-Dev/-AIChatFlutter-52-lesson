import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ключи, которые мы храним в защищённом хранилище.
///
/// Важно: flutter_secure_storage на разных платформах использует разные механизмы
/// (Keychain/Keystore/DPAPI). Для Windows это будет защищённое хранилище учётной
/// записи пользователя.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String keyApiKey = 'auth.apiKey';
  static const String keyProvider = 'auth.provider';
  static const String keyPin = 'auth.pin';

  Future<String?> getApiKey() => _storage.read(key: keyApiKey);

  Future<void> saveApiKey(String apiKey) => _storage.write(
        key: keyApiKey,
        value: apiKey,
      );

  Future<String?> getProvider() => _storage.read(key: keyProvider);

  Future<void> saveProvider(String provider) => _storage.write(
        key: keyProvider,
        value: provider,
      );

  Future<String?> getPin() => _storage.read(key: keyPin);

  Future<void> savePin(String pin) => _storage.write(
        key: keyPin,
        value: pin,
      );

  /// Полный сброс аутентификационных данных.
  /// Не трогаем историю чата (SQLite) — это будет отдельное решение/кнопка.
  Future<void> clearAuth() async {
    await _storage.delete(key: keyApiKey);
    await _storage.delete(key: keyProvider);
    await _storage.delete(key: keyPin);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.trim().isNotEmpty;
  }
}
