import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/features/ti/models/solicitacao.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';

class SolicitacaoCard extends StatelessWidget {
  final Solicitacao solicitacao;
  final VoidCallback? onTap;

  const SolicitacaoCard({super.key, required this.solicitacao, this.onTap});

  Color _getStatusColor() {
    switch (solicitacao.status) {
      case 'Pendente':
        return DS.warning;
      case 'Aprovado':
        return DS.success;
      case 'Reprovado':
        return DS.error;
      default:
        return DS.textSecondary;
    }
  }

  Color _getPriorityColor() {
    switch (solicitacao.prioridade) {
      case 4:
        return DS.error;
      case 3:
        return DS.warning;
      case 2:
        return DS.action;
      default:
        return DS.success;
    }
  }

  String _getPriorityLabel() {
    switch (solicitacao.prioridade) {
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
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(double? value) {
    if (value == null) return 'Não informado';
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: DS.card,
          borderRadius: BorderRadius.circular(DS.cardRadius),
          border: Border.all(color: DS.border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra de prioridade lateral (3px)
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(DS.cardRadius),
                    bottomLeft: Radius.circular(DS.cardRadius),
                  ),
                ),
              ),
              // Conteúdo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Número + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Número
                          Text(
                            solicitacao.numeroFormatado,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: DS.textTertiary,
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              solicitacao.status,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Row 2: Título
                      Text(
                        solicitacao.titulo,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DS.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Row 3: Item + Custo
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            size: 14,
                            color: DS.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              solicitacao.itemSolicitado,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: DS.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(solicitacao.custoEstimado),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DS.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Row 4: Setor + Prioridade Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.business,
                                size: 14,
                                color: DS.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                solicitacao.setor,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: DS.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getPriorityLabel(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Row 5: Usuário + Data
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: DS.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                solicitacao.usuarioNome,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: DS.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatDate(solicitacao.dataCriacao),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: DS.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
