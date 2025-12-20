import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final usuarioId = authService.firebaseUser?.uid ?? '';

    // Se não tiver ID de usuário, mostrar erro
    if (usuarioId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.2),
                    AppColors.warning.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Usuário não autenticado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login novamente para ver seus chamados',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder(
      stream: firestoreService.getChamadosDoUsuarioStream(usuarioId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ MeusChamadosTab - Error: ${snapshot.error}');
        }

        // Carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Erro
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error.withValues(alpha: 0.2),
                        AppColors.error.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erro ao carregar chamados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primaryLight.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: isDarkMode
                        ? AppColors.primary.withValues(alpha: 0.7)
                        : AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nenhum chamado encontrado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie um novo chamado para começar',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Lista de chamados
        final chamados = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chamados.length,
          itemBuilder: (context, index) {
            try {
              final chamado = chamados[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TicketCardV2(
                  numeroFormatado: chamado.numeroFormatado,
                  titulo: chamado.titulo,
                  status: chamado.status,
                  prioridade: chamado.prioridade,
                  usuarioNome: chamado.usuarioNome,
                  lastUpdated: chamado.lastUpdated,
                  numeroComentarios: chamado.numeroComentarios,
                  temAnexos: chamado.temAnexos,
                  onTap: () {
                    print(
                      '👆 Navegando para detalhes do chamado: ${chamado.id}',
                    );
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
                ),
              );
            } catch (e, stackTrace) {
              print('❌ Erro ao renderizar card $index: $e');
              print('Stack: $stackTrace');
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error.withValues(alpha: 0.2),
                        AppColors.error.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.error, color: AppColors.error),
                    title: const Text(
                      'Erro ao carregar chamado',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '$e',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
