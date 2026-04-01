import 'package:flutter/material.dart';

import '../services/secure_storage_service.dart';
import 'api_key_entry_screen.dart';
import 'pin_entry_screen.dart';

/// Экран-«ворота»: решает, что показывать при запуске.
///
/// - Нет ключа в secure storage -> ввод API-ключа
/// - Ключ есть -> ввод PIN
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = SecureStorageService();
  late Future<bool> _hasKeyFuture;

  @override
  void initState() {
    super.initState();
    _hasKeyFuture = _storage.hasApiKey();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasKeyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasKey = snapshot.data == true;
        return hasKey ? const PinEntryScreen() : const ApiKeyEntryScreen();
      },
    );
  }
}
