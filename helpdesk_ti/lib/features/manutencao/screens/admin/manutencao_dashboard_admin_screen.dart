import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../widgets/manutencao_card.dart';
import '../comum/manutencao_detalhes_chamado_screen.dart';
import '../comum/manutencao_advanced_search_screen.dart';
import 'manutencao_criar_chamado_admin_screen.dart';
import 'manutencao_dashboard_stats_screen.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';

/// Dashboard do Admin Manutenção - Visual Profissional
class ManutencaoDashboardAdminScreen extends StatefulWidget {
  const ManutencaoDashboardAdminScreen({super.key});

  @override
  State<ManutencaoDashboardAdminScreen> createState() =>
      _ManutencaoDashboardAdminScreenState();
}

class _ManutencaoDashboardAdminScreenState
    extends State<ManutencaoDashboardAdminScreen> {
  final _manutencaoService = ManutencaoService();

  StatusChamadoManutencao? _filtroStatus;
  String _buscaTexto = '';

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userName = authService.userName ?? 'Admin';
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
                              color: isDarkMode ? Colors.white : Colors.black87,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: isDarkMode
                                      ? Colors.black.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '👷 Manutenção',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: isDarkMode
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.7),
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
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: isDarkMode ? Colors.white : Colors.black87,
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
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      offset: const Offset(0, 50),
                      onSelected: (String value) {
                        switch (value) {
                          case 'busca_avancada':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManutencaoAdvancedSearchScreen(),
                              ),
                            );
                            break;
                          case 'filtrar_status':
                            _mostrarDialogFiltroStatus();
                            break;
                          case 'limpar_filtros':
                            setState(() {
                              _filtroStatus = null;
                              _buscaTexto = '';
                            });
                            break;
                          case 'estatisticas':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManutencaoDashboardStatsScreen(),
                              ),
                            );
                            break;
                          case 'criar_chamado':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManutencaoCriarChamadoAdminScreen(),
                              ),
                            );
                            break;
                          case 'perfil':
                            _mostrarPerfil(context, userName);
                            break;
                          case 'sair':
                            authService.logout();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'busca_avancada',
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 12),
                              const Text('Busca Avançada'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'filtrar_status',
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                size: 20,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 12),
                              const Text('Filtrar Status'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'limpar_filtros',
                          child: Row(
                            children: [
                              Icon(
                                Icons.clear_all,
                                size: 20,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 12),
                              const Text('Limpar Filtros'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'estatisticas',
                          child: Row(
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 20,
                                color: Colors.teal[700],
                              ),
                              const SizedBox(width: 12),
                              const Text('Estatísticas'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'criar_chamado',
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle,
                                size: 20,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 12),
                              const Text('Criar Chamado'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
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
                              const Text('Sair'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Conteúdo: Lista de chamados
              Expanded(
                child: Column(
                  children: [
                    // Card de informação sobre filtro ativo
                    if (_filtroStatus != null)
                      Container(
                        margin: const EdgeInsets.all(12.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt, color: Colors.teal.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Filtrando por: ${_filtroStatus!.label}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() => _filtroStatus = null);
                              },
                            ),
                          ],
                        ),
                      ),

                    // Lista de chamados
                    Expanded(
                      child: StreamBuilder<List<ChamadoManutencao>>(
                        stream: _manutencaoService
                            .getChamadosParaAdminManutencao(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Erro ao carregar chamados',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          var chamados = snapshot.data ?? [];

                          // Aplicar filtros
                          if (_filtroStatus != null) {
                            chamados = chamados
                                .where((c) => c.status == _filtroStatus)
                                .toList();
                          }

                          if (_buscaTexto.isNotEmpty) {
                            chamados = chamados.where((c) {
                              return c.titulo.toLowerCase().contains(
                                    _buscaTexto,
                                  ) ||
                                  c.descricao.toLowerCase().contains(
                                    _buscaTexto,
                                  );
                            }).toList();
                          }

                          if (chamados.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.construction,
                                    color: Colors.grey.shade400,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhum chamado encontrado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            itemCount: chamados.length,
                            itemBuilder: (context, index) {
                              final chamado = chamados[index];
                              return ManutencaoCard(
                                chamado: chamado,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ManutencaoDetalhesChamadoScreen(
                                            chamadoId: chamado.id,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManutencaoCriarChamadoAdminScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('CRIAR CHAMADO'),
          backgroundColor: Colors.teal,
        ),
      ),
    );
  }

  void _mostrarDialogFiltroStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Filtrar por Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('Todos os status'),
                onTap: () {
                  setState(() => _filtroStatus = null);
                  Navigator.pop(context);
                },
              ),
              ...StatusChamadoManutencao.values.map((status) {
                return ListTile(
                  leading: Text(status.emoji),
                  title: Text(status.label),
                  onTap: () {
                    setState(() => _filtroStatus = status);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarPerfil(BuildContext context, String userName) {
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
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF009688)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👷', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '👷 ADMIN MANUTENÇÃO',
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
}
