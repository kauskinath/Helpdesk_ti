import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/utils/date_formatter.dart';

/// TicketCard Otimizado - Versão 2.0
///
/// Melhorias:
/// - Design mais limpo e moderno
/// - Menos informações redundantes
/// - Badges visuais de prioridade
/// - Contadores de comentários e anexos
/// - Performance otimizada (150ms animations)
/// - Datas relativas ("Agora", "5min", "2h", "Hoje 14:30")
class TicketCardV2 extends StatelessWidget {
  final String? numeroFormatado;
  final String titulo;
  final String status;
  final int prioridade;
  final String? usuarioNome;
  final DateTime? lastUpdated;
  final int numeroComentarios;
  final bool temAnexos;
  final VoidCallback? onTap;

  const TicketCardV2({
    super.key,
    this.numeroFormatado,
    required this.titulo,
    required this.status,
    required this.prioridade,
    this.usuarioNome,
    this.lastUpdated,
    this.numeroComentarios = 0,
    this.temAnexos = false,
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

  Color _getPriorityColor() {
    switch (prioridade) {
      case 4:
        return const Color(0xFFEF5350); // Crítica - Vermelho
      case 3:
        return const Color(0xFFFF9800); // Alta - Laranja
      case 2:
        return const Color(0xFF42A5F5); // Média - Azul
      case 1:
        return const Color(0xFF66BB6A); // Baixa - Verde
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel() {
    switch (prioridade) {
      case 4:
        return 'CRÍTICA';
      case 3:
        return 'Alta';
      case 2:
        return 'Média';
      case 1:
        return 'Baixa';
      default:
        return 'Normal';
    }
  }

  String _getTimeAgo() {
    if (lastUpdated == null) return '';
    return DateFormatter.formatRelative(lastUpdated!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: _getPriorityColor(), width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Número + Status
                Row(
                  children: [
                    // Número do chamado
                    if (numeroFormatado != null) ...[
                      Text(
                        numeroFormatado!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor().withValues(alpha: 0.2),
                            _getStatusColor().withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Prioridade badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getPriorityColor().withValues(alpha: 0.2),
                            _getPriorityColor().withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getPriorityColor(),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 12,
                            color: _getPriorityColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPriorityLabel(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Título
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Footer: Usuário + Contadores
                Row(
                  children: [
                    // Usuário
                    if (usuarioNome != null) ...[
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          usuarioNome!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    // Spacer
                    const SizedBox(width: 12),

                    // Contadores e indicadores
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Anexos
                        if (temAnexos) ...[
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Comentários
                        if (numeroComentarios > 0) ...[
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            numeroComentarios.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Tempo desde última atualização
                        if (lastUpdated != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
