enum AuthProvider {
  vsegpt,
  openRouter,
}

extension AuthProviderX on AuthProvider {
  String get storageValue {
    switch (this) {
      case AuthProvider.vsegpt:
        return 'vsegpt';
      case AuthProvider.openRouter:
        return 'openrouter';
    }
  }

  static AuthProvider? fromStorageValue(String? value) {
    switch (value) {
      case 'vsegpt':
        return AuthProvider.vsegpt;
      case 'openrouter':
        return AuthProvider.openRouter;
      default:
        return null;
    }
  }
}
