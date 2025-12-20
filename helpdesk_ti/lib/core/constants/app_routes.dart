/// Rotas nomeadas do aplicativo
///
/// Centralize todas as rotas aqui para facilitar manutenção e navegação
library;

class AppRoutes {
  // ========== ROTAS PRINCIPAIS ==========

  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';

  // ========== ROTAS DE CHAMADOS ==========

  static const String newTicket = '/new_ticket';
  static const String ticketDetails = '/ticket_details';
  static const String editTicket = '/edit_ticket';

  // ========== ROTAS DE SOLICITAÇÕES ==========

  static const String newSolicitacao = '/new_solicitacao';
  static const String solicitacaoDetails = '/solicitacao_details';

  // ========== ROTAS ADMINISTRATIVAS ==========

  static const String admin = '/admin';
  static const String manageUsers = '/manage_users';
  static const String createUser = '/create_user';
  static const String editUser = '/edit_user';

  // ========== ROTAS DE CONFIGURAÇÕES ==========

  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String about = '/about';

  // ========== HELPERS ==========

  /// Todas as rotas do app
  static List<String> get allRoutes => [
    splash,
    home,
    login,
    newTicket,
    ticketDetails,
    editTicket,
    newSolicitacao,
    solicitacaoDetails,
    admin,
    manageUsers,
    createUser,
    editUser,
    settings,
    profile,
    about,
  ];

  /// Verifica se a rota existe
  static bool isValidRoute(String route) => allRoutes.contains(route);
}
