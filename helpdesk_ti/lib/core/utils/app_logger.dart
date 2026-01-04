import 'package:flutter/foundation.dart';

/// Utilitário de logging para produção
///
/// Em produção (kReleaseMode), os logs são silenciados.
/// Em debug, os logs são exibidos normalmente.
class AppLogger {
  /// Log de informação
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }

  /// Log de sucesso
  static void success(String message) {
    if (kDebugMode) {
      print('✅ $message');
    }
  }

  /// Log de aviso
  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ $message');
    }
  }

  /// Log de erro
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ $message');
      if (error != null) {
        print('   Error: $error');
      }
      if (stackTrace != null) {
        print('   Stack: $stackTrace');
      }
    }
  }

  /// Log de debug (mais detalhado)
  static void debug(String message) {
    if (kDebugMode) {
      print('🔍 $message');
    }
  }

  /// Log de notificação
  static void notification(String message) {
    if (kDebugMode) {
      print('🔔 $message');
    }
  }

  /// Log de navegação
  static void navigation(String message) {
    if (kDebugMode) {
      print('🧭 $message');
    }
  }

  /// Log de autenticação
  static void auth(String message) {
    if (kDebugMode) {
      print('🔐 $message');
    }
  }

  /// Log de Firebase
  static void firebase(String message) {
    if (kDebugMode) {
      print('🔥 $message');
    }
  }

  /// Log com separador visual
  static void separator(String title) {
    if (kDebugMode) {
      print('═══════════════════════════════════════');
      print('  $title');
      print('═══════════════════════════════════════');
    }
  }
}
