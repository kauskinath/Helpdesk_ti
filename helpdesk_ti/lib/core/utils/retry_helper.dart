import 'dart:math';

/// Utilitário para retry de operações com exponential backoff
class RetryHelper {
  /// Executa uma operação com retry automático
  ///
  /// [operation] - Função assíncrona a ser executada
  /// [maxAttempts] - Número máximo de tentativas (padrão: 3)
  /// [initialDelay] - Delay inicial em ms (padrão: 100ms)
  /// [maxDelay] - Delay máximo em ms (padrão: 5000ms)
  /// [shouldRetry] - Função para determinar se deve tentar novamente
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    int initialDelay = 100,
    int maxDelay = 5000,
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempts = 0;
    int delay = initialDelay;

    while (true) {
      try {
        attempts++;
        return await operation();
      } on Exception catch (e) {
        // Verificar se deve tentar novamente
        final canRetry = shouldRetry?.call(e) ?? true;

        if (!canRetry || attempts >= maxAttempts) {
          rethrow;
        }

        // Aguardar com exponential backoff + jitter
        final jitter = Random().nextInt(50);
        await Future.delayed(Duration(milliseconds: delay + jitter));

        // Aumentar delay para próxima tentativa
        delay = min(delay * 2, maxDelay);
      }
    }
  }

  /// Executa uma transação do Firestore com retry
  ///
  /// [transaction] - Função de transação a ser executada
  /// [maxAttempts] - Número máximo de tentativas (padrão: 3)
  static Future<T> withTransactionRetry<T>({
    required Future<T> Function() transaction,
    int maxAttempts = 3,
  }) async {
    return withRetry(
      operation: transaction,
      maxAttempts: maxAttempts,
      initialDelay: 100,
      maxDelay: 2000,
      shouldRetry: (e) {
        // Retry apenas em erros de conflito de transação
        final message = e.toString().toLowerCase();
        return message.contains('transaction') ||
            message.contains('aborted') ||
            message.contains('conflict') ||
            message.contains('contention');
      },
    );
  }
}
