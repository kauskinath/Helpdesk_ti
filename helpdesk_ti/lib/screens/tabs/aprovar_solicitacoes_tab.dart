import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import '../../widgets/solicitacao_card.dart';
import '../solicitacao_details_screen.dart';

class AprovarSolicitacoesTab extends StatefulWidget {
  const AprovarSolicitacoesTab({super.key});

  @override
  State<AprovarSolicitacoesTab> createState() => _AprovarSolicitacoesTabState();
}

class _AprovarSolicitacoesTabState extends State<AprovarSolicitacoesTab> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    print('🔄 Atualizando solicitações...');
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
    print('✅ Solicitações atualizadas');
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final isManager = authService.userRole == 'manager';

    print('🏗️ APROVAR SOLICITAÇÕES - Role: ${authService.userRole}');
    print('🏗️ APROVAR SOLICITAÇÕES - isManager: $isManager');

    if (!isManager) {
      return Container(
        color: DS.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: DS.error.withAlpha(77)),
              const SizedBox(height: 16),
              const Text(
                'Acesso restrito',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DS.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apenas gerentes podem aprovar solicitações',
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
        stream: firestoreService.getSolicitacoesPendentesStream(),
        builder: (context, snapshot) {
          print('📊 SNAPSHOT - ConnectionState: ${snapshot.connectionState}');
          print('📊 SNAPSHOT - HasData: ${snapshot.hasData}');
          print('📊 SNAPSHOT - HasError: ${snapshot.hasError}');

          if (snapshot.hasError) {
            print('❌ SNAPSHOT ERROR: ${snapshot.error}');
          }

          // Carregando
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ Estado: CARREGANDO...');
            return const Center(
              child: CircularProgressIndicator(color: DS.action),
            );
          }

          // Erro
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: DS.error.withAlpha(77),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao carregar solicitações',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sem dados
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: DS.success.withAlpha(77),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma solicitação pendente',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Todas as solicitações foram processadas',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Lista de solicitações
          final solicitacoes = snapshot.data!;
          print('🔍 SOLICITAÇÕES: ${solicitacoes.length} encontradas');

          for (var i = 0; i < solicitacoes.length; i++) {
            print(
              '   📝 [$i] ${solicitacoes[i].titulo} - Status: ${solicitacoes[i].status}',
            );
          }

          print('🎨 Construindo ListView com ${solicitacoes.length} items');

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: solicitacoes.length,
              itemBuilder: (context, index) {
                print('🏗️ Construindo card $index');
                final solicitacao = solicitacoes[index];

                return SolicitacaoCard(
                  solicitacao: solicitacao,
                  onTap: () {
                    print(
                      '👆 Solicitação $index clicada: ${solicitacao.titulo}',
                    );
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
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'aprovar_solicitacoes_fab',
        onPressed: _isRefreshing ? null : _refresh,
        backgroundColor: _isRefreshing ? DS.textTertiary : DS.action,
        child: _isRefreshing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
