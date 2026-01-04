import 'package:flutter_test/flutter_test.dart';
import 'package:helpdesk_ti/core/utils/retry_helper.dart';

void main() {
  group('RetryHelper', () {
    test(
      'withRetry executa operação com sucesso na primeira tentativa',
      () async {
        int attempts = 0;

        final result = await RetryHelper.withRetry<int>(
          operation: () async {
            attempts++;
            return 42;
          },
          maxAttempts: 3,
        );

        expect(result, equals(42));
        expect(attempts, equals(1));
      },
    );

    test('withRetry retenta operação em caso de falha', () async {
      int attempts = 0;

      final result = await RetryHelper.withRetry<int>(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Tentativa $attempts falhou');
          }
          return 42;
        },
        maxAttempts: 5,
        initialDelay: 10,
      );

      expect(result, equals(42));
      expect(attempts, equals(3));
    });

    test('withRetry lança exceção após esgotar tentativas', () async {
      expect(
        () => RetryHelper.withRetry<int>(
          operation: () async {
            throw Exception('Sempre falha');
          },
          maxAttempts: 3,
          initialDelay: 10,
        ),
        throwsException,
      );
    });

    test('withRetry não retenta para exceções não retriáveis', () async {
      int attempts = 0;

      expect(
        () => RetryHelper.withRetry<int>(
          operation: () async {
            attempts++;
            throw const FormatException('Erro de formato');
          },
          maxAttempts: 5,
          initialDelay: 10,
          shouldRetry: (e) => e is! FormatException,
        ),
        throwsFormatException,
      );

      // Deve ter tentado apenas uma vez
      expect(attempts, equals(1));
    });
  });
}
