import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import '../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../widgets/ticket_card_v2.dart';
import 'chamado/ticket_details_refactored.dart';

/// Tela de Histórico Completo para Gerente
///
/// Exibe SOMENTE chamados FECHADOS (concluídos) de TI e Manutenção juntos
class GerenteHistoricoCompletoScreen extends StatefulWidget {
  const GerenteHistoricoCompletoScreen({super.key});

  @override
  State<GerenteHistoricoCompletoScreen> createState() =>
      _GerenteHistoricoCompletoScreenState();
}

class _GerenteHistoricoCompletoScreenState
    extends State<GerenteHistoricoCompletoScreen> {
  String _filtroSelecionado = '30'; // 7, 30, 90 ou 'todos'

  DateTime? get _dataInicio {
    if (_filtroSelecionado == 'todos') return null;
    final dias = int.parse(_filtroSelecionado);
    return DateTime.now().subtract(Duration(days: dias));
  }

  /// Stream que busca APENAS chamados FECHADOS de TI e Manutenção
  Stream<List<Chamado>> _getChamadosFechados() {
    final firestoreService = context.read<FirestoreService>();

    return firestoreService.getTodosChamadosStream().map((chamados) {
      // Filtrar apenas chamados FECHADOS (status: Fechado)
      var filtrados = chamados.where((c) => c.status == 'Fechado').toList();

      // Aplicar filtro de data se necessário
      if (_dataInicio != null) {
        filtrados = filtrados.where((c) {
          return c.dataCriacao.isAfter(_dataInicio!);
        }).toList();
      }

      // Ordenar por data de criação (mais recente primeiro)
      filtrados.sort((a, b) {
        return b.dataCriacao.compareTo(a.dataCriacao);
      });

      return filtrados;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userName = authService.userName ?? 'Gerente';

    return Container(
      color: DS.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header com botão voltar e saudação
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Botão voltar
                    Container(
                      decoration: BoxDecoration(
                        color: DS.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DS.border, width: 1),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: DS.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Voltar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Saudação e título
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $userName!',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DS.textPrimary,
                            ),
                          ),
                          const Text(
                            '📋 Histórico - Chamados Fechados',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: DS.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filtro de período
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      'Período: ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: DS.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFiltroChip('7', '7 dias'),
                            const SizedBox(width: 8),
                            _buildFiltroChip('30', '30 dias'),
                            const SizedBox(width: 8),
                            _buildFiltroChip('90', '90 dias'),
                            const SizedBox(width: 8),
                            _buildFiltroChip('todos', 'Todos'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lista de chamados fechados
              Expanded(
                child: StreamBuilder<List<Chamado>>(
                  stream: _getChamadosFechados(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: DS.action),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: DS.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Erro ao carregar histórico',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: DS.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final chamados = snapshot.data ?? [];

                    if (chamados.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: DS.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum chamado fechado',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: DS.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'no período selecionado',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: DS.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chamados.length,
                      itemBuilder: (context, index) {
                        final chamado = chamados[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TicketCardV2(
                            numeroFormatado: chamado.numeroFormatado,
                            titulo: chamado.titulo,
                            status: chamado.status,
                            prioridade: chamado.prioridade,
                            usuarioNome: chamado.usuarioNome,
                            setorNome: chamado.setor,
                            lastUpdated: chamado.lastUpdated,
                            temAnexos: chamado.anexos.isNotEmpty,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketDetailsRefactored(
                                    chamado: chamado,
                                    firestoreService: context
                                        .read<FirestoreService>(),
                                    authService: context.read<AuthService>(),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label) {
    final isSelected = _filtroSelecionado == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroSelecionado = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DS.action : DS.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DS.action : DS.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isSelected ? Colors.white : DS.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
