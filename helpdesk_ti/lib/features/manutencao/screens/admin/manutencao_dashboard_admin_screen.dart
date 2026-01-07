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
import 'package:helpdesk_ti/core/theme/design_system.dart';

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
                            '👷 Manutenção',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: DS.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Menu popup (3 pontinhos)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: DS.textPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DS.cardRadius),
                      ),
                      offset: const Offset(0, 50),
                      onSelected: (String value) async {
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
                            await authService.logout();
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
                          color: DS.info.withAlpha(26),
                          borderRadius: BorderRadius.circular(DS.cardRadius),
                          border: Border.all(color: DS.info.withAlpha(77)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_alt, color: DS.info),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Filtrando por: ${_filtroStatus!.label}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  color: DS.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: DS.textSecondary,
                              ),
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
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: DS.error,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Erro ao carregar chamados',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      color: DS.textSecondary,
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
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.construction,
                                    color: DS.textSecondary,
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Nenhum chamado encontrado',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      color: DS.textSecondary,
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
          label: const Text(
            'CRIAR CHAMADO',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: DS.action,
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
        backgroundColor: DS.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.cardRadius),
        ),
        title: const Text(
          'Perfil do Usuário',
          style: TextStyle(fontFamily: 'Inter', color: DS.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: DS.action,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👷', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: DS.action.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '👷 ADMIN MANUTENÇÃO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: DS.action,
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
            child: const Text('Fechar', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }
}
