/// Configurações gerais do aplicativo
///
/// Centralize todas as configurações, URLs, limites e constantes aqui
library;

class AppConfig {
  // ========== INFORMAÇÕES DO APP ==========
  static const String appName = 'Pichau TI';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Pichau Informática';

  // ========== CONFIGURAÇÕES DE CHAMADOS ==========

  /// Prioridades disponíveis para chamados
  static const List<int> availablePriorities = [1, 2, 3];

  /// Nomes das prioridades
  static const Map<int, String> priorityNames = {
    1: 'Baixa',
    2: 'Média',
    3: 'Alta',
  };

  /// Prioridade padrão ao criar novo chamado
  static const int defaultPriority = 2; // Média

  /// Status possíveis para chamados de serviço
  static const List<String> ticketStatuses = [
    'Aberto',
    'Em Andamento',
    'Aguardando',
    'Fechado',
    'Rejeitado',
  ];

  /// Status possíveis para solicitações de compra
  static const List<String> solicitacaoStatuses = [
    'Pendente',
    'Aprovado',
    'Reprovado',
  ];

  // ========== CONFIGURAÇÕES DE UI ==========

  /// Número máximo de linhas para descrição em cards
  static const int maxDescriptionLines = 3;

  /// Delay para auto-refresh (em segundos)
  static const int autoRefreshDelay = 30;

  /// Tempo de duração padrão para SnackBars (em segundos)
  static const int snackBarDuration = 3;

  // ========== VALIDAÇÕES ==========

  /// Tamanho mínimo para título de chamado
  static const int minTitleLength = 5;

  /// Tamanho máximo para título de chamado
  static const int maxTitleLength = 100;

  /// Tamanho mínimo para descrição
  static const int minDescriptionLength = 10;

  /// Tamanho máximo para descrição
  static const int maxDescriptionLength = 500;

  // ========== FIREBASE ==========

  /// Nome da coleção de tickets no Firestore
  static const String ticketsCollection = 'tickets';

  /// Nome da coleção de solicitações no Firestore
  static const String solicitacoesCollection = 'solicitacoes';

  /// Nome da coleção de usuários no Firestore
  static const String usersCollection = 'users';

  // ========== FEATURES FLAGS ==========

  /// Habilitar modo debug (desabilitado para produção)
  static const bool debugMode = false;

  /// Habilitar logs detalhados (mantidos para notificações)
  static const bool verboseLogs = true;

  /// Habilitar notificações push (futuro)
  static const bool enablePushNotifications = false;

  /// Habilitar anexos de imagens
  static const bool enableImageAttachments = true;

  /// Habilitar exportação de relatórios
  static const bool enableReports = false;
}
