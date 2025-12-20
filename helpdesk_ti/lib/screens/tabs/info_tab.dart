import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import '../../widgets/dashboard/stat_card.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    // Determinar qual dashboard mostrar baseado no role
    if (authService.isAdmin) {
      return _AdminDashboard(firestoreService: firestoreService);
    } else if (authService.isManager) {
      return _ManagerDashboard(
        firestoreService: firestoreService,
        authService: authService,
      );
    } else {
      return _UserDashboard(
        firestoreService: firestoreService,
        authService: authService,
      );
    }
  }
}

// ==================== DASHBOARD USUÁRIO ====================
class _UserDashboard extends StatelessWidget {
  final FirestoreService firestoreService;
  final AuthService authService;

  const _UserDashboard({
    required this.firestoreService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final usuarioId = authService.userEmail ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            '📊 Minhas Estatísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 20),

          // Cards de Estatísticas
          FutureBuilder<Map<String, dynamic>>(
            future: firestoreService.getStatsUsuario(usuarioId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum dado disponível',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final stats = snapshot.data!;

              return Column(
                children: [
                  // Primeira linha
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total de Chamados',
                          value: '${stats['totalChamados'] ?? 0}',
                          icon: Icons.assignment,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Solicitações',
                          value: '${stats['totalSolicitacoes'] ?? 0}',
                          icon: Icons.shopping_cart,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Segunda linha
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Abertos',
                          value: '${stats['abertos'] ?? 0}',
                          icon: Icons.folder_open,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Em Andamento',
                          value: '${stats['emAndamento'] ?? 0}',
                          icon: Icons.hourglass_empty,
                          color: const Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Terceira linha
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Fechados',
                          value: '${stats['fechados'] ?? 0}',
                          icon: Icons.check_circle,
                          color: const Color(0xFF607D8B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Aguardando Aprovação',
                          value: '${stats['solicitacoesPendentes'] ?? 0}',
                          icon: Icons.pending,
                          color: const Color(0xFFFFA726),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Contatos Úteis
          _buildContactsSection(),

          const SizedBox(height: 32),

          // FAQ
          _buildFAQSection(),
        ],
      ),
    );
  }

  Widget _buildContactsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_phone, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Contatos Úteis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.schedule,
            'Horário de Atendimento',
            'Segunda a Sexta: 8h às 18h',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.info_outline,
            'Informação',
            'Abra um chamado para suporte urgente',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E88E5), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Perguntas Frequentes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'Como abrir um chamado?',
            'Clique no botão "NOVO CHAMADO" na tela inicial.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'Quanto tempo demora o atendimento?',
            'Depende da prioridade. Chamados críticos são atendidos em até 1 hora.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'Posso anexar fotos?',
            'Sim! Ao criar o chamado, use os botões de Câmera ou Galeria.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
        ),
      ],
    );
  }
}

// ==================== DASHBOARD MANAGER ====================
class _ManagerDashboard extends StatelessWidget {
  final FirestoreService firestoreService;
  final AuthService authService;

  const _ManagerDashboard({
    required this.firestoreService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    // NOTA: Atualmente usando setor fixo. Futuramente adicionar campo 'setor' na coleção 'users' do Firestore
    // e buscar dinamicamente: userData['setor'] ?? 'Não informado'
    const setor = 'financeiro'; // Placeholder

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Dashboard do Gerente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 20),

          FutureBuilder<Map<String, dynamic>>(
            future: firestoreService.getStatsManager(setor),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    'Nenhum dado disponível',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final stats = snapshot.data!;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Chamados do Setor',
                          value: '${stats['totalChamadosSetor'] ?? 0}',
                          icon: Icons.business,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Solicitações',
                          value: '${stats['totalSolicitacoesSetor'] ?? 0}',
                          icon: Icons.shopping_cart,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Aguardando Aprovação',
                          value: '${stats['solicitacoesAguardando'] ?? 0}',
                          icon: Icons.pending_actions,
                          color: const Color(0xFFFFA726),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Aprovadas',
                          value: '${stats['solicitacoesAprovadas'] ?? 0}',
                          icon: Icons.check_circle,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==================== DASHBOARD ADMIN ====================
class _AdminDashboard extends StatelessWidget {
  final FirestoreService firestoreService;

  const _AdminDashboard({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Dashboard Administrativo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 20),

          FutureBuilder<Map<String, dynamic>>(
            future: firestoreService.getStatsAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    'Nenhum dado disponível',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final stats = snapshot.data!;

              return Column(
                children: [
                  // Visão Geral
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Chamados',
                          value: '${stats['totalChamados'] ?? 0}',
                          icon: Icons.assignment,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Solicitações',
                          value: '${stats['totalSolicitacoes'] ?? 0}',
                          icon: Icons.shopping_cart,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Abertos',
                          value: '${stats['abertos'] ?? 0}',
                          icon: Icons.folder_open,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Em Andamento',
                          value: '${stats['emAndamento'] ?? 0}',
                          icon: Icons.hourglass_empty,
                          color: const Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Fechados',
                          value: '${stats['fechados'] ?? 0}',
                          icon: Icons.check_circle,
                          color: const Color(0xFF607D8B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Rejeitados',
                          value: '${stats['rejeitados'] ?? 0}',
                          icon: Icons.cancel,
                          color: const Color(0xFFEF5350),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Prioridades
                  const Text(
                    '🎯 Por Prioridade',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Crítica',
                          value: '${stats['prioridadeCritica'] ?? 0}',
                          icon: Icons.warning,
                          color: const Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Alta',
                          value: '${stats['prioridadeAlta'] ?? 0}',
                          icon: Icons.priority_high,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Média',
                          value: '${stats['prioridadeMedia'] ?? 0}',
                          icon: Icons.remove,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Baixa',
                          value: '${stats['prioridadeBaixa'] ?? 0}',
                          icon: Icons.arrow_downward,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

