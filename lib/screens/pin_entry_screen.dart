import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/secure_storage_service.dart';
import '../providers/chat_provider.dart';
import 'api_key_entry_screen.dart';
import 'chat_screen.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _controller = TextEditingController();
  final _storage = SecureStorageService();

  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkPin() async {
    final entered = _controller.text.trim();
    if (entered.length != 4) {
      setState(() => _error = 'PIN должен состоять из 4 цифр');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final saved = await _storage.getPin();
      if (saved == null || saved.isEmpty) {
        // Неконсистентное состояние — отправим на ввод ключа.
        await _storage.clearAuth();
        if (mounted) {
          context.read<ChatProvider>().lock();
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ApiKeyEntryScreen()),
        );
        return;
      }

      if (entered != saved) {
        setState(() => _error = 'Неверный PIN');
        return;
      }

      // Успешный PIN -> разблокируем и переинициализируем чат под текущий ключ из secure storage.
      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.unlock();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reset() async {
    final chatProvider = context.read<ChatProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Сбросить данные?'),
          content: const Text(
            'Будут удалены сохранённые API-ключ и PIN. После этого нужно ввести новый ключ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Сбросить',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _storage.clearAuth();
    if (mounted) {
      // «Полный сброс данных»: очищаем и локальную историю.
      await chatProvider.clearHistory();
      chatProvider.lock();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ApiKeyEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Введите PIN'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _reset,
            child: const Text('Сброс', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN (4 цифры)',
                ),
                maxLength: 4,
                obscureText: true,
                onSubmitted: (_) => _isLoading ? null : _checkPin(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkPin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Войти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
