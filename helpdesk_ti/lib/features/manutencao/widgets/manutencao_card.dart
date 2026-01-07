import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import '../models/chamado_manutencao_model.dart';
import '../models/manutencao_enums.dart';

/// Card padronizado para chamados de Manutenção
///
/// Novo Design System:
/// - Fundo #1A1C1E, borda #2C2F33, radius 12px
/// - Barra de status 3px à esquerda
/// - Layout: ID + Status (linha 1), Título (linha 2), Usuário (linha 3)
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

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inDays == 0) {
      if (diferenca.inHours == 0) {
        return '${diferenca.inMinutes}min';
      }
      return '${diferenca.inHours}h';
    } else if (diferenca.inDays == 1) {
      return 'Ontem';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays}d';
    } else {
      return DateFormat('dd/MM').format(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Stack(
          children: [
            // Card principal com barra de status
            Row(
              children: [
                // Barra de status (3px à esquerda)
                Container(
                  width: 3,
                  height: 100,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(DS.cardRadius),
                      bottomLeft: Radius.circular(DS.cardRadius),
                    ),
                  ),
                ),
                // Card principal
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 100),
                    decoration: BoxDecoration(
                      color: DS.card,
                      border: Border.all(color: DS.border, width: 1),
                      borderRadius: BorderRadius.circular(DS.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Linha 1: ID à esquerda (status exibido no badge)
                          Text(
                            chamado.numeroFormatado,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: DS.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Linha 2: Título
                          Text(
                            chamado.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DS.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Linha 3: Usuário + Data + Orçamento
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: DS.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  chamado.criadorNome,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: DS.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Orçamento (se houver)
                              if (chamado.orcamento?.valorEstimado != null) ...[
                                const Icon(
                                  Icons.attach_money,
                                  size: 14,
                                  color: DS.success,
                                ),
                                Text(
                                  'R\$ ${chamado.orcamento!.valorEstimado!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: DS.success,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Data
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: DS.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatarData(chamado.dataAbertura),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: DS.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Badge de status (canto superior direito) com cor
            Positioned(
              top: 8,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(38), // 15% opacidade
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
