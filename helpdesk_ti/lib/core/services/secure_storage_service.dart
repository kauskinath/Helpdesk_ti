import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de armazenamento seguro para dados sensíveis
///
/// Usa flutter_secure_storage para criptografar senhas e tokens
/// em dispositivos móveis. Na web, usa SharedPreferences como fallback
/// (não tão seguro, mas funcional).
class SecureStorageService {
  // Singleton
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Storage seguro (mobile)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const String _emailKey = 'secure_email';
  static const String _passwordKey = 'secure_password';
  static const String _rememberMeKey = 'remember_me';

  /// Salvar credenciais de forma segura
  Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (rememberMe) {
      if (kIsWeb) {
        // Web: usar SharedPreferences (menos seguro, mas único disponível)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_emailKey, email);
        // Na web, NÃO salvamos a senha por segurança
        await prefs.setBool(_rememberMeKey, true);
      } else {
        // Mobile: usar flutter_secure_storage
        await _secureStorage.write(key: _emailKey, value: email);
        await _secureStorage.write(key: _passwordKey, value: password);
        await _secureStorage.write(key: _rememberMeKey, value: 'true');
      }
    } else {
      await clearCredentials();
    }
  }

  /// Carregar credenciais salvas
  Future<Map<String, dynamic>> loadCredentials() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
        if (!rememberMe) {
          return {'rememberMe': false};
        }
        return {
          'email': prefs.getString(_emailKey),
          'password': null, // Na web, não salvamos senha
          'rememberMe': rememberMe,
        };
      } else {
        final rememberMe = await _secureStorage.read(key: _rememberMeKey);
        if (rememberMe != 'true') {
          return {'rememberMe': false};
        }
        return {
          'email': await _secureStorage.read(key: _emailKey),
          'password': await _secureStorage.read(key: _passwordKey),
          'rememberMe': true,
        };
      }
    } catch (e) {
      // Em caso de erro, retornar vazio
      return {'rememberMe': false};
    }
  }

  /// Limpar credenciais salvas
  Future<void> clearCredentials() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);
      await prefs.remove(_rememberMeKey);
    } else {
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
      await _secureStorage.delete(key: _rememberMeKey);
    }
  }

  /// Verificar se tem credenciais salvas
  Future<bool> hasCredentials() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } else {
      final rememberMe = await _secureStorage.read(key: _rememberMeKey);
      return rememberMe == 'true';
    }
  }

  /// Salvar valor genérico de forma segura
  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  /// Ler valor genérico
  Future<String?> read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  /// Deletar valor genérico
  Future<void> delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  /// Limpar todo o armazenamento seguro
  Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }
}
