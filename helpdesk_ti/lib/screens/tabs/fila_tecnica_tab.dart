import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder(
        stream: firestoreService.getTodosChamadosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ SNAPSHOT ERROR: ${snapshot.error}');
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
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar chamados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
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
                    Icons.inbox,
                    size: 80,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum chamado na fila',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Todos os chamados foram resolvidos'),
                ],
              ),
            );
          }

          // Lista de chamados
          final chamados = snapshot.data!;

          // Se não houver chamados, mostrar mensagem
          if (chamados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 80,
                    color: isDarkMode
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum chamado encontrado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
                    lastUpdated: chamado.lastUpdated,
                    numeroComentarios: chamado.numeroComentarios,
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
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fila_tecnica_fab',
        onPressed: _isRefreshing ? null : _refresh,
        backgroundColor: _isRefreshing ? Colors.grey : AppColors.primary,
        child: _isRefreshing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }
}
