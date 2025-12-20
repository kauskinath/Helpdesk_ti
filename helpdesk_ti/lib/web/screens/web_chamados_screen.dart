import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../../widgets/chamado/status_badge.dart';
import '../widgets/chamado_detail_dialog.dart';

/// Tela de gerenciamento completo de chamados
class WebChamadosScreen extends StatefulWidget {
  const WebChamadosScreen({super.key});

  @override
  State<WebChamadosScreen> createState() => _WebChamadosScreenState();
}

class _WebChamadosScreenState extends State<WebChamadosScreen> {
  String _searchQuery = '';
  String _statusFilter = 'Todos';
  String _prioridadeFilter = 'Todas';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Chamado> _filterChamados(List<Chamado> chamados) {
    var filtered = chamados;

    // Filtro de busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.numeroFormatado.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            c.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.usuarioNome.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtro de status
    if (_statusFilter != 'Todos') {
      filtered = filtered.where((c) => c.status == _statusFilter).toList();
    }

    // Filtro de prioridade
    if (_prioridadeFilter != 'Todas') {
      final prioridadeMap = {'Baixa': 1, 'Média': 2, 'Alta': 3, 'Crítica': 4};
      final prioridade = prioridadeMap[_prioridadeFilter];
      if (prioridade != null) {
        filtered = filtered.where((c) => c.prioridade == prioridade).toList();
      }
    }

    return filtered;
  }

  Color _getPriorityColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return AppColors.statusOpen;
      case 2:
        return AppColors.statusInProgress;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.error;
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
    final firestoreService = context.read<FirestoreService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            isDarkMode
                ? 'assets/images/wallpaper_dark.png'
                : 'assets/images/wallpaper_light.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da página
            Text(
              'Gerenciamento de Chamados',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 24),

            // Barra de ferramentas (Pesquisa + Filtros)
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
              child: Column(
                children: [
                  Row(
                    children: [
                      // Campo de pesquisa
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por número, título ou usuário...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _currentPage = 0;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Filtro de Status
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: const Icon(Icons.filter_list),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Todos',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem(
                              value: 'Aberto',
                              child: Text('Aberto'),
                            ),
                            DropdownMenuItem(
                              value: 'Em Andamento',
                              child: Text('Em Andamento'),
                            ),
                            DropdownMenuItem(
                              value: 'Pendente Aprovação',
                              child: Text('Pendente Aprovação'),
                            ),
                            DropdownMenuItem(
                              value: 'Fechado',
                              child: Text('Fechado'),
                            ),
                            DropdownMenuItem(
                              value: 'Rejeitado',
                              child: Text('Rejeitado'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value!;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Filtro de Prioridade
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _prioridadeFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Prioridade',
                            prefixIcon: const Icon(Icons.priority_high),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Todas',
                              child: Text('Todas'),
                            ),
                            DropdownMenuItem(
                              value: 'Baixa',
                              child: Text('Baixa'),
                            ),
                            DropdownMenuItem(
                              value: 'Média',
                              child: Text('Média'),
                            ),
                            DropdownMenuItem(
                              value: 'Alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'Crítica',
                              child: Text('Crítica'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _prioridadeFilter = value!;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tabela de chamados
            StreamBuilder<List<Chamado>>(
              stream: firestoreService.getTodosChamadosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text('Erro: ${snapshot.error}'),
                        ],
                      ),
                    ),
                  );
                }

                final allChamados = snapshot.data ?? [];
                final filteredChamados = _filterChamados(allChamados);
                final totalItems = filteredChamados.length;
                final totalPages = (totalItems / _rowsPerPage).ceil();

                // Paginação
                final startIndex = _currentPage * _rowsPerPage;
                final endIndex = (startIndex + _rowsPerPage).clamp(
                  0,
                  totalItems,
                );
                final paginatedChamados = filteredChamados.sublist(
                  startIndex,
                  endIndex,
                );

                if (filteredChamados.isEmpty) {
                  return Container(
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
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: AppColors.grey.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum chamado encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tente ajustar os filtros de busca',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Estatísticas rápidas
                    Row(
                      children: [
                        _buildQuickStat(
                          'Total',
                          filteredChamados.length.toString(),
                          Icons.confirmation_number,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          'Abertos',
                          filteredChamados
                              .where((c) => c.status == 'Aberto')
                              .length
                              .toString(),
                          Icons.pending,
                          AppColors.statusOpen,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          'Em Andamento',
                          filteredChamados
                              .where((c) => c.status == 'Em Andamento')
                              .length
                              .toString(),
                          Icons.loop,
                          AppColors.statusInProgress,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          'Fechados',
                          filteredChamados
                              .where((c) => c.status == 'Fechado')
                              .length
                              .toString(),
                          Icons.check_circle,
                          AppColors.statusClosed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tabela
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
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  AppColors.greyLight,
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Nº',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Título',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Usuário',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Tipo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Prioridade',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Data Criação',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Ações',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: paginatedChamados.map((chamado) {
                                  return DataRow(
                                    color:
                                        WidgetStateProperty.resolveWith<Color>((
                                          states,
                                        ) {
                                          if (states.contains(
                                            WidgetState.hovered,
                                          )) {
                                            return AppColors.primary.withValues(
                                              alpha: 0.05,
                                            );
                                          }
                                          return Colors.transparent;
                                        }),
                                    cells: [
                                      DataCell(
                                        Text(
                                          chamado.numeroFormatado,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 250,
                                          ),
                                          child: Text(
                                            chamado.titulo,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(chamado.usuarioNome)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            chamado.tipo,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            _getPriorityLabel(
                                              chamado.prioridade,
                                            ),
                                            style: TextStyle(
                                              color: _getPriorityColor(
                                                chamado.prioridade,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        StatusBadge(status: chamado.status),
                                      ),
                                      DataCell(
                                        Text(
                                          DateFormat(
                                            'dd/MM/yy HH:mm',
                                          ).format(chamado.dataCriacao),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.visibility,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      ChamadoDetailDialog(
                                                        chamado: chamado,
                                                      ),
                                                );
                                              },
                                              tooltip: 'Visualizar',
                                              color: AppColors.primary,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                // TODO: Editar chamado
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Editar ${chamado.numeroFormatado}',
                                                    ),
                                                  ),
                                                );
                                              },
                                              tooltip: 'Editar',
                                              color: AppColors.warning,
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

                          // Controles de paginação
                          if (totalPages > 1)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.grey.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Linhas por página:',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<int>(
                                    value: _rowsPerPage,
                                    items: [10, 25, 50, 100].map((value) {
                                      return DropdownMenuItem(
                                        value: value,
                                        child: Text(value.toString()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _rowsPerPage = value!;
                                        _currentPage = 0;
                                      });
                                    },
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${startIndex + 1}-$endIndex de $totalItems',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 0
                                        ? () {
                                            setState(() {
                                              _currentPage--;
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    'Página ${_currentPage + 1} de $totalPages',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < totalPages - 1
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
