import 'package:flutter/foundation.dart' show kDebugMode;

/// Utilitário para limitar a taxa de operações sensíveis
///
/// Uso:
/// ```dart
/// final rateLimiter = RateLimiter(
///   maxAttempts: 5,
///   windowDuration: Duration(minutes: 15),
/// );
///
/// if (rateLimiter.isAllowed('login_user123')) {
///   // Executar operação
/// } else {
///   // Usuário bloqueado temporariamente
/// }
/// ```
class RateLimiter {
  final int maxAttempts;
  final Duration windowDuration;
  final Duration? blockDuration;

  // Armazena tentativas por chave: {key: [timestamp1, timestamp2, ...]}
  final Map<String, List<DateTime>> _attempts = {};

  // Armazena bloqueios: {key: blockedUntil}
  final Map<String, DateTime> _blockedUntil = {};

  RateLimiter({
    this.maxAttempts = 5,
    this.windowDuration = const Duration(minutes: 15),
    this.blockDuration,
  });

  /// Verifica se a operação é permitida para a chave especificada
  /// Retorna true se permitida, false se bloqueada
  bool isAllowed(String key) {
    _cleanup(key);

    // Verificar se está bloqueado
    if (_blockedUntil.containsKey(key)) {
      final blockedUntil = _blockedUntil[key]!;
      if (DateTime.now().isBefore(blockedUntil)) {
        _log('⛔ Rate limit: $key bloqueado até $blockedUntil');
        return false;
      } else {
        // Bloqueio expirou
        _blockedUntil.remove(key);
      }
    }

    return true;
  }

  /// Registra uma tentativa para a chave especificada
  /// Retorna true se ainda permitido, false se excedeu o limite
  bool recordAttempt(String key) {
    if (!isAllowed(key)) return false;

    _cleanup(key);

    if (!_attempts.containsKey(key)) {
      _attempts[key] = [];
    }

    _attempts[key]!.add(DateTime.now());

    // Verificar se excedeu o limite
    if (_attempts[key]!.length >= maxAttempts) {
      _log('⚠️ Rate limit: $key atingiu $maxAttempts tentativas');

      if (blockDuration != null) {
        _blockedUntil[key] = DateTime.now().add(blockDuration!);
        _log('🔒 $key bloqueado por ${blockDuration!.inMinutes} minutos');
      }

      return false;
    }

    final remaining = maxAttempts - _attempts[key]!.length;
    _log('📊 Rate limit: $key - $remaining tentativas restantes');

    return true;
  }

  /// Remove tentativas antigas fora da janela de tempo
  void _cleanup(String key) {
    if (!_attempts.containsKey(key)) return;

    final cutoff = DateTime.now().subtract(windowDuration);
    _attempts[key] = _attempts[key]!
        .where((timestamp) => timestamp.isAfter(cutoff))
        .toList();

    if (_attempts[key]!.isEmpty) {
      _attempts.remove(key);
    }
  }

  /// Reseta o contador para uma chave (após login bem-sucedido, por exemplo)
  void reset(String key) {
    _attempts.remove(key);
    _blockedUntil.remove(key);
    _log('♻️ Rate limit resetado para: $key');
  }

  /// Retorna o tempo restante de bloqueio para uma chave
  Duration? getBlockTimeRemaining(String key) {
    if (!_blockedUntil.containsKey(key)) return null;

    final remaining = _blockedUntil[key]!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Retorna quantas tentativas restam para uma chave
  int getRemainingAttempts(String key) {
    _cleanup(key);
    final used = _attempts[key]?.length ?? 0;
    return (maxAttempts - used).clamp(0, maxAttempts);
  }

  void _log(String message) {
    if (kDebugMode) print(message);
  }
}

/// Rate limiter singleton para operações de autenticação
class AuthRateLimiter {
  static final AuthRateLimiter _instance = AuthRateLimiter._internal();
  factory AuthRateLimiter() => _instance;
  AuthRateLimiter._internal();

  final RateLimiter _loginLimiter = RateLimiter(
    maxAttempts: 5,
    windowDuration: const Duration(minutes: 15),
    blockDuration: const Duration(minutes: 30),
  );

  final RateLimiter _passwordResetLimiter = RateLimiter(
    maxAttempts: 3,
    windowDuration: const Duration(hours: 1),
    blockDuration: const Duration(hours: 2),
  );

  /// Verifica se login é permitido para o email
  bool canAttemptLogin(String email) {
    return _loginLimiter.isAllowed('login_$email');
  }

  /// Registra tentativa de login falha
  bool recordFailedLogin(String email) {
    return _loginLimiter.recordAttempt('login_$email');
  }

  /// Reseta contador após login bem-sucedido
  void resetLoginAttempts(String email) {
    _loginLimiter.reset('login_$email');
  }

  /// Tempo restante de bloqueio de login
  Duration? getLoginBlockTimeRemaining(String email) {
    return _loginLimiter.getBlockTimeRemaining('login_$email');
  }

  /// Tentativas restantes de login
  int getLoginAttemptsRemaining(String email) {
    return _loginLimiter.getRemainingAttempts('login_$email');
  }

  /// Verifica se reset de senha é permitido
  bool canAttemptPasswordReset(String email) {
    return _passwordResetLimiter.isAllowed('reset_$email');
  }

  /// Registra tentativa de reset de senha
  bool recordPasswordResetAttempt(String email) {
    return _passwordResetLimiter.recordAttempt('reset_$email');
  }

  /// Reseta contador de reset de senha
  void resetPasswordResetAttempts(String email) {
    _passwordResetLimiter.reset('reset_$email');
  }
}
