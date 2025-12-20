import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';

class TicketCard extends StatelessWidget {
  final String? numeroFormatado;
  final String titulo;
  final String tipo;
  final String status;
  final DateTime dataCriacao;
  final String usuarioNome;
  final int prioridade;
  final VoidCallback? onTap;
  const TicketCard({
    super.key,
    this.numeroFormatado,
    required this.titulo,
    required this.tipo,
    required this.status,
    required this.dataCriacao,
    required this.usuarioNome,
    required this.prioridade,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Aberto':
        return const Color(0xFF4CAF50);
      case 'Em Andamento':
        return const Color(0xFF2196F3);
      case 'Pendente Aprovação':
        return const Color(0xFFFFA726);
      case 'Aguardando':
        return const Color(0xFF9C27B0);
      case 'Fechado':
        return const Color(0xFF9E9E9E);
      case 'Rejeitado':
        return const Color(0xFFEF5350);
      default:
        return AppColors.grey;
    }
  }

  String _getPriorityLabel() {
    switch (prioridade) {
      case 1:
        return 'Baixa';
      case 2:
        return 'Média';
      case 3:
        return 'Alta';
      case 4:
        return 'CRÍTICA';
      default:
        return 'Normal';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(minHeight: 120),
      child: Card(
        elevation: 4,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getStatusColor(), width: 3),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor().withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número do chamado
                  if (numeroFormatado != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        numeroFormatado!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  // Título
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor().withValues(alpha: 0.2),
                              _getStatusColor().withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          'Prioridade: ${_getPriorityLabel()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Informações
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          usuarioNome,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 18),
                      const SizedBox(width: 4),
                      Text(tipo, style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(dataCriacao),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

