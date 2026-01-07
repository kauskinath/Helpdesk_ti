import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import '../../data/firestore_service.dart';
import '../../widgets/ticket_card_v2.dart';
import '../chamado/ticket_details_refactored.dart';

/// ChamadosOrcamentoTab - Tab de Chamados TI com Orçamento
///
/// Esta tab exibe apenas chamados de TI que possuem custoEstimado definido,
/// permitindo que o gerente visualize e aprove solicitações que necessitam
/// de verba/orçamento.
///
/// Fluxo:
/// 1. Usuário comum cria chamado TI solicitando equipamento/serviço
/// 2. Admin TI define custoEstimado e anexa documentação
/// 3. Gerente visualiza nesta tab e aprova/rejeita
/// 4. Após aprovação, Admin TI realiza a compra/serviço
/// 5. Chamado é finalizado e vai para o histórico
class ChamadosOrcamentoTab extends StatefulWidget {
  const ChamadosOrcamentoTab({super.key});

  @override
  State<ChamadosOrcamentoTab> createState() => _ChamadosOrcamentoTabState();
}

class _ChamadosOrcamentoTabState extends State<ChamadosOrcamentoTab> {
  Future<void> _refresh() async {
    print('🔄 Atualizando chamados com orçamento...');
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
    print('✅ Chamados com orçamento atualizados');
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final isManager = authService.userRole == 'manager';

    print('💰 CHAMADOS COM ORÇAMENTO - Role: ${authService.userRole}');
    print('💰 CHAMADOS COM ORÇAMENTO - isManager: $isManager');

    if (!isManager) {
      return Container(
        color: DS.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: DS.error.withAlpha(102),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acesso Restrito',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DS.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apenas gerentes podem visualizar chamados com orçamento',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', color: DS.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DS.background,
      body: StreamBuilder(
        stream: firestoreService.getTodosChamadosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ SNAPSHOT ERROR: ${snapshot.error}');
          }

          // Carregando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: DS.action),
            );
          }

          // Erro
          if (snapshot.hasError) {
            print('❌ ERRO NO STREAM: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: DS.error.withAlpha(102),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao carregar chamados',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final todosChamados = snapshot.data ?? [];
          print('📋 TOTAL CHAMADOS: ${todosChamados.length}');

          /// Filtro de Chamados com Orçamento
          ///
          /// Este filtro seleciona apenas chamados TI que possuem custoEstimado
          /// definido, indicando que precisam de aprovação de orçamento pelo gerente.
          ///
          /// Critérios de filtro:
          /// 1. chamado.tipo != 'MANUTENCAO' - Apenas chamados de TI
          /// 2. chamado.custoEstimado != null - Possui orçamento definido
          /// 3. chamado.custoEstimado > 0 - Orçamento maior que zero
          final chamadosComOrcamento = todosChamados.where((chamado) {
            final isTI = chamado.tipo != 'MANUTENCAO';
            final temOrcamento =
                chamado.custoEstimado != null && chamado.custoEstimado! > 0;

            return isTI && temOrcamento;
          }).toList();

          print('💰 CHAMADOS TI COM ORÇAMENTO: ${chamadosComOrcamento.length}');

          /// Ordenação dos Chamados
          ///
          /// Os chamados são ordenados por:
          /// 1º - Prioridade (4=Crítica, 3=Alta, 2=Média, 1=Baixa) - Maior primeiro
          /// 2º - Data de criação - Mais recente primeiro
          chamadosComOrcamento.sort((a, b) {
            final prioridadeCompare = b.prioridade.compareTo(a.prioridade);
            if (prioridadeCompare != 0) return prioridadeCompare;
            return b.dataCriacao.compareTo(a.dataCriacao);
          });

          // Lista vazia
          if (chamadosComOrcamento.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.request_quote,
                    size: 80,
                    color: DS.action.withAlpha(77),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum chamado com orçamento',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quando houver chamados TI com orçamento\npara aprovação, eles aparecerão aqui',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Exibir lista de chamados com orçamento
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chamadosComOrcamento.length,
              itemBuilder: (context, index) {
                final chamado = chamadosComOrcamento[index];
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
                    temAnexos: chamado.temAnexos,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicketDetailsRefactored(
                            chamado: chamado,
                            firestoreService: context.read<FirestoreService>(),
                            authService: context.read<AuthService>(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
