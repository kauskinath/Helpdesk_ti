import 'package:flutter/material.dart';

/// Widget que exibe gráfico de barras horizontal para chamados por prioridade
///
/// Mostra quantidades de:
/// - Crítica (vermelho)
/// - Alta (laranja)
/// - Média (azul)
/// - Baixa (verde)
class ChamadosPorPrioridadeChart extends StatelessWidget {
  final Map<String, int> contadores;

  const ChamadosPorPrioridadeChart({super.key, required this.contadores});

  Color _getPriorityColor(String prioridade) {
    switch (prioridade.toLowerCase()) {
      case 'crítica':
      case 'critica':
        return const Color(0xFFEF5350);
      case 'alta':
        return const Color(0xFFFF9800);
      case 'média':
      case 'media':
        return const Color(0xFF42A5F5);
      case 'baixa':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String prioridade) {
    switch (prioridade.toLowerCase()) {
      case 'crítica':
      case 'critica':
        return Icons.warning;
      case 'alta':
        return Icons.priority_high;
      case 'média':
      case 'media':
        return Icons.adjust;
      case 'baixa':
        return Icons.arrow_downward;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = contadores.values.fold<int>(0, (sum, count) => sum + count);

    if (total == 0) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Nenhum chamado ativo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final prioridades = ['Crítica', 'Alta', 'Média', 'Baixa'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Por Prioridade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Distribuição de chamados ativos',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...prioridades.map((prioridade) {
              final count = contadores[prioridade] ?? 0;
              final percentage = total > 0 ? (count / total * 100) : 0.0;
              final color = _getPriorityColor(prioridade);
              final icon = _getPriorityIcon(prioridade);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prioridade,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
