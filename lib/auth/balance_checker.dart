import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_provider.dart';
import 'auth_config.dart';

class BalanceCheckResult {
  final double balance;
  final String formatted;

  const BalanceCheckResult({required this.balance, required this.formatted});
}

class BalanceChecker {
  /// Проверяет баланс по ключу и провайдеру.
  ///
  /// Возвращает:
  /// - числовой баланс (для проверок > 0)
  /// - форматированное отображение (для UI)
  Future<BalanceCheckResult> check({
    required String apiKey,
    required AuthProvider provider,
  }) async {
    final baseUrl = AuthConfig.baseUrlFor(provider);

    final headers = <String, String>{
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
      'X-Title': 'AI Chat Flutter',
    };

    final Uri uri;
    switch (provider) {
      case AuthProvider.vsegpt:
        uri = Uri.parse('$baseUrl/balance');
        break;
      case AuthProvider.openRouter:
        uri = Uri.parse('$baseUrl/credits');
        break;
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      final body = utf8.decode(response.bodyBytes);
      throw Exception(
          'Ошибка проверки баланса (${response.statusCode}): $body');
    }

    final Map<String, dynamic> data =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final payload = data['data'];
    if (payload == null) {
      throw Exception('Некорректный ответ баланса: отсутствует поле data');
    }

    switch (provider) {
      case AuthProvider.vsegpt:
        // ожидаем credits в рублях
        final credits =
            double.tryParse((payload['credits'] ?? '0').toString()) ?? 0.0;
        return BalanceCheckResult(
          balance: credits,
          formatted: '${credits.toStringAsFixed(2)}₽',
        );
      case AuthProvider.openRouter:
        final totalCredits =
            double.tryParse((payload['total_credits'] ?? '0').toString()) ??
                0.0;
        final totalUsage =
            double.tryParse((payload['total_usage'] ?? '0').toString()) ?? 0.0;
        final available = totalCredits - totalUsage;
        return BalanceCheckResult(
          balance: available,
          formatted: '\$${available.toStringAsFixed(2)}',
        );
    }
  }
}
