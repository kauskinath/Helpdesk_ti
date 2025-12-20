import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import '../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'dashboard/chamados_por_prioridade_chart.dart';
import 'dashboard/tempo_medio_card.dart';
import 'common/shimmer_loading.dart';

/// Dashboard Tab com estatísticas e visão geral
///
/// Funcionalidades:
/// - Cards de stats por prioridade
/// - Gráfico visual de distribuição
/// - Lista de chamados recentes
/// - Estatísticas gerais (total, abertos, fechados)
class DashboardTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final AuthService authService;

  const DashboardTab({
    super.key,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Mantém estado ao trocar de tab

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Force rebuild
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              '📊 Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Stats por prioridade
            FutureBuilder<Map<String, int>>(
              future: widget.firestoreService.getChamadosPorPrioridade(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: [
                      ShimmerLoading.rectangle(
                        width: double.infinity,
                        height: 160,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(height: 16),
                      ShimmerLoading.statGrid(),
                    ],
                  );
                }

                final stats =
                    snapshot.data ??
                    {'critica': 0, 'alta': 0, 'media': 0, 'baixa': 0};

                final total = stats.values.fold<int>(0, (a, b) => a + b);

                return Column(
                  children: [
                    // Card de total (sem animação para melhor performance)
                    _buildTotalCard(total),
                    const SizedBox(height: 16),

                    // Gráfico de prioridades
                    ChamadosPorPrioridadeChart(
                      contadores: {
                        'Crítica': stats['critica'] ?? 0,
                        'Alta': stats['alta'] ?? 0,
                        'Média': stats['media'] ?? 0,
                        'Baixa': stats['baixa'] ?? 0,
                      },
                    ),
                    const SizedBox(height: 16),

                    // Grid de prioridades
                    FadeInUp(
                      duration: const Duration(milliseconds: 200),
                      child: _buildPriorityGrid(stats),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Card de tempo médio de resolução (novo)
            StreamBuilder<List<Chamado>>(
              stream: widget.firestoreService.getChamadosAtivosStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Filtrar apenas chamados FECHADOS (status correto) e calcular tempos de resolução
                  final chamados = snapshot.data!;
                  final temposResolucao = chamados
                      .where(
                        (c) =>
                            c.status == 'Fechado' && c.dataFechamento != null,
                      )
                      .map(
                        (c) => c.dataFechamento!
                            .difference(c.dataCriacao)
                            .inSeconds,
                      )
                      .toList();

                  return TempoMedioCard(
                    temposResolucaoEmSegundos: temposResolucao,
                    periodo: '30 dias',
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),

            // Chamados recentes
            const Text(
              '📋 Chamados Recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lista de chamados ativos
            StreamBuilder<List<Chamado>>(
              stream: widget.firestoreService.getChamadosAtivosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerLoading.ticketList();
                }

                if (snapshot.hasError) {
                  return _buildErrorCard('Erro ao carregar chamados');
                }

                final chamados = snapshot.data ?? [];

                if (chamados.isEmpty) {
                  return _buildEmptyCard('Nenhum chamado ativo no momento');
                }

                // Mostrar apenas os 10 mais recentes (sem animação para melhor performance)
                final chamadosRecentes = chamados.take(10).toList();

                return Column(
                  children: chamadosRecentes
                      .map((chamado) => _buildChamadoCard(chamado))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.dashboard, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            total.toString(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Chamados Ativos',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityGrid(Map<String, int> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildPriorityCard(
          label: 'Crítica',
          count: stats['critica'] ?? 0,
          color: const Color(0xFFEF5350),
          icon: Icons.priority_high,
        ),
        _buildPriorityCard(
          label: 'Alta',
          count: stats['alta'] ?? 0,
          color: const Color(0xFFFF9800),
          icon: Icons.arrow_upward,
        ),
        _buildPriorityCard(
          label: 'Média',
          count: stats['media'] ?? 0,
          color: const Color(0xFF42A5F5),
          icon: Icons.remove,
        ),
        _buildPriorityCard(
          label: 'Baixa',
          count: stats['baixa'] ?? 0,
          color: const Color(0xFF66BB6A),
          icon: Icons.arrow_downward,
        ),
      ],
    );
  }

  Widget _buildPriorityCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamadoCard(Chamado chamado) {
    Color statusColor;
    switch (chamado.status) {
      case 'Aberto':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Em Andamento':
        statusColor = const Color(0xFF2196F3);
        break;
      case 'Aguardando':
        statusColor = const Color(0xFF9C27B0);
        break;
      default:
        statusColor = Colors.grey;
    }

    Color priorityColor;
    switch (chamado.prioridade) {
      case 4:
        priorityColor = const Color(0xFFEF5350);
        break;
      case 3:
        priorityColor = const Color(0xFFFF9800);
        break;
      case 2:
        priorityColor = const Color(0xFF42A5F5);
        break;
      default:
        priorityColor = const Color(0xFF66BB6A);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge de prioridade
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${chamado.numero.toString().padLeft(4, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withValues(alpha: 0.15),
                            statusColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        chamado.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  chamado.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        chamado.usuarioNome,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ícone de prioridade
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.flag, color: priorityColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



