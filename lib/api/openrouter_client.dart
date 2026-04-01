// Import JSON library
import 'dart:convert';
// Import HTTP client
import 'package:http/http.dart' as http;
// Import Flutter core classes
import 'package:flutter/foundation.dart';
// Import package for working with .env files
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../auth/auth_config.dart';
import '../auth/auth_provider.dart';
import '../services/secure_storage_service.dart';

// Класс клиента для работы с API OpenRouter
class OpenRouterClient {
  final SecureStorageService _secureStorage;

  /// Для UI/логики, где нужно понять текущий провайдер.
  Future<AuthProvider> get provider async => _requireProvider();

  /// Для отображения и внутренней логики.
  Future<String> get baseUrl async => _requireBaseUrl();

  // Единственный экземпляр класса (Singleton)
  static final OpenRouterClient _instance = OpenRouterClient._internal();

  // Фабричный метод для получения экземпляра
  factory OpenRouterClient() {
    return _instance;
  }

  // Приватный конструктор для реализации Singleton
  OpenRouterClient._internal()
      : _secureStorage = SecureStorageService() {
    // Инициализация клиента
    _initializeClient();
  }

  // Метод инициализации клиента
  void _initializeClient() {
    try {
      if (kDebugMode) {
        print('Initializing OpenRouterClient...');
        print('dotenv MAX_TOKENS: ${dotenv.env['MAX_TOKENS']}');
      }

      if (kDebugMode) {
        print('OpenRouterClient initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing OpenRouterClient: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<AuthProvider> _requireProvider() async {
    final raw = await _secureStorage.getProvider();
    final provider = AuthProviderX.fromStorageValue(raw);
    if (provider == null) {
      throw Exception('Provider not found in secure storage');
    }
    return provider;
  }

  Future<String> _requireApiKey() async {
    final apiKey = await _secureStorage.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('API key not found in secure storage');
    }
    return apiKey;
  }

  Future<String> _requireBaseUrl() async {
    final provider = await _requireProvider();
    return AuthConfig.baseUrlFor(provider);
  }

  Future<Map<String, String>> _headers() async {
    final apiKey = await _requireApiKey();
    return {
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
      'X-Title': 'AI Chat Flutter',
    };
  }

  // Метод получения списка доступных моделей
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      final baseUrl = await _requireBaseUrl();
      final headers = await _headers();
      // Выполнение GET запроса для получения моделей
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Models response status: ${response.statusCode}');
        print('Models response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о моделях
        final modelsData = json.decode(response.body);
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List)
              .map((model) => {
                    'id': model['id'] as String,
                    'name': (() {
                      try {
                        return utf8.decode((model['name'] as String).codeUnits);
                      } catch (e) {
                        // Remove invalid UTF-8 characters and try again
                        final cleaned = (model['name'] as String)
                            .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
                        return utf8.decode(cleaned.codeUnits);
                      }
                    })(),
                    'pricing': {
                      'prompt': model['pricing']['prompt'] as String,
                      'completion': model['pricing']['completion'] as String,
                    },
                    'context_length': (model['context_length'] ??
                            model['top_provider']['context_length'] ??
                            0)
                        .toString(),
                  })
              .toList();
        }
        throw Exception('Invalid API response format');
      } else {
        // Возвращение моделей по умолчанию, если API недоступен
        return [
          {'id': 'deepseek-coder', 'name': 'DeepSeek'},
          {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
          {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
        ];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting models: $e');
      }
      // Возвращение моделей по умолчанию в случае ошибки
      return [
        {'id': 'deepseek-coder', 'name': 'DeepSeek'},
        {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
        {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
      ];
    }
  }

  // Метод отправки сообщения через API
  Future<Map<String, dynamic>> sendMessage(String message, String model) async {
    try {
      final baseUrl = await _requireBaseUrl();
      final headers = await _headers();
      // Подготовка данных для отправки
      final data = {
        'model': model, // Модель для генерации ответа
        'messages': [
          {'role': 'user', 'content': message} // Сообщение пользователя
        ],
        'max_tokens': int.parse(dotenv.env['MAX_TOKENS'] ??
            '1000'), // Максимальное количество токенов
        'temperature': double.parse(
            dotenv.env['TEMPERATURE'] ?? '0.7'), // Температура генерации
        'stream': false, // Отключение потоковой передачи
      };

      if (kDebugMode) {
        print('Sending message to API: ${json.encode(data)}');
      }

      // Выполнение POST запроса
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: headers,
        body: json.encode(data),
      );

      if (kDebugMode) {
        print('Message response status: ${response.statusCode}');
        print('Message response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Успешный ответ
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        // Обработка ошибки
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'error': errorData['error']?['message'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Метод получения текущего баланса
  Future<String> getBalance() async {
    try {
      final baseUrl = await _requireBaseUrl();
      final headers = await _headers();
      // Выполнение GET запроса для получения баланса
      final response = await http.get(
        Uri.parse(baseUrl.contains('vsegpt.ru')
            ? '$baseUrl/balance'
            : '$baseUrl/credits'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Balance response status: ${response.statusCode}');
        print('Balance response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о балансе
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          if (baseUrl.contains('vsegpt.ru')) {
            final credits =
                double.tryParse(data['data']['credits'].toString()) ??
                    0.0; // Доступно средств
            return '${credits.toStringAsFixed(2)}₽'; // Расчет доступного баланса
          } else {
            final credits = data['data']['total_credits'] ?? 0; // Общие кредиты
            final usage =
                data['data']['total_usage'] ?? 0; // Использованные кредиты
            return '\$${(credits - usage).toStringAsFixed(2)}'; // Расчет доступного баланса
          }
        }
      }
      return baseUrl.contains('vsegpt.ru')
          ? '0.00₽'
          : '\$0.00'; // Возвращение нулевого баланса по умолчанию
    } catch (e) {
      if (kDebugMode) {
        print('Error getting balance: $e');
      }
      return 'Error'; // Возвращение ошибки в случае исключения
    }
  }

  // Метод форматирования цен
  String formatPricing(double pricing) {
    try {
      // Сохранение в синхронном методе: формат зависит от провайдера.
      // Т.к. тут нельзя await, используем эвристику: pricing для VSEGPT уже в ₽/K,
      // для OpenRouter показываем $/M.
      // Для корректного отображения можно позже расширить API, передавая провайдера.
      return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting pricing: $e');
      }
      return '0.00';
    }
  }
}
