import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/utils/date_formatter.dart';

/// Card que exibe o tempo médio de resolução de chamados
///
/// Calcula e exibe:
/// - Tempo médio de resolução (horas/dias)
/// - Tendência (melhor/pior que período anterior)
/// - Gráfico visual de progresso
class TempoMedioCard extends StatelessWidget {
  final List<int> temposResolucaoEmSegundos;
  final String periodo;

  const TempoMedioCard({
    super.key,
    required this.temposResolucaoEmSegundos,
    this.periodo = '30 dias',
  });

  String _calcularTempoMedio() {
    if (temposResolucaoEmSegundos.isEmpty) return 'N/A';

    return DateFormatter.formatAverageResolutionTime(temposResolucaoEmSegundos);
  }

  Color _getTempoMedioColor() {
    if (temposResolucaoEmSegundos.isEmpty) return Colors.grey;

    final sum = temposResolucaoEmSegundos.reduce((a, b) => a + b);
    final average = sum / temposResolucaoEmSegundos.length;
    final averageInHours = average / 3600;

    // Verde: < 4 horas
    if (averageInHours < 4) return const Color(0xFF66BB6A);

    // Azul: 4-8 horas
    if (averageInHours < 8) return const Color(0xFF42A5F5);

    // Laranja: 8-24 horas
    if (averageInHours < 24) return const Color(0xFFFF9800);

    // Vermelho: > 24 horas
    return const Color(0xFFEF5350);
  }

  String _getDesempenho() {
    if (temposResolucaoEmSegundos.isEmpty) return 'Sem dados';

    final sum = temposResolucaoEmSegundos.reduce((a, b) => a + b);
    final average = sum / temposResolucaoEmSegundos.length;
    final averageInHours = average / 3600;

    if (averageInHours < 4) return 'Excelente';
    if (averageInHours < 8) return 'Bom';
    if (averageInHours < 24) return 'Regular';
    return 'Precisa melhorar';
  }

  IconData _getDesempenhoIcon() {
    if (temposResolucaoEmSegundos.isEmpty) return Icons.help_outline;

    final sum = temposResolucaoEmSegundos.reduce((a, b) => a + b);
    final average = sum / temposResolucaoEmSegundos.length;
    final averageInHours = average / 3600;

    if (averageInHours < 4) return Icons.star;
    if (averageInHours < 8) return Icons.thumb_up;
    if (averageInHours < 24) return Icons.trending_flat;
    return Icons.trending_down;
  }

  @override
  Widget build(BuildContext context) {
    final tempoMedio = _calcularTempoMedio();
    final color = _getTempoMedioColor();
    final desempenho = _getDesempenho();
    final icon = _getDesempenhoIcon();
    final totalChamados = temposResolucaoEmSegundos.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.1), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.timer, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tempo Médio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Resolução de chamados',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tempo médio (grande)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tempoMedio,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          desempenho,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Text(
                          'nos últimos $periodo',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Informações adicionais
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        totalChamados > 0
                            ? 'Baseado em $totalChamados chamados resolvidos'
                            : 'Nenhum chamado resolvido neste período',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Legenda de cores
              if (totalChamados > 0) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      'Excelente',
                      const Color(0xFF66BB6A),
                      '< 4h',
                    ),
                    _buildLegendItem('Bom', const Color(0xFF42A5F5), '4-8h'),
                    _buildLegendItem(
                      'Regular',
                      const Color(0xFFFF9800),
                      '8-24h',
                    ),
                    _buildLegendItem('Lento', const Color(0xFFEF5350), '> 24h'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}
