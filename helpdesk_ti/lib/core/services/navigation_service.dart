import 'package:flutter/material.dart';

/// Serviço de Navegação Global
///
/// Permite navegar sem acesso direto ao BuildContext.
/// Útil para navegação a partir de notificações, handlers em background, etc.
///
/// ## Uso:
///
/// 1. Registrar a chave global no MaterialApp:
/// ```dart
/// MaterialApp(
///   navigatorKey: NavigationService.navigatorKey,
///   ...
/// )
/// ```
///
/// 2. Navegar de qualquer lugar:
/// ```dart
/// NavigationService.navigateTo('/chamado/123');
/// NavigationService.navigateToNamed('/fila_tecnica', arguments: data);
/// NavigationService.pop();
/// ```
class NavigationService {
  /// Chave global do Navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Obter o contexto atual do Navigator
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navegar para uma rota nomeada
  ///
  /// [routeName] - Nome da rota (ex: '/chamado')
  /// [arguments] - Argumentos opcionais para passar à rota
  /// [replace] - Se true, substitui a rota atual
  static Future<T?>? navigateToNamed<T>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) {
    if (navigatorKey.currentState == null) {
      print('⚠️ NavigationService: Navigator não está pronto');
      return null;
    }

    if (replace) {
      return navigatorKey.currentState!.pushReplacementNamed(
        routeName,
        arguments: arguments,
      );
    } else {
      return navigatorKey.currentState!.pushNamed(
        routeName,
        arguments: arguments,
      );
    }
  }

  /// Navegar para uma tela específica (widget)
  ///
  /// [page] - Widget da página de destino
  /// [replace] - Se true, substitui a rota atual
  static Future<T?>? navigateTo<T>(
    Widget page, {
    bool replace = false,
  }) {
    if (navigatorKey.currentState == null) {
      print('⚠️ NavigationService: Navigator não está pronto');
      return null;
    }

    final route = MaterialPageRoute<T>(builder: (_) => page);

    if (replace) {
      return navigatorKey.currentState!.pushReplacement(route);
    } else {
      return navigatorKey.currentState!.push(route);
    }
  }

  /// Voltar para a tela anterior
  ///
  /// [result] - Resultado opcional para passar de volta
  static void pop<T>([T? result]) {
    if (navigatorKey.currentState == null) {
      print('⚠️ NavigationService: Navigator não está pronto');
      return;
    }

    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop(result);
    }
  }

  /// Voltar até uma rota específica
  ///
  /// [routeName] - Nome da rota de destino
  static void popUntil(String routeName) {
    if (navigatorKey.currentState == null) {
      print('⚠️ NavigationService: Navigator não está pronto');
      return;
    }

    navigatorKey.currentState!.popUntil(
      (route) => route.settings.name == routeName,
    );
  }

  /// Limpar pilha de navegação e ir para rota
  ///
  /// [routeName] - Nome da rota de destino
  /// [arguments] - Argumentos opcionais
  static Future<T?>? popAllAndNavigateTo<T>(
    String routeName, {
    Object? arguments,
  }) {
    if (navigatorKey.currentState == null) {
      print('⚠️ NavigationService: Navigator não está pronto');
      return null;
    }

    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Navegar para detalhes de chamado
  ///
  /// [chamadoId] - ID do chamado
  static void navigateToChamadoDetails(String chamadoId) {
    navigateToNamed('/chamado_details', arguments: chamadoId);
  }

  /// Navegar para fila técnica
  static void navigateToFilaTecnica() {
    navigateToNamed('/home'); // Home tem a aba de fila técnica
  }

  /// Navegar para aprovar solicitações
  static void navigateToAprovarSolicitacoes() {
    navigateToNamed('/home'); // Home tem a aba de solicitações
  }

  /// Navegar para histórico de solicitações
  static void navigateToHistoricoSolicitacoes() {
    navigateToNamed('/home'); // Home tem a aba de histórico
  }

  /// Navegar para home (tela principal)
  static void navigateToHome() {
    navigateToNamed('/home');
  }

  /// Mostrar SnackBar global
  ///
  /// [message] - Mensagem a exibir
  /// [backgroundColor] - Cor de fundo
  /// [duration] - Duração da exibição
  static void showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = currentContext;
    if (context == null) {
      print('⚠️ NavigationService: Contexto não disponível para SnackBar');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostrar Dialog global
  ///
  /// [title] - Título do diálogo
  /// [content] - Conteúdo do diálogo
  /// [actions] - Botões de ação
  static Future<T?> showDialogGlobal<T>({
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    final context = currentContext;
    if (context == null) {
      print('⚠️ NavigationService: Contexto não disponível para Dialog');
      return Future.value(null);
    }

    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions ??
            [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
      ),
    );
  }
}
