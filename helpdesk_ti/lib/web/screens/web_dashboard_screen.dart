import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../widgets/stat_card_web.dart';
import '../widgets/recent_tickets_table.dart';

/// Dashboard principal do painel web - visual igual ao mobile
class WebDashboardScreen extends StatelessWidget {
  const WebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      // Wallpaper igual ao mobile
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
            // Título da seção
            Text(
              'Resumo Geral',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
                shadows: isDarkMode
                    ? null
                    : [
                        const Shadow(
                          color: Colors.white,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 16),

            // Cards de estatísticas - layout igual ao mobile
            StreamBuilder<List<Chamado>>(
              stream: firestoreService.getChamadosAtivosStream(),
              builder: (context, snapshot) {
                final chamados = snapshot.data ?? [];
                final total = chamados.length;
                final abertos = chamados
                    .where((c) => c.status == 'Aberto')
                    .length;
                final emAndamento = chamados
                    .where((c) => c.status == 'Em Andamento')
                    .length;
                final fechados = chamados
                    .where((c) => c.status == 'Fechado')
                    .length;

                return Column(
                  children: [
                    // Primeira linha: Total e Abertos
                    Row(
                      children: [
                        Expanded(
                          child: StatCardWeb(
                            title: 'Total',
                            value: total.toString(),
                            icon: Icons.confirmation_number,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCardWeb(
                            title: 'Abertos',
                            value: abertos.toString(),
                            icon: Icons.fiber_new,
                            color: AppColors.statusOpen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Segunda linha: Em Andamento e Fechados
                    Row(
                      children: [
                        Expanded(
                          child: StatCardWeb(
                            title: 'Em Andamento',
                            value: emAndamento.toString(),
                            icon: Icons.pending_actions,
                            color: AppColors.statusInProgress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCardWeb(
                            title: 'Fechados',
                            value: fechados.toString(),
                            icon: Icons.check_circle,
                            color: AppColors.statusClosed,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Chamados Recentes
            Text(
              '📋 Chamados Recentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
                shadows: isDarkMode
                    ? null
                    : [
                        const Shadow(
                          color: Colors.white,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<Chamado>>(
              stream: firestoreService.getChamadosAtivosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white70
                            : AppColors.textPrimary,
                      ),
                    ),
                  );
                }

                final chamados = snapshot.data ?? [];

                if (chamados.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum chamado no momento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Todos os chamados foram resolvidos',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RecentTicketsTable(chamados: chamados.take(10).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}
