import 'auth_provider.dart';

class ProviderDetector {
  /// Возвращает провайдера по префиксу ключа.
  ///
  /// Требование:
  /// - VSEGPT для ключей `sk-or-vv-...`
  /// - OpenRouter для ключей `sk-or-v1-...`
  static AuthProvider? detect(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.startsWith('sk-or-vv-')) return AuthProvider.vsegpt;
    if (trimmed.startsWith('sk-or-v1-')) return AuthProvider.openRouter;
    return null;
  }
}
