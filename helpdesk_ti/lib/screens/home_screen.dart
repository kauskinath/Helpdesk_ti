import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../data/firestore_service.dart';
import '../core/permissions/permission_provider.dart';
import 'package:helpdesk_ti/features/ti/models/chamado_template.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import '../features/manutencao/screens/comum/manutencao_criar_chamado_screen.dart';
import 'tabs/meus_chamados_tab.dart';
import 'tabs/fila_tecnica_tab.dart';
import 'tabs/aprovar_solicitacoes_tab.dart';
import 'tabs/user_dashboard_tab.dart';
import 'historico_chamados_screen.dart';
import 'selecionar_template_screen.dart';
import 'search/advanced_search_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Listener de notificações já foi iniciado no login (auth_service.dart)
    // Não precisamos reinicializar aqui para evitar conflitos de permissão
    print('✅ HomeScreen: Iniciado (notificações já ativas)');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userName = authService.userName;

    // Usar o novo sistema de permissões centralizado
    final permissions = context.permissions;

    // Determinar quais abas exibir baseado nas permissões
    final showAprovarSolicitacoesTab = permissions.canViewSolicitacoes;
    final showFilaTecnicaTab = permissions.canViewFilaTecnica;
    final showMeusChamados =
        !showFilaTecnicaTab; // TI não cria chamados, apenas atende

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
                            'Olá, ${userName ?? 'Usuário'}!',
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
                            permissions.roleDisplayName,
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
                    // Menu (3 pontinhos)
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () => _mostrarMenu(
                          context,
                          userName,
                          authService,
                          permissions,
                        ),
                        tooltip: 'Menu',
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo das abas
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    if (showMeusChamados) const MeusChamadosTab(),
                    if (showAprovarSolicitacoesTab)
                      const AprovarSolicitacoesTab(),
                    if (showAprovarSolicitacoesTab)
                      HistoricoChamadosScreen(
                        firestoreService: context.read<FirestoreService>(),
                        authService: context.read<AuthService>(),
                      ),
                    if (showFilaTecnicaTab) const FilaTecnicaTab(),
                    // Dashboard para todos os perfis
                    if (showMeusChamados)
                      const UserDashboardTab()
                    else
                      const DashboardScreen(),
                  ],
                ),
              ),
            ],
          ),
        ), // Fecha SafeArea (body do Scaffold)
        extendBody: true,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedTabIndex,
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedFontSize: 12,
            unselectedFontSize: 10,
            items: [
              if (showMeusChamados)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt),
                  label: 'Chamados',
                ),
              if (showAprovarSolicitacoesTab)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Solicitações',
                ),
              if (showAprovarSolicitacoesTab)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Histórico',
                ),
              if (showFilaTecnicaTab)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.engineering),
                  label: 'Fila Técnica',
                ),
              // Dashboard para todos os perfis
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
            ],
          ),
        ), // Fecha BottomNavigationBar Container
        floatingActionButton: (_selectedTabIndex == 0 && showMeusChamados)
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6F00).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  heroTag: 'home_new_ticket_fab',
                  onPressed: () => _mostrarSeletorTipoChamado(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text(
                    'Novo Chamado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            : null,
      ), // Fecha Scaffold
    ); // Fecha Container (wallpaper)
  }

  void _mostrarMenu(
    BuildContext context,
    String? userName,
    AuthService authService,
    dynamic permissions,
  ) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // GERENCIAMENTO (apenas admins)
              if (authService.isAdmin) ...[
                _buildMenuItem(
                  context: bottomSheetContext,
                  icon: Icons.people,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Gerenciar Usuários',
                  subtitle: 'Adicionar e editar usuários',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.of(context).pushNamed('/admin');
                  },
                ),
                _buildMenuItem(
                  context: bottomSheetContext,
                  icon: Icons.description,
                  iconColor: const Color(0xFFFF9800),
                  title: 'Gerenciar Templates',
                  subtitle: 'Criar e editar templates',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.of(context).pushNamed('/templates');
                  },
                ),
                const Divider(height: 1, indent: 72),
              ],

              // RELATÓRIOS (admins/TI)
              if (permissions.isAdministrative) ...[
                _buildMenuItem(
                  context: bottomSheetContext,
                  icon: Icons.analytics,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Dashboard Completo',
                  subtitle: 'Estatísticas e relatórios',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 72),
              ],

              // FERRAMENTAS
              _buildMenuItem(
                context: bottomSheetContext,
                icon: Icons.search,
                iconColor: const Color(0xFF009688),
                title: 'Busca Avançada',
                subtitle: 'Pesquisar chamados',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdvancedSearchScreen(
                        firestoreService: context.read<FirestoreService>(),
                        authService: context.read<AuthService>(),
                      ),
                    ),
                  );
                },
              ),

              const Divider(height: 1, indent: 72),

              // Meu Perfil
              _buildMenuItem(
                context: bottomSheetContext,
                icon: Icons.person,
                iconColor: const Color(0xFF9C27B0),
                title: 'Meu Perfil',
                subtitle: 'Ver informações do perfil',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  // Chamar o dialog de perfil (código já existe na classe)
                },
              ),

              // Sobre o Sistema
              _buildMenuItem(
                context: bottomSheetContext,
                icon: Icons.info_outline,
                iconColor: const Color(0xFF2196F3),
                title: 'Sobre o Sistema',
                subtitle: 'Informações do aplicativo',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),

              const Divider(height: 1, indent: 72),

              // Sair do Sistema
              _buildMenuItem(
                context: bottomSheetContext,
                icon: Icons.exit_to_app,
                iconColor: const Color(0xFFF44336),
                title: 'Sair do Sistema',
                subtitle: 'Encerrar sessão',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  authService.logout();
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarSeletorTipoChamado(BuildContext context) async {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              const Text(
                '🎯 Qual tipo de chamado?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione o departamento responsável',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Opção TI
              InkWell(
                onTap: () async {
                  Navigator.pop(dialogContext);
                  // Abrir seletor de templates de TI
                  final firestoreService = FirestoreService();
                  final template = await Navigator.push<ChamadoTemplate>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelecionarTemplateScreen(
                        firestoreService: firestoreService,
                      ),
                    ),
                  );

                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamed('/new_ticket', arguments: template);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.computer, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'TI - Suporte Técnico',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hardware, Software, Rede',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
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
                  // Abrir tela de criar chamado de manutenção
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.build, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Manutenção - Infraestrutura',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Reparos, Instalações, Serviços',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão Cancelar
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
