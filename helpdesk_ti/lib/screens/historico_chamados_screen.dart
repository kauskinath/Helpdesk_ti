import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import '../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../widgets/ticket_card_v2.dart';
import 'chamado/ticket_details_refactored.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';

/// Tela de Histórico de Chamados Fechados
///
/// Exibe chamados com status "Fechado" ou "Rejeitado"
/// Permite filtrar por período (7, 30, 90 dias ou todos)
class HistoricoChamadosScreen extends StatefulWidget {
  final FirestoreService firestoreService;
  final AuthService authService;

  const HistoricoChamadosScreen({
    super.key,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<HistoricoChamadosScreen> createState() =>
      _HistoricoChamadosScreenState();
}

class _HistoricoChamadosScreenState extends State<HistoricoChamadosScreen> {
  String _filtroSelecionado = '30'; // 7, 30, 90 ou 'todos'

  DateTime? get _dataInicio {
    if (_filtroSelecionado == 'todos') return null;
    final dias = int.parse(_filtroSelecionado);
    return DateTime.now().subtract(Duration(days: dias));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Chamado>>(
        stream: _getChamadosFechados(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final chamados = snapshot.data ?? [];

          if (chamados.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Info do filtro atual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _filtroSelecionado == 'todos'
                            ? 'Últimos 30 dias'
                            : 'Últimos $_filtroSelecionado dias',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Filtro compacto
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.filter_list,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        setState(() {
                          _filtroSelecionado = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: '7',
                          child: Row(
                            children: [
                              Icon(
                                _filtroSelecionado == '7'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text('Últimos 7 dias'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: '30',
                          child: Row(
                            children: [
                              Icon(
                                _filtroSelecionado == '30'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text('Últimos 30 dias'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: '90',
                          child: Row(
                            children: [
                              Icon(
                                _filtroSelecionado == '90'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text('Últimos 90 dias'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'todos',
                          child: Row(
                            children: [
                              Icon(
                                _filtroSelecionado == 'todos'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text('Todos'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de chamados fechados
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {}); // Force rebuild
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chamados.length,
                    itemBuilder: (context, index) {
                      final chamado = chamados[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 200),
                          child: TicketCardV2(
                            numeroFormatado:
                                '#${chamado.numero.toString().padLeft(4, '0')}',
                            titulo: chamado.titulo,
                            status: chamado.status,
                            prioridade: chamado.prioridade,
                            usuarioNome: chamado.usuarioNome,
                            lastUpdated: chamado.lastUpdated,
                            numeroComentarios: chamado.numeroComentarios,
                            temAnexos: chamado.temAnexos,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketDetailsRefactored(
                                    chamado: chamado,
                                    firestoreService: widget.firestoreService,
                                    authService: widget.authService,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<List<Chamado>> _getChamadosFechados() {
    final dataInicio = _dataInicio;

    if (widget.authService.isAdmin || widget.authService.userRole == 'ti') {
      // Admin/TI: Ver todos os chamados fechados
      if (dataInicio != null) {
        return widget.firestoreService.getTodosChamadosStream().map((chamados) {
          return chamados.where((c) {
            final isFechado = c.status == 'Fechado' || c.status == 'Rejeitado';
            final dataFechamento = c.dataFechamento ?? c.dataCriacao;
            return isFechado && dataFechamento.isAfter(dataInicio);
          }).toList()..sort(
            (a, b) => (b.dataFechamento ?? b.dataCriacao).compareTo(
              a.dataFechamento ?? a.dataCriacao,
            ),
          );
        });
      } else {
        return widget.firestoreService.getTodosChamadosStream().map((chamados) {
          return chamados
              .where((c) => c.status == 'Fechado' || c.status == 'Rejeitado')
              .toList()
            ..sort(
              (a, b) => (b.dataFechamento ?? b.dataCriacao).compareTo(
                a.dataFechamento ?? a.dataCriacao,
              ),
            );
        });
      }
    } else {
      // Usuário comum: Ver apenas seus chamados fechados
      final userId = widget.authService.firebaseUser?.uid ?? '';
      if (dataInicio != null) {
        return widget.firestoreService.getChamadosDoUsuario(userId).map((
          chamados,
        ) {
          return chamados.where((c) {
            final isFechado = c.status == 'Fechado' || c.status == 'Rejeitado';
            final dataFechamento = c.dataFechamento ?? c.dataCriacao;
            return isFechado && dataFechamento.isAfter(dataInicio);
          }).toList()..sort(
            (a, b) => (b.dataFechamento ?? b.dataCriacao).compareTo(
              a.dataFechamento ?? a.dataCriacao,
            ),
          );
        });
      } else {
        return widget.firestoreService.getChamadosDoUsuario(userId).map((
          chamados,
        ) {
          return chamados
              .where((c) => c.status == 'Fechado' || c.status == 'Rejeitado')
              .toList()
            ..sort(
              (a, b) => (b.dataFechamento ?? b.dataCriacao).compareTo(
                a.dataFechamento ?? a.dataCriacao,
              ),
            );
        });
      }
    }
  }

  Widget _buildEmptyState() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: isDarkMode
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum chamado fechado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filtroSelecionado == 'todos'
                ? 'Não há chamados fechados ainda'
                : 'Nenhum chamado fechado nos últimos $_filtroSelecionado dias',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar histórico',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente novamente mais tarde',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
