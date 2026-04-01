import 'package:flutter/material.dart';

import '../auth/balance_checker.dart';
import '../auth/pin_generator.dart';
import '../auth/provider_detector.dart';
import '../auth/auth_provider.dart';
import '../services/secure_storage_service.dart';
import 'pin_entry_screen.dart';

class ApiKeyEntryScreen extends StatefulWidget {
  const ApiKeyEntryScreen({super.key});

  @override
  State<ApiKeyEntryScreen> createState() => _ApiKeyEntryScreenState();
}

class _ApiKeyEntryScreenState extends State<ApiKeyEntryScreen> {
  final _controller = TextEditingController();
  final _storage = SecureStorageService();
  final _balanceChecker = BalanceChecker();

  AuthProvider? _detectedProvider;
  String? _error;
  String? _balanceText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onKeyChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onKeyChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onKeyChanged() {
    final key = _controller.text;
    final provider = ProviderDetector.detect(key);
    if (provider != _detectedProvider) {
      setState(() {
        _detectedProvider = provider;
        _error = null;
        _balanceText = null;
      });
    }
  }

  String _providerLabel(AuthProvider? provider) {
    switch (provider) {
      case AuthProvider.vsegpt:
        return 'VSEGPT';
      case AuthProvider.openRouter:
        return 'OpenRouter';
      case null:
        return 'Не определён';
    }
  }

  Future<void> _submit() async {
    final apiKey = _controller.text.trim();
    final provider = ProviderDetector.detect(apiKey);

    if (apiKey.isEmpty) {
      setState(() => _error = 'Введите API-ключ');
      return;
    }

    if (provider == null) {
      setState(() => _error =
          'Не удалось определить провайдера по формату ключа.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _balanceText = null;
    });

    try {
      final result = await _balanceChecker.check(
        apiKey: apiKey,
        provider: provider,
      );

      setState(() {
        _balanceText = result.formatted;
      });

      if (result.balance <= 0) {
        setState(() => _error = 'Предупреждение: Баланс пуст, но вход разрешен.');
        // Убираем return; чтобы код шел дальше к генерации PIN
      }

      final pin = PinGenerator.generate4Digits();

      await _storage.saveApiKey(apiKey);
      await _storage.saveProvider(provider.storageValue);
      await _storage.savePin(pin);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ваш PIN-код'),
            content: SelectableText(
              pin,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Продолжить'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // После сохранения ключа логично сразу попросить ввести PIN.
      // Это также валидирует, что пользователь его записал.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PinEntryScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ввод API-ключа'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'API-ключ',
                  hintText: 'sk-or-v1-... или sk-or-vv-...',
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: 12),
              Text(
                'Провайдер: ${_providerLabel(_detectedProvider)}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (_balanceText != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Баланс: $_balanceText',
                  style: const TextStyle(color: Color(0xFF33CC33)),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Проверить и сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
