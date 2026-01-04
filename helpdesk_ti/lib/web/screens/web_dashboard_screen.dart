import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/features/manutencao/services/manutencao_service.dart';
import 'package:helpdesk_ti/features/manutencao/models/chamado_manutencao_model.dart';
import '../widgets/stat_card_web.dart';
import '../widgets/recent_tickets_table.dart';

/// Dashboard principal do painel web - adaptado por role
class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  final ManutencaoService _manutencaoService = ManutencaoService();

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final userRole = authService.userRole;

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Chamados TI (para admin, gerente, user)
            if (_canSeeTI(userRole)) ...[
              _buildSectionTitle('🖥️ Chamados TI', isDarkMode),
              const SizedBox(height: 16),
              _buildTIStats(
                firestoreService,
                isDarkMode,
                userRole,
                authService.firebaseUser?.uid,
              ),
              const SizedBox(height: 32),
            ],

            // Seção de Manutenção (para gerente, admin_manutencao, executor)
            if (_canSeeManutencao(userRole)) ...[
              _buildSectionTitle('🔧 Chamados Manutenção', isDarkMode),
              const SizedBox(height: 16),
              _buildManutencaoStats(
                isDarkMode,
                userRole,
                authService.firebaseUser?.uid,
              ),
              const SizedBox(height: 32),
            ],

            // Chamados Recentes TI
            if (_canSeeTI(userRole)) ...[
              _buildSectionTitle('📋 Chamados TI Recentes', isDarkMode),
              const SizedBox(height: 16),
              _buildRecentTIChamados(
                firestoreService,
                isDarkMode,
                userRole,
                authService.firebaseUser?.uid,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canSeeTI(String? role) {
    return ['admin', 'manager', 'user'].contains(role);
  }

  bool _canSeeManutencao(String? role) {
    return ['admin', 'manager', 'admin_manutencao', 'executor'].contains(role);
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTIStats(
    FirestoreService firestoreService,
    bool isDarkMode,
    String? role,
    String? userId,
  ) {
    // Admin e Gerente veem todos, User vê só os próprios
    Stream<List<Chamado>> stream;
    if (role == 'user' && userId != null) {
      stream = firestoreService.getChamadosDoUsuario(userId);
    } else {
      stream = firestoreService.getChamadosAtivosStream();
    }

    return StreamBuilder<List<Chamado>>(
      stream: stream,
      builder: (context, snapshot) {
        final chamados = snapshot.data ?? [];
        final total = chamados.length;
        final abertos = chamados.where((c) => c.status == 'Aberto').length;
        final emAndamento = chamados
            .where((c) => c.status == 'Em Andamento')
            .length;
        final fechados = chamados.where((c) => c.status == 'Fechado').length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCardWeb(
                    title: 'Total TI',
                    value: total.toString(),
                    icon: Icons.computer,
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
    );
  }

  Widget _buildManutencaoStats(bool isDarkMode, String? role, String? userId) {
    Stream<List<ChamadoManutencao>> stream;

    if (role == 'manager') {
      // Gerente vê todos os chamados de manutenção
      stream = _manutencaoService.getChamadosParaAdminManutencao();
    } else if (role == 'admin_manutencao') {
      stream = _manutencaoService.getChamadosParaAdminManutencao();
    } else if (role == 'executor' && userId != null) {
      stream = _manutencaoService.getChamadosParaExecutor(userId);
    } else {
      // Admin vê todos
      stream = _manutencaoService.getChamadosParaAdminManutencao();
    }

    return StreamBuilder<List<ChamadoManutencao>>(
      stream: stream,
      builder: (context, snapshot) {
        final chamados = snapshot.data ?? [];
        final total = chamados.length;
        final pendentesAprovacao = chamados
            .where((c) => c.status.value == 'aguardando_aprovacao_gerente')
            .length;
        final emExecucao = chamados
            .where((c) => c.status.value == 'em_execucao')
            .length;
        final concluidos = chamados
            .where((c) => c.status.value == 'concluido')
            .length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCardWeb(
                    title: 'Total Manutenção',
                    value: total.toString(),
                    icon: Icons.build,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCardWeb(
                    title: role == 'manager'
                        ? 'Aguardando Aprovação'
                        : 'Pendentes',
                    value: pendentesAprovacao.toString(),
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCardWeb(
                    title: 'Em Execução',
                    value: emExecucao.toString(),
                    icon: Icons.engineering,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCardWeb(
                    title: 'Concluídos',
                    value: concluidos.toString(),
                    icon: Icons.task_alt,
                    color: AppColors.statusClosed,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTIChamados(
    FirestoreService firestoreService,
    bool isDarkMode,
    String? role,
    String? userId,
  ) {
    Stream<List<Chamado>> stream;
    if (role == 'user' && userId != null) {
      stream = firestoreService.getChamadosDoUsuario(userId);
    } else {
      stream = firestoreService.getChamadosAtivosStream();
    }

    return StreamBuilder<List<Chamado>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Erro: ${snapshot.error}',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          );
        }

        final chamados = snapshot.data ?? [];

        if (chamados.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    role == 'user'
                        ? 'Você não possui chamados ativos'
                        : 'Todos os chamados foram resolvidos',
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
    );
  }
}
