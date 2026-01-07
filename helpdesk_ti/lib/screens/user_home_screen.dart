import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import '../features/manutencao/screens/comum/manutencao_criar_chamado_screen.dart';
import 'tabs/meus_chamados_tab.dart';
import '../features/manutencao/screens/comum/manutencao_meus_chamados_screen.dart';

/// Home screen para usuários comuns com acesso a TI e Manutenção via tabs
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userName = authService.userName ?? 'Usuário';

    return Container(
      color: DS.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            color: DS.action,
            borderRadius: BorderRadius.circular(16),
          ),
          child: FloatingActionButton.extended(
            heroTag: 'user_home_new_ticket_fab',
            onPressed: () => _mostrarSeletorTipoChamado(context),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add, size: 28, color: Colors.white),
            label: const Text(
              'Novo Chamado',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header com saudação e menu
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Saudação personalizada
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $userName!',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: DS.textPrimary,
                            ),
                          ),
                          const Text(
                            '👤 Usuário Comum',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: DS.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu popup simples (3 pontinhos)
                    Container(
                      decoration: BoxDecoration(
                        color: DS.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DS.border, width: 1),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: DS.textPrimary,
                        ),
                        tooltip: 'Menu',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        offset: const Offset(0, 50),
                        onSelected: (value) =>
                            _onMenuSelected(context, value, authService),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'perfil',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 20, color: DS.action),
                                SizedBox(width: 12),
                                Text('Meu Perfil'),
                              ],
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'sair',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.exit_to_app,
                                  size: 20,
                                  color: DS.error,
                                ),
                                SizedBox(width: 12),
                                Text('Sair'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs para TI e Manutenção
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabController.index = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: _tabController.index == 0
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF2196F3),
                                      Color(0xFF1976D2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _tabController.index != 0
                                ? Colors.black.withValues(alpha: 0.3)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.computer,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: _tabController.index == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabController.index = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: _tabController.index == 1
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF9800),
                                      Color(0xFFF57C00),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _tabController.index != 1
                                ? Colors.black.withValues(alpha: 0.3)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.build,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Manutenção',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: _tabController.index == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Conteúdo das tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    // Tab TI
                    MeusChamadosTab(),
                    // Tab Manutenção
                    ManutencaoMeusChamadosScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMenuSelected(
    BuildContext context,
    String value,
    AuthService authService,
  ) {
    switch (value) {
      case 'perfil':
        _mostrarPerfil(context, authService);
        break;
      case 'sair':
        authService.logout();
        break;
    }
  }

  Future<void> _mostrarSeletorTipoChamado(BuildContext context) async {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: DS.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DS.border, width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              const Text(
                '🎯 Qual tipo de chamado?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: DS.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecione o departamento responsável',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: DS.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Opção TI
              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.of(context).pushNamed('/new_ticket');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DS.action,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.computer, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'TI - Suporte Técnico',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hardware, Software, Rede',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Opção Manutenção
              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ManutencaoCriarChamadoScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.build, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Manutenção - Infraestrutura',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Reparos, Instalações, Serviços',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão Cancelar
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: DS.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarPerfil(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade700,
              child: Text(
                authService.userName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('Meu Perfil', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.person, 'Nome', authService.userName ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', authService.userEmail ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.badge, 'Perfil', 'Usuário Comum'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
