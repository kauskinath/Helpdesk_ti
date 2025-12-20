import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import '../../widgets/solicitacao_card.dart';
import '../solicitacao_details_screen.dart';

class HistoricoSolicitacoesTab extends StatefulWidget {
  const HistoricoSolicitacoesTab({super.key});

  @override
  State<HistoricoSolicitacoesTab> createState() =>
      _HistoricoSolicitacoesTabState();
}

class _HistoricoSolicitacoesTabState extends State<HistoricoSolicitacoesTab> {
  String _filtroStatus = 'Todas'; // Todas, Aprovado, Reprovado

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final isManager = authService.userRole == 'manager';

    if (!isManager) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.red.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acesso restrito',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Apenas gerentes podem visualizar o histórico'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filtrar por:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Todas',
                        label: Text('Todas'),
                        icon: Icon(Icons.list, size: 16),
                      ),
                      ButtonSegment(
                        value: 'Aprovado',
                        label: Text('Aprovadas'),
                        icon: Icon(Icons.check_circle, size: 16),
                      ),
                      ButtonSegment(
                        value: 'Reprovado',
                        label: Text('Reprovadas'),
                        icon: Icon(Icons.cancel, size: 16),
                      ),
                    ],
                    selected: {_filtroStatus},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _filtroStatus = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de solicitações
          Expanded(
            child: StreamBuilder(
              stream: firestoreService.getSolicitacoesProcessadasStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar histórico',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma solicitação processada',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Aprove ou reprove solicitações para visualizar o histórico'),
                      ],
                    ),
                  );
                }

                // Filtrar por status
                var solicitacoes = snapshot.data!;
                if (_filtroStatus != 'Todas') {
                  solicitacoes = solicitacoes
                      .where((s) => s.status == _filtroStatus)
                      .toList();
                }

                if (solicitacoes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma solicitação $_filtroStatus',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: solicitacoes.length,
                  itemBuilder: (context, index) {
                    final solicitacao = solicitacoes[index];

                    return SolicitacaoCard(
                      solicitacao: solicitacao,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SolicitacaoDetailsScreen(
                              solicitacao: solicitacao,
                              firestoreService: firestoreService,
                              authService: authService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


