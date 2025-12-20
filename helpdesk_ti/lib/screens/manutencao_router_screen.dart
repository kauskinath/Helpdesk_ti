import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/shared/widgets/base_dashboard_layout.dart';
import '../features/manutencao/screens/admin/manutencao_dashboard_admin_screen.dart';
import '../features/manutencao/screens/executor/manutencao_dashboard_executor_screen.dart';
import '../features/manutencao/screens/comum/manutencao_meus_chamados_screen.dart';
import '../features/manutencao/screens/comum/manutencao_criar_chamado_screen.dart';

/// Roteador inteligente que direciona para o dashboard correto baseado na role
class ManutencaoRouterScreen extends StatelessWidget {
  const ManutencaoRouterScreen({super.key});

  Widget _buildUserDashboard(BuildContext context, AuthService authService) {
    return const _ManutencaoUserDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Redirecionar baseado na role
    if (authService.isAdminManutencao) {
      return const ManutencaoDashboardAdminScreen();
    } else if (authService.isExecutor) {
      return const ManutencaoDashboardExecutorScreen();
    } else if (authService.isUser) {
      return _buildUserDashboard(context, authService);
    } else if (authService.isAdmin) {
      // Admin TI não tem acesso a manutenção
      return Scaffold(
        appBar: AppBar(
          title: const Text('❌ Acesso Negado'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 80, color: Colors.red.shade300),
                const SizedBox(height: 24),
                const Text(
                  '🚫 Acesso Restrito',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Administradores de TI não têm acesso ao módulo de Manutenção.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fallback - não deveria chegar aqui
    return Scaffold(
      appBar: AppBar(title: const Text('Erro'), backgroundColor: Colors.red),
      body: const Center(child: Text('Role não reconhecida')),
    );
  }
}

/// Dashboard moderno para usuário comum de Manutenção
class _ManutencaoUserDashboard extends StatelessWidget {
  const _ManutencaoUserDashboard();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userName = authService.userName ?? 'Usuário';

    return BaseDashboardLayout(
      title: 'Manutenção',
      titleEmoji: '🔧',
      primaryColor: Colors.teal,
      userName: userName,
      body: const ManutencaoMeusChamadosScreen(),
      menuCategories: [
        MenuCategory(
          title: 'CHAMADOS',
          icon: Icons.description,
          color: Colors.teal.shade700,
          items: [
            MenuItem(
              emoji: '➕',
              icon: Icons.add_circle,
              label: 'Criar Chamado',
              value: 'criar_chamado',
              onTap: (context) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManutencaoCriarChamadoScreen(),
                ),
              ),
            ),
            const MenuItem(
              emoji: '📋',
              icon: Icons.list_alt,
              label: 'Meus Chamados',
              value: 'meus_chamados',
            ),
          ],
        ),
        MenuCategory(
          title: 'CONFIGURAÇÕES',
          icon: Icons.settings,
          color: Colors.grey.shade700,
          items: [
            MenuItem(
              emoji: 'ℹ️',
              icon: Icons.info_outline,
              label: 'Sobre o Sistema',
              value: 'sobre',
              onTap: (context) => Navigator.pushNamed(context, '/about'),
            ),
            MenuItem(
              emoji: '🚪',
              icon: Icons.exit_to_app,
              label: 'Sair do Sistema',
              value: 'sair',
              onTap: (context) => context.read<AuthService>().logout(),
            ),
          ],
        ),
      ],
    );
  }
}
