import 'auth_provider.dart';

/// Конфигурация базовых URL провайдеров.
///
/// При необходимости можно вынести в app_settings.json или .env,
/// но ключи и PIN всегда должны быть только в secure storage.
class AuthConfig {
  static String baseUrlFor(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.openRouter:
        return 'https://openrouter.ai/api/v1';
      case AuthProvider.vsegpt:
        // Оставляем API совместимым с OpenAI-style роутами.
        // Баланс будет проверяться через /balance.
        return 'https://api.vsegpt.ru/v1';
    }
  }
}
