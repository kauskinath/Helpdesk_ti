import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import '../../widgets/ticket_card_v2.dart';
import '../chamado/ticket_details_refactored.dart';

class MeusChamadosTab extends StatefulWidget {
  const MeusChamadosTab({super.key});

  @override
  State<MeusChamadosTab> createState() => _MeusChamadosTabState();
}

class _MeusChamadosTabState extends State<MeusChamadosTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final usuarioId = authService.firebaseUser?.uid ?? '';

    // Se não tiver ID de usuário, mostrar erro
    if (usuarioId.isEmpty) {
      return Container(
        color: DS.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: DS.warning.withAlpha(128),
              ),
              const SizedBox(height: 24),
              const Text(
                'Usuário não autenticado',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DS.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Faça login novamente para ver seus chamados',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: DS.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: DS.background,
      child: StreamBuilder(
        stream: firestoreService.getChamadosDoUsuarioStream(usuarioId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ MeusChamadosTab - Error: ${snapshot.error}');
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
                    color: DS.error.withAlpha(128),
                  ),
                  const SizedBox(height: 24),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: DS.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sem dados - mostrar mensagem amigável
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: DS.action.withAlpha(128),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nenhum chamado encontrado',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crie um novo chamado para começar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Lista de chamados
          final chamados = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chamados.length,
            itemBuilder: (context, index) {
              try {
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
              } catch (e, stackTrace) {
                print('❌ Erro ao renderizar card $index: $e');
                print('Stack: $stackTrace');
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DS.card,
                    border: Border.all(color: DS.error, width: 1),
                    borderRadius: BorderRadius.circular(DS.cardRadius),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.error, color: DS.error),
                    title: Text(
                      'Erro ao carregar chamado',
                      style: TextStyle(color: DS.textPrimary),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
