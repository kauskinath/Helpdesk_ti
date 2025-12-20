import 'package:flutter/material.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../widgets/manutencao_card.dart';
import '../comum/manutencao_detalhes_chamado_screen.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/shared/widgets/base_dashboard_layout.dart';

/// Dashboard do Gerente Manutenção - Aprovação de Orçamentos
class ManutencaoDashboardGerenteScreen extends StatefulWidget {
  const ManutencaoDashboardGerenteScreen({super.key});

  @override
  State<ManutencaoDashboardGerenteScreen> createState() =>
      _ManutencaoDashboardGerenteScreenState();
}

class _ManutencaoDashboardGerenteScreenState
    extends State<ManutencaoDashboardGerenteScreen> {
  final _manutencaoService = ManutencaoService();
  final _authService = AuthService();

  StatusChamadoManutencao? _filtroStatus;
  String _buscaTexto = '';

  @override
  Widget build(BuildContext context) {
    return BaseDashboardLayout(
      title: '',
      titleEmoji: '',
      primaryColor: Colors.teal,
      showHeader:
          false, // Desabilita header completo (já existe no gerente_dashboard)
      menuCategories: [
        MenuCategory(
          title: 'BUSCA',
          icon: Icons.search,
          color: Colors.blue.shade700,
          items: [
            MenuItem(
              emoji: '🔍',
              icon: Icons.filter_alt,
              label: 'Filtrar Status',
              value: 'filtrar_status',
              onTap: (context) => _mostrarDialogFiltroStatus(),
            ),
            MenuItem(
              emoji: '❌',
              icon: Icons.clear_all,
              label: 'Limpar Filtros',
              value: 'limpar_filtros',
              onTap: (context) {
                setState(() {
                  _filtroStatus = null;
                  _buscaTexto = '';
                });
              },
            ),
          ],
        ),
        MenuCategory(
          title: 'ORÇAMENTOS',
          icon: Icons.attach_money,
          color: Colors.teal.shade700,
          items: [
            MenuItem(
              emoji: '⏳',
              icon: Icons.pending_actions,
              label: 'Pendentes',
              value: 'pendentes',
              onTap: (context) {
                setState(() {
                  _filtroStatus =
                      StatusChamadoManutencao.aguardandoAprovacaoGerente;
                });
              },
            ),
            MenuItem(
              emoji: '✅',
              icon: Icons.check_circle,
              label: 'Aprovados',
              value: 'aprovados',
              onTap: (context) {
                setState(() {
                  _filtroStatus = StatusChamadoManutencao.liberadoParaExecucao;
                });
              },
            ),
            MenuItem(
              emoji: '❌',
              icon: Icons.cancel,
              label: 'Rejeitados',
              value: 'rejeitados',
              onTap: (context) {
                setState(() {
                  _filtroStatus = StatusChamadoManutencao.orcamentoRejeitado;
                });
              },
            ),
          ],
        ),
        MenuCategory(
          title: 'CONFIGURAÇÕES',
          icon: Icons.settings,
          color: Colors.grey.shade700,
          items: [
            MenuItem(
              emoji: '🚪',
              icon: Icons.logout,
              label: 'Sair',
              value: 'sair',
              onTap: (ctx) async {
                await _authService.logout();
                if (mounted && ctx.mounted) {
                  Navigator.pushReplacementNamed(ctx, '/login');
                }
              },
            ),
          ],
        ),
      ],
      body: Column(
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
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
              stream: _manutencaoService.getChamadosParaGerente(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                          'Erro ao carregar orçamentos',
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
                    return c.titulo.toLowerCase().contains(_buscaTexto) ||
                        c.descricao.toLowerCase().contains(_buscaTexto);
                  }).toList();
                }

                if (chamados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Colors.grey.shade400,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum orçamento encontrado',
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
}
