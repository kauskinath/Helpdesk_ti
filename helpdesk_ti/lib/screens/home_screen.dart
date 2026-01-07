import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import '../data/firestore_service.dart';
import '../core/permissions/permission_provider.dart';
import '../features/manutencao/screens/comum/manutencao_criar_chamado_screen.dart';
import 'tabs/meus_chamados_tab.dart';
import 'tabs/fila_tecnica_tab.dart';
import 'tabs/aprovar_solicitacoes_tab.dart';
import 'historico_chamados_screen.dart';
import 'search/advanced_search_screen.dart';
import 'dashboard/dashboard_screen.dart';

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
    // Admin e TI veem Fila Técnica, usuários comuns veem Meus Chamados
    // Admin vê ambos para poder criar chamados também
    final bool isAdmin = permissions.roleDisplayName.toLowerCase().contains(
      'admin',
    );
    final showMeusChamados = !showFilaTecnicaTab || isAdmin;

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
                            'Olá, ${userName ?? 'Usuário'}!',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: DS.textPrimary,
                            ),
                          ),
                          Text(
                            permissions.roleDisplayName,
                            style: const TextStyle(
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
                        itemBuilder: (context) => [
                          // Gerenciar Usuários (apenas admin)
                          if (authService.isAdmin)
                            const PopupMenuItem(
                              value: 'usuarios',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 20,
                                    color: DS.action,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Gerenciar Usuários'),
                                ],
                              ),
                            ),
                          // Busca Avançada
                          const PopupMenuItem(
                            value: 'busca',
                            child: Row(
                              children: [
                                Icon(Icons.search, size: 20, color: DS.info),
                                SizedBox(width: 12),
                                Text('Busca Avançada'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          // Meu Perfil
                          const PopupMenuItem(
                            value: 'perfil',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 20, color: DS.action),
                                SizedBox(width: 12),
                                Text('Meu Perfil'),
                              ],
                            ),
                          ),
                          // Sair
                          const PopupMenuItem(
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

              // Conteúdo das abas
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    // Admin TI: Fila Técnica primeiro
                    if (showFilaTecnicaTab) const FilaTecnicaTab(),
                    // Estatísticas ao lado da Fila Técnica
                    if (showFilaTecnicaTab) const DashboardScreen(),
                    if (showMeusChamados && !showFilaTecnicaTab)
                      const MeusChamadosTab(),
                    if (showAprovarSolicitacoesTab)
                      const AprovarSolicitacoesTab(),
                    if (showAprovarSolicitacoesTab)
                      HistoricoChamadosScreen(
                        firestoreService: context.read<FirestoreService>(),
                        authService: context.read<AuthService>(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ), // Fecha SafeArea (body do Scaffold)
        extendBody: true,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: DS.card,
            border: Border(top: BorderSide(color: DS.border, width: 1)),
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
            selectedItemColor: DS.action,
            unselectedItemColor: DS.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 10,
            items: [
              // Admin TI: Fila Técnica primeiro
              if (showFilaTecnicaTab)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.engineering),
                  label: 'Fila Técnica',
                ),
              // Estatísticas ao lado da Fila Técnica
              if (showFilaTecnicaTab)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Estatísticas',
                ),
              if (showMeusChamados && !showFilaTecnicaTab)
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
            ],
          ),
        ), // Fecha BottomNavigationBar Container
        floatingActionButton: (_selectedTabIndex == 0 && showMeusChamados)
            ? Container(
                decoration: BoxDecoration(
                  color: DS.action,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FloatingActionButton.extended(
                  heroTag: 'home_new_ticket_fab',
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
              )
            : null,
      ), // Fecha Scaffold
    ); // Fecha Container (wallpaper)
  }

  void _onMenuSelected(
    BuildContext context,
    String value,
    AuthService authService,
  ) {
    switch (value) {
      case 'usuarios':
        Navigator.of(context).pushNamed('/admin');
        break;
      case 'dashboard':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 'busca':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdvancedSearchScreen(
              firestoreService: context.read<FirestoreService>(),
              authService: context.read<AuthService>(),
            ),
          ),
        );
        break;
      case 'filtrar':
        // TODO: Implementar filtro de status
        break;
      case 'limpar_filtros':
        // TODO: Implementar limpar filtros
        break;
      case 'estatisticas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 'criar_chamado':
        _mostrarSeletorTipoChamado(context);
        break;
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
                  // Ir direto para criação manual de chamado TI
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
                    color: DS.warning,
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: DS.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exibe o perfil do usuário
  void _mostrarPerfil(BuildContext context, AuthService authService) {
    final userName = authService.userName ?? 'Usuário';
    final permissions = context.permissions;
    final roleDisplay = permissions.roleDisplayName;

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
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, size: 40, color: Colors.white),
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
                color: DS.action.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleDisplay,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: DS.action,
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
