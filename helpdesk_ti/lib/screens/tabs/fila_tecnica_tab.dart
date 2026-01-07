import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import '../../widgets/ticket_card_v2.dart';
import '../chamado/ticket_details_refactored.dart';

class FilaTecnicaTab extends StatefulWidget {
  const FilaTecnicaTab({super.key});

  @override
  State<FilaTecnicaTab> createState() => _FilaTecnicaTabState();
}

class _FilaTecnicaTabState extends State<FilaTecnicaTab> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();

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
                    'Erro ao carregar chamados',
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
                      fontSize: 12,
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
                    Icons.inbox_outlined,
                    size: 80,
                    color: DS.action.withAlpha(77),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum chamado na fila',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Todos os chamados foram resolvidos',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Lista de chamados
          final chamados = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: DS.action,
            backgroundColor: DS.card,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: chamados.length,
              itemBuilder: (context, index) {
                final chamado = chamados[index];

                return TicketCardV2(
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
        heroTag: 'fila_tecnica_fab',
        onPressed: _isRefreshing ? null : _refresh,
        backgroundColor: _isRefreshing ? DS.border : DS.action,
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
