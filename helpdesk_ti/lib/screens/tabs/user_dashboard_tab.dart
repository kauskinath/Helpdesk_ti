import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import '../../widgets/dashboard/stat_card.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';

class UserDashboardTab extends StatefulWidget {
  const UserDashboardTab({super.key});

  @override
  State<UserDashboardTab> createState() => _UserDashboardTabState();
}

class _UserDashboardTabState extends State<UserDashboardTab> {
  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final usuarioId = authService.userEmail ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black12],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com título e saudação
            _buildHeader(context, authService),
            const SizedBox(height: 24),

            // Cards de estatísticas principais
            _buildStatsCards(firestoreService, usuarioId),
            const SizedBox(height: 24),

            // Gráfico de distribuição por status
            _buildStatusDistribution(firestoreService, usuarioId),
            const SizedBox(height: 24),

            // Chamados recentes
            _buildRecentTickets(firestoreService, usuarioId),
            const SizedBox(height: 24),

            // Tempo médio de resposta
            _buildAverageResponseTime(firestoreService, usuarioId),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Bom dia';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Boa tarde';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Boa noite';
      greetingIcon = Icons.nightlight_round;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(greetingIcon, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  authService.userName ?? 'Usuário',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Acompanhe seus chamados',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.dashboard,
            size: 36,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(FirestoreService firestoreService, String usuarioId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: firestoreService.getStatsUsuario(usuarioId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Nenhum chamado registrado ainda',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        final stats = snapshot.data!;
        final total = stats['totalChamados'] ?? 0;
        final abertos = stats['abertos'] ?? 0;
        final emAndamento = stats['emAndamento'] ?? 0;
        final concluidos = stats['concluidos'] ?? 0;

        return Column(
          children: [
            // Primeira linha: Total e Abertos
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total',
                    value: '$total',
                    icon: Icons.assignment,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Abertos',
                    value: '$abertos',
                    icon: Icons.folder_open,
                    color: const Color(0xFFFFA726),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Segunda linha: Em Andamento e Concluídos
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Em Andamento',
                    value: '$emAndamento',
                    icon: Icons.refresh,
                    color: const Color(0xFF42A5F5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Concluídos',
                    value: '$concluidos',
                    icon: Icons.check_circle,
                    color: const Color(0xFF66BB6A),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusDistribution(
    FirestoreService firestoreService,
    String usuarioId,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: firestoreService.getStatsUsuario(usuarioId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;
        final total = (stats['totalChamados'] ?? 0) as int;

        if (total == 0) return const SizedBox.shrink();

        final abertos = (stats['abertos'] ?? 0) as int;
        final emAndamento = (stats['emAndamento'] ?? 0) as int;
        final concluidos = (stats['concluidos'] ?? 0) as int;

        final percentAbertos = (abertos / total * 100).toStringAsFixed(1);
        final percentAndamento = (emAndamento / total * 100).toStringAsFixed(1);
        final percentConcluidos = (concluidos / total * 100).toStringAsFixed(1);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Distribuição por Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Barra de Abertos
              _buildStatusBar(
                'Abertos',
                abertos,
                percentAbertos,
                const Color(0xFFFFA726),
                total,
              ),
              const SizedBox(height: 12),

              // Barra de Em Andamento
              _buildStatusBar(
                'Em Andamento',
                emAndamento,
                percentAndamento,
                const Color(0xFF42A5F5),
                total,
              ),
              const SizedBox(height: 12),

              // Barra de Concluídos
              _buildStatusBar(
                'Concluídos',
                concluidos,
                percentConcluidos,
                const Color(0xFF66BB6A),
                total,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(
    String label,
    int count,
    String percent,
    Color color,
    int total,
  ) {
    final value = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '$count ($percent%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTickets(
    FirestoreService firestoreService,
    String usuarioId,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Últimos Chamados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          StreamBuilder<List<Chamado>>(
            stream: firestoreService.getChamadosDoUsuarioStream(usuarioId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Nenhum chamado encontrado',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              }

              // Pegar apenas os 5 mais recentes
              final chamados = snapshot.data!.take(5).toList();

              return Column(
                children: chamados.map((chamado) {
                  return _buildTicketItem(chamado);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(Chamado chamado) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    Color statusColor;
    IconData statusIcon;

    switch (chamado.status.toLowerCase()) {
      case 'aberto':
        statusColor = const Color(0xFFFFA726);
        statusIcon = Icons.folder_open;
        break;
      case 'em andamento':
        statusColor = const Color(0xFF42A5F5);
        statusIcon = Icons.refresh;
        break;
      case 'concluído':
        statusColor = const Color(0xFF66BB6A);
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chamado.titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(chamado.dataCriacao),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              chamado.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageResponseTime(
    FirestoreService firestoreService,
    String usuarioId,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A).withValues(alpha: 0.8),
            const Color(0xFF8E24AA).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: firestoreService.getStatsUsuario(usuarioId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final stats = snapshot.data!;
          final tempoMedio = stats['tempoMedioResposta'] ?? '—';

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tempo Médio de Resposta',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tempoMedio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.trending_down, color: Colors.white70, size: 32),
            ],
          );
        },
      ),
    );
  }
}


