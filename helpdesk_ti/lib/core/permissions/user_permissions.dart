/// Sistema de Permissões Centralizado
///
/// Este arquivo define as permissões para cada tipo de usuário no sistema.
///
/// Roles disponíveis:
/// - 'user': Usuário comum (cria chamados e solicitações)
/// - 'manager': Gerente (aprova solicitações de compra)
/// - 'admin': Administrador (gerencia serviços técnicos)
library;

class UserPermissions {
  final String role;

  UserPermissions(this.role);

  // ========== PERMISSÕES DE VISUALIZAÇÃO ==========

  /// Pode ver a aba "Meus Chamados"
  bool get canViewMeusChamados => true; // Todos podem ver

  /// Pode ver a aba "Solicitações" (aprovar compras)
  bool get canViewSolicitacoes => role == 'manager';

  /// Pode ver a aba "Fila Técnica" (gerenciar serviços)
  bool get canViewFilaTecnica => role == 'admin' || role == 'manager';

  // ========== PERMISSÕES DE CRIAÇÃO ==========

  /// Pode criar chamados de serviço
  bool get canCreateServico => true; // Todos podem criar

  /// Pode criar solicitações de compra
  bool get canCreateSolicitacao => true; // Todos podem criar

  // ========== PERMISSÕES DE EDIÇÃO ==========

  /// Pode editar chamados de serviço na Fila Técnica
  bool get canEditServicos => role == 'admin';

  /// Pode aprovar/rejeitar solicitações de compra
  bool get canApproveRejectSolicitacoes => role == 'manager';

  /// Pode mudar status de chamados (Aberto, Em Andamento, Aguardando, etc)
  bool get canChangeTicketStatus => role == 'admin';

  /// Pode atribuir chamados para si mesmo (pegar chamado)
  bool get canAssignTicketsToSelf => role == 'admin';

  /// Pode adicionar notas/comentários em chamados
  bool get canAddNotesToTickets => role == 'admin' || role == 'manager';

  // ========== PERMISSÕES ADMINISTRATIVAS ==========

  /// Pode acessar painel de gerenciamento de usuários
  bool get canManageUsers => role == 'admin';

  /// Pode ver todos os chamados do sistema
  bool get canViewAllTickets => role == 'admin' || role == 'manager';

  /// Pode deletar chamados
  bool get canDeleteTickets => role == 'admin';

  /// Pode exportar relatórios
  bool get canExportReports => role == 'admin' || role == 'manager';

  /// Pode ver dados estatísticos/dashboard
  bool get canViewDashboard => role == 'admin' || role == 'manager';

  // ========== HELPERS ==========

  /// Verifica se o usuário tem pelo menos uma permissão administrativa
  bool get isAdministrative =>
      role == 'admin' || role == 'manager' || role == 'admin_manutencao';

  /// Retorna descrição amigável do role
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return '⚙️ ADMINISTRADOR TI';
      case 'manager':
        return '👔 GERENTE';
      case 'admin_manutencao':
        return '🛠️ SUPERVISOR MANUTENÇÃO';
      case 'executor':
        return '🔧 EXECUTOR';
      case 'user':
        return '👤 USUÁRIO';
      default:
        return '❓ DESCONHECIDO';
    }
  }

  /// Retorna emoji do role
  String get roleEmoji {
    switch (role) {
      case 'admin':
        return '⚙️';
      case 'manager':
        return '👔';
      case 'admin_manutencao':
        return '🛠️';
      case 'executor':
        return '🔧';
      case 'user':
        return '👤';
      default:
        return '❓';
    }
  }

  /// Retorna cor do role (para UI)
  String get roleColorHex {
    switch (role) {
      case 'admin':
        return '#EF5350'; // Vermelho
      case 'manager':
        return '#FF9800'; // Laranja
      case 'admin_manutencao':
        return '#9C27B0'; // Roxo
      case 'executor':
        return '#009688'; // Teal
      case 'user':
        return '#66BB6A'; // Verde
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  // ========== VALIDAÇÕES ==========

  /// Valida se a role é válida
  static bool isValidRole(String? role) {
    return role == 'user' ||
        role == 'manager' ||
        role == 'admin' ||
        role == 'admin_manutencao' ||
        role == 'executor';
  }

  /// Lista todas as roles disponíveis
  static List<String> get availableRoles => [
    'user',
    'manager',
    'admin',
    'admin_manutencao',
    'executor',
  ];

  /// Lista todas as permissões do usuário (para debug)
  Map<String, bool> getAllPermissions() {
    return {
      'canViewMeusChamados': canViewMeusChamados,
      'canViewSolicitacoes': canViewSolicitacoes,
      'canViewFilaTecnica': canViewFilaTecnica,
      'canCreateServico': canCreateServico,
      'canCreateSolicitacao': canCreateSolicitacao,
      'canEditServicos': canEditServicos,
      'canApproveRejectSolicitacoes': canApproveRejectSolicitacoes,
      'canChangeTicketStatus': canChangeTicketStatus,
      'canAssignTicketsToSelf': canAssignTicketsToSelf,
      'canAddNotesToTickets': canAddNotesToTickets,
      'canManageUsers': canManageUsers,
      'canViewAllTickets': canViewAllTickets,
      'canDeleteTickets': canDeleteTickets,
      'canExportReports': canExportReports,
      'canViewDashboard': canViewDashboard,
    };
  }

  @override
  String toString() {
    return 'UserPermissions(role: $role, displayName: $roleDisplayName)';
  }
}
