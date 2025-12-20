import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/features/ti/models/solicitacao.dart';

class SolicitacaoCard extends StatelessWidget {
  final Solicitacao solicitacao;
  final VoidCallback? onTap;

  const SolicitacaoCard({super.key, required this.solicitacao, this.onTap});

  Color _getStatusColor() {
    switch (solicitacao.status) {
      case 'Pendente':
        return const Color(0xFFFFA726); // Laranja
      case 'Aprovado':
        return const Color(0xFF4CAF50); // Verde
      case 'Reprovado':
        return const Color(0xFFEF5350); // Vermelho
      default:
        return Colors.grey;
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
    print('🎨 SolicitacaoCard.build() - Título: ${solicitacao.titulo}');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(minHeight: 140),
      child: Card(
        elevation: 8,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            print('👆 Solicitação clicada: ${solicitacao.titulo}');
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : Colors.white,
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? _getStatusColor().withValues(alpha: 0.5)
                    : _getStatusColor(),
                width: Theme.of(context).brightness == Brightness.dark ? 2 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? _getStatusColor().withValues(alpha: 0.3)
                      : _getStatusColor().withValues(alpha: 0.2),
                  blurRadius: Theme.of(context).brightness == Brightness.dark
                      ? 8
                      : 12,
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
                  // Número da solicitação
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      solicitacao.numeroFormatado,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Título
                  Text(
                    solicitacao.titulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      shadows: Theme.of(context).brightness == Brightness.dark
                          ? [
                              const Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status e Prioridade
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                Theme.of(context).brightness == Brightness.dark
                                ? [
                                    _getStatusColor().withValues(alpha: 0.3),
                                    _getStatusColor().withValues(alpha: 0.2),
                                  ]
                                : [
                                    _getStatusColor().withValues(alpha: 0.15),
                                    _getStatusColor().withValues(alpha: 0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(),
                            width:
                                Theme.of(context).brightness == Brightness.dark
                                ? 1
                                : 1.5,
                          ),
                        ),
                        child: Text(
                          solicitacao.status,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : _getStatusColor(),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Theme.of(context).brightness == Brightness.dark
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Prioridade: ${_getPriorityLabel()}',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Item Solicitado
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          solicitacao.itemSolicitado,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Custo Estimado
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _formatCurrency(solicitacao.custoEstimado),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Setor e Data
                  Row(
                    children: [
                      const Icon(Icons.business, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        solicitacao.setor,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(solicitacao.dataCriacao),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),

                  // Solicitante
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          solicitacao.usuarioNome,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
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

