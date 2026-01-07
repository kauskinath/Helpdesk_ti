import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'tabs/chamados_orcamento_tab.dart';
import 'gerente_historico_completo_screen.dart';
import '../features/manutencao/screens/gerente/manutencao_dashboard_gerente_screen.dart';

/// Dashboard completo do Gerente com acesso a TI e Manutenção
///
/// Esta tela gerencia a visualização do gerente com duas abas principais:
/// - Tab TI: Mostra chamados com orçamento e histórico completo
/// - Tab Manutenção: Mostra orçamentos de manutenção para aprovação
class GerenteDashboardScreen extends StatefulWidget {
  const GerenteDashboardScreen({super.key});

  @override
  State<GerenteDashboardScreen> createState() => _GerenteDashboardScreenState();
}

class _GerenteDashboardScreenState extends State<GerenteDashboardScreen>
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
    final userName = authService.userName ?? 'Gerente';

    return Container(
      color: DS.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                            '👔 Gerente',
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
                        onSelected: (String value) {
                          switch (value) {
                            case 'historico':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GerenteHistoricoCompletoScreen(),
                                ),
                              );
                              break;
                            case 'perfil':
                              _mostrarPerfil(context, userName, authService);
                              break;
                            case 'sair':
                              authService.logout();
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'historico',
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 20, color: DS.action),
                                SizedBox(width: 12),
                                Text('Histórico Completo'),
                              ],
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'perfil',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 20, color: DS.action),
                                SizedBox(width: 12),
                                Text('Meu Perfil'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
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
                            color: _tabController.index != 0 ? DS.card : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DS.border, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.computer,
                                color: _tabController.index == 0
                                    ? Colors.white
                                    : DS.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TI',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: _tabController.index == 0
                                      ? Colors.white
                                      : DS.textSecondary,
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
                            color: _tabController.index != 1 ? DS.card : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DS.border, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.build,
                                color: _tabController.index == 1
                                    ? Colors.white
                                    : DS.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Manutenção',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: _tabController.index == 1
                                      ? Colors.white
                                      : DS.textSecondary,
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
                  children: [
                    // Tab TI
                    _buildTIContent(),
                    // Tab Manutenção
                    const ManutencaoDashboardGerenteScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Conteúdo da aba TI: Mostra apenas chamados TI COM orçamento e ABERTOS
  Widget _buildTIContent() {
    return const ChamadosOrcamentoTab();
  }

  void _mostrarPerfil(
    BuildContext context,
    String userName,
    AuthService authService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DS.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Perfil do Usuário',
          style: TextStyle(
            fontFamily: 'Inter',
            color: DS.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👔', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
            // Nome
            Text(
              userName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DS.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Cargo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '👔 GERENTE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFF57C00),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: DS.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DS.success.withValues(alpha: 0.5),
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
                    fontFamily: 'Inter',
                    color: DS.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar', style: TextStyle(color: DS.action)),
          ),
        ],
      ),
    );
  }
}
