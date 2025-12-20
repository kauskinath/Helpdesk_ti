import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import '../models/chamado_manutencao_model.dart';
import '../models/manutencao_enums.dart';

/// Card padronizado para chamados de Manutenção
///
/// Segue o mesmo visual do TicketCard do TI:
/// - Tema adaptável (claro/escuro)
/// - Bordas coloridas baseadas no status
/// - Layout consistente
/// - Gradientes sutis
class ManutencaoCard extends StatelessWidget {
  final ChamadoManutencao chamado;
  final VoidCallback onTap;

  const ManutencaoCard({super.key, required this.chamado, required this.onTap});

  Color _getStatusColor() {
    switch (chamado.status) {
      case StatusChamadoManutencao.aberto:
      case StatusChamadoManutencao.emValidacaoAdmin:
        return const Color(0xFF2196F3); // Azul
      case StatusChamadoManutencao.aguardandoAprovacaoGerente:
        return const Color(0xFFFF9800); // Laranja
      case StatusChamadoManutencao.orcamentoAprovado:
      case StatusChamadoManutencao.liberadoParaExecucao:
        return const Color(0xFF4CAF50); // Verde
      case StatusChamadoManutencao.orcamentoRejeitado:
      case StatusChamadoManutencao.cancelado:
      case StatusChamadoManutencao.recusadoExecutor:
        return const Color(0xFFF44336); // Vermelho
      case StatusChamadoManutencao.emCompra:
      case StatusChamadoManutencao.aguardandoMateriais:
        return const Color(0xFF9C27B0); // Roxo
      case StatusChamadoManutencao.atribuidoExecutor:
      case StatusChamadoManutencao.emExecucao:
        return const Color(0xFF00BCD4); // Ciano
      case StatusChamadoManutencao.finalizado:
        return const Color(0xFF66BB6A); // Verde claro
    }
  }

  String _getStatusLabel() {
    return chamado.status.label;
  }

  IconData _getStatusIcon() {
    switch (chamado.status) {
      case StatusChamadoManutencao.aberto:
        return Icons.new_releases;
      case StatusChamadoManutencao.emValidacaoAdmin:
        return Icons.fact_check;
      case StatusChamadoManutencao.aguardandoAprovacaoGerente:
        return Icons.pending_actions;
      case StatusChamadoManutencao.orcamentoAprovado:
      case StatusChamadoManutencao.liberadoParaExecucao:
        return Icons.check_circle;
      case StatusChamadoManutencao.orcamentoRejeitado:
      case StatusChamadoManutencao.recusadoExecutor:
      case StatusChamadoManutencao.cancelado:
        return Icons.cancel;
      case StatusChamadoManutencao.emCompra:
        return Icons.shopping_cart;
      case StatusChamadoManutencao.aguardandoMateriais:
        return Icons.inventory_2;
      case StatusChamadoManutencao.atribuidoExecutor:
        return Icons.person_add;
      case StatusChamadoManutencao.emExecucao:
        return Icons.construction;
      case StatusChamadoManutencao.finalizado:
        return Icons.done_all;
    }
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yy HH:mm').format(data);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final statusColor = _getStatusColor();

    // Cores adaptáveis ao tema
    final cardColor = isDark
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.95);

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black54;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isDark ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 3),
      ),
      color: cardColor,
      shadowColor: statusColor.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withValues(alpha: 0.05),
                statusColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com título e status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone de status
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Título
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID do chamado
                          Text(
                            chamado.numeroFormatado,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Título
                          Text(
                            chamado.titulo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Badge de status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Descrição (preview)
                if (chamado.descricao.isNotEmpty) ...[
                  Text(
                    chamado.descricao,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                // Rodapé com info
                Row(
                  children: [
                    // Usuário
                    Icon(Icons.person_outline, size: 16, color: subtitleColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        chamado.criadorNome,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Data
                    Icon(Icons.access_time, size: 16, color: subtitleColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatarData(chamado.dataAbertura),
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Orçamento (se houver)
                if (chamado.orcamento?.valorEstimado != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'R\$ ${chamado.orcamento!.valorEstimado!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
