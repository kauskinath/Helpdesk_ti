import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';

/// Tela de relatórios e estatísticas
class WebRelatoriosScreen extends StatefulWidget {
  const WebRelatoriosScreen({super.key});

  @override
  State<WebRelatoriosScreen> createState() => _WebRelatoriosScreenState();
}

class _WebRelatoriosScreenState extends State<WebRelatoriosScreen> {
  String _periodoSelecionado = 'Últimos 30 dias';

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      // Fundo limpo para web
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da página
            Text(
              'Relatórios e Estatísticas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Filtro de período
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Período:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.greyLight,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _periodoSelecionado,
                        items:
                            [
                              'Últimos 7 dias',
                              'Últimos 30 dias',
                              'Últimos 90 dias',
                              'Este ano',
                              'Todo o período',
                            ].map((periodo) {
                              return DropdownMenuItem(
                                value: periodo,
                                child: Text(periodo),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _periodoSelecionado = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exportação em desenvolvimento'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Estatísticas principais
            StreamBuilder<List<Chamado>>(
              stream: firestoreService.getChamadosAtivosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final chamados = snapshot.data ?? [];
                final now = DateTime.now();

                // Filtrar por período
                List<Chamado> chamadosFiltrados = _filtrarPorPeriodo(
                  chamados,
                  now,
                );

                // Calcular estatísticas
                final stats = _calcularEstatisticas(chamadosFiltrados);

                return Column(
                  children: [
                    // Cards principais
                    Row(
                      children: [
                        _buildMainStatCard(
                          'Total de Chamados',
                          stats['total'].toString(),
                          Icons.confirmation_number,
                          AppColors.primary,
                          'No período selecionado',
                        ),
                        const SizedBox(width: 16),
                        _buildMainStatCard(
                          'Taxa de Resolução',
                          '${stats['taxaResolucao']}%',
                          Icons.check_circle,
                          AppColors.statusClosed,
                          'Chamados resolvidos',
                        ),
                        const SizedBox(width: 16),
                        _buildMainStatCard(
                          'Tempo Médio',
                          '${stats['tempoMedio']}h',
                          Icons.timer,
                          AppColors.warning,
                          'Para resolução',
                        ),
                        const SizedBox(width: 16),
                        _buildMainStatCard(
                          'Chamados Pendentes',
                          stats['pendentes'].toString(),
                          Icons.pending,
                          AppColors.statusOpen,
                          'Aguardando atendimento',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Gráficos
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distribuição por Status
                        Expanded(
                          child: _buildChartCard(
                            'Distribuição por Status',
                            _buildStatusChart(chamadosFiltrados),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Distribuição por Prioridade
                        Expanded(
                          child: _buildChartCard(
                            'Distribuição por Prioridade',
                            _buildPriorityChart(chamadosFiltrados),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Chamados por Departamento
                    _buildChartCard(
                      'Chamados por Departamento',
                      _buildDepartmentTable(chamadosFiltrados),
                    ),
                    const SizedBox(height: 24),

                    // Atividade Recente
                    _buildChartCard(
                      'Resumo de Atividades',
                      _buildActivitySummary(chamadosFiltrados),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Chamado> _filtrarPorPeriodo(List<Chamado> chamados, DateTime now) {
    int dias;
    switch (_periodoSelecionado) {
      case 'Últimos 7 dias':
        dias = 7;
        break;
      case 'Últimos 30 dias':
        dias = 30;
        break;
      case 'Últimos 90 dias':
        dias = 90;
        break;
      case 'Este ano':
        dias = now.difference(DateTime(now.year, 1, 1)).inDays;
        break;
      default:
        return chamados; // Todo o período
    }

    final dataLimite = now.subtract(Duration(days: dias));
    return chamados.where((c) => c.dataCriacao.isAfter(dataLimite)).toList();
  }

  Map<String, dynamic> _calcularEstatisticas(List<Chamado> chamados) {
    final total = chamados.length;
    final fechados = chamados.where((c) => c.status == 'Fechado').length;
    final pendentes = chamados.where((c) => c.status == 'Aberto').length;
    final taxaResolucao = total > 0 ? ((fechados / total) * 100).round() : 0;

    // Calcular tempo médio de resolução (simplificado)
    final tempoMedio = 24; // Placeholder - implementar cálculo real

    return {
      'total': total,
      'fechados': fechados,
      'pendentes': pendentes,
      'taxaResolucao': taxaResolucao,
      'tempoMedio': tempoMedio,
    };
  }

  Widget _buildMainStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                const Icon(
                  Icons.trending_up,
                  color: AppColors.success,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildStatusChart(List<Chamado> chamados) {
    final statusCount = {
      'Aberto': chamados.where((c) => c.status == 'Aberto').length,
      'Em Andamento': chamados.where((c) => c.status == 'Em Andamento').length,
      'Fechado': chamados.where((c) => c.status == 'Fechado').length,
    };

    final total = chamados.length;

    return Column(
      children: statusCount.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        Color color;
        switch (entry.key) {
          case 'Aberto':
            color = AppColors.statusOpen;
            break;
          case 'Em Andamento':
            color = AppColors.statusInProgress;
            break;
          case 'Fechado':
            color = AppColors.statusClosed;
            break;
          default:
            color = AppColors.grey;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppColors.greyLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriorityChart(List<Chamado> chamados) {
    final priorityLabels = ['Baixa', 'Média', 'Alta', 'Crítica'];
    final priorityColors = [
      AppColors.statusOpen,
      AppColors.statusInProgress,
      AppColors.warning,
      AppColors.error,
    ];

    final total = chamados.length;

    return Column(
      children: List.generate(4, (index) {
        final count = chamados.where((c) => c.prioridade == index + 1).length;
        final percentage = total > 0 ? (count / total * 100) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: priorityColors[index],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        priorityLabels[index],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppColors.greyLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    priorityColors[index],
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDepartmentTable(List<Chamado> chamados) {
    // Agrupar por departamento (usando usuarioNome como proxy)
    final departmentMap = <String, int>{};
    for (final chamado in chamados) {
      final dept = chamado.usuarioNome.split(' ').first; // Simplificação
      departmentMap[dept] = (departmentMap[dept] ?? 0) + 1;
    }

    final sortedDepts = departmentMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topDepts = sortedDepts.take(5).toList();

    if (topDepts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum dado disponível'),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        AppColors.primary.withValues(alpha: 0.1),
      ),
      columns: const [
        DataColumn(
          label: Text('Usuário', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Chamados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Proporção',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: topDepts.map((entry) {
        final percentage = chamados.isNotEmpty
            ? (entry.value / chamados.length * 100)
            : 0.0;
        return DataRow(
          cells: [
            DataCell(Text(entry.key)),
            DataCell(Text(entry.value.toString())),
            DataCell(
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.greyLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${percentage.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActivitySummary(List<Chamado> chamados) {
    final now = DateTime.now();
    final hoje = chamados.where((c) {
      final diff = now.difference(c.dataCriacao);
      return diff.inDays == 0;
    }).length;

    final semana = chamados.where((c) {
      final diff = now.difference(c.dataCriacao);
      return diff.inDays <= 7;
    }).length;

    final resolvidosHoje = chamados.where((c) {
      return c.status == 'Fechado' &&
          c.dataFechamento != null &&
          now.difference(c.dataFechamento!).inDays == 0;
    }).length;

    return Row(
      children: [
        _buildActivityItem(
          Icons.add_circle,
          'Criados Hoje',
          hoje.toString(),
          AppColors.primary,
        ),
        const SizedBox(width: 24),
        _buildActivityItem(
          Icons.calendar_view_week,
          'Esta Semana',
          semana.toString(),
          AppColors.statusInProgress,
        ),
        const SizedBox(width: 24),
        _buildActivityItem(
          Icons.check_circle,
          'Resolvidos Hoje',
          resolvidosHoje.toString(),
          AppColors.success,
        ),
        const SizedBox(width: 24),
        _buildActivityItem(
          Icons.pending,
          'Em Aberto',
          chamados.where((c) => c.status == 'Aberto').length.toString(),
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
