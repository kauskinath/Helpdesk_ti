import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../../widgets/chamado/status_badge.dart';
import 'chamado_detail_dialog.dart';

/// Tabela de chamados recentes para dashboard web
class RecentTicketsTable extends StatelessWidget {
  final List<Chamado> chamados;

  const RecentTicketsTable({super.key, required this.chamados});

  Color _getPriorityColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return AppColors.statusOpen; // Baixa - Verde
      case 2:
        return AppColors.statusInProgress; // Média - Azul
      case 3:
        return AppColors.warning; // Alta - Amarelo
      case 4:
        return AppColors.error; // Crítica - Vermelho
      default:
        return AppColors.grey;
    }
  }

  String _getPriorityLabel(int prioridade) {
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final headerColor = isDarkMode ? const Color(0xFF252525) : Colors.grey[50];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(headerColor),
            columns: [
              DataColumn(
                label: Text(
                  'Nº',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Título',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Usuário',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tipo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Prioridade',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Ações',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
            rows: chamados.map((chamado) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      chamado.numeroFormatado,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        chamado.titulo,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : null,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      chamado.usuarioNome,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : null,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      chamado.tipo,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : null,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          chamado.prioridade,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPriorityLabel(chamado.prioridade),
                        style: TextStyle(
                          color: _getPriorityColor(chamado.prioridade),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(StatusBadge(status: chamado.status)),
                  DataCell(
                    Text(
                      DateFormat('dd/MM/yy HH:mm').format(chamado.dataCriacao),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : null,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDarkMode ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.visibility_rounded,
                              size: 20,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    ChamadoDetailDialog(chamado: chamado),
                              );
                            },
                            tooltip: 'Visualizar',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(
                              alpha: isDarkMode ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: isDarkMode
                                  ? Colors.amber
                                  : AppColors.accent,
                            ),
                            onPressed: () {
                              // TODO: Editar chamado
                            },
                            tooltip: 'Editar',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
