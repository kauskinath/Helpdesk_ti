import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            isDarkMode
                ? 'assets/images/wallpaper_dark.png'
                : 'assets/images/wallpaper_light.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
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
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                              shadows: isDarkMode
                                  ? null
                                  : [
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                          ),
                          Text(
                            '👔 Gerente',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.black,
                              shadows: isDarkMode
                                  ? null
                                  : [
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botão de alternar tema
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          context.read<ThemeProvider>().toggleTheme();
                        },
                        tooltip: isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Menu popup (3 pontinhos)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                          case 'sobre':
                            Navigator.pushNamed(context, '/about');
                            break;
                          case 'sair':
                            authService.logout();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        // Histórico de Chamados
                        PopupMenuItem<String>(
                          value: 'historico',
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 12),
                              const Text('Histórico Completo'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // Meu Perfil
                        const PopupMenuItem<String>(
                          value: 'perfil',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.purple,
                              ),
                              SizedBox(width: 12),
                              Text('Meu Perfil'),
                            ],
                          ),
                        ),
                        // Sobre o Sistema
                        const PopupMenuItem<String>(
                          value: 'sobre',
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 12),
                              Text('Sobre o Sistema'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // Sair
                        PopupMenuItem<String>(
                          value: 'sair',
                          child: Row(
                            children: [
                              Icon(
                                Icons.exit_to_app,
                                size: 20,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 12),
                              const Text('Sair do Sistema'),
                            ],
                          ),
                        ),
                      ],
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Perfil do Usuário'),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
}
