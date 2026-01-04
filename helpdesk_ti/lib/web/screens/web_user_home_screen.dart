import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/features/ti/models/avaliacao.dart';
import 'package:helpdesk_ti/features/manutencao/services/manutencao_service.dart';
import 'package:helpdesk_ti/features/manutencao/models/chamado_manutencao_model.dart';
import 'package:helpdesk_ti/features/manutencao/models/manutencao_enums.dart';
import '../widgets/avaliacao_dialog.dart';

/// Tela inicial para usuários comuns - Portal do Usuário
class WebUserHomeScreen extends StatefulWidget {
  const WebUserHomeScreen({super.key});

  @override
  State<WebUserHomeScreen> createState() => _WebUserHomeScreenState();
}

class _WebUserHomeScreenState extends State<WebUserHomeScreen> {
  final ManutencaoService _manutencaoService = ManutencaoService();

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final userId = authService.firebaseUser?.uid;
    final userName = authService.firebaseUser?.displayName ?? 'Usuário';

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação
            _buildWelcomeCard(userName, isDarkMode),
            const SizedBox(height: 24),

            // Ações rápidas
            _buildQuickActions(context, isDarkMode),
            const SizedBox(height: 32),

            // Meus chamados TI
            _buildSectionTitle('📋 Meus Chamados TI', isDarkMode),
            const SizedBox(height: 16),
            _buildMeusChamadosTI(firestoreService, userId, isDarkMode),
            const SizedBox(height: 32),

            // Meus chamados de manutenção (se aplicável)
            _buildSectionTitle('🔧 Meus Chamados de Manutenção', isDarkMode),
            const SizedBox(height: 16),
            _buildMeusChamadosManutencao(userId, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String userName, bool isDarkMode) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Bom dia';
      icon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Boa tarde';
      icon = Icons.wb_cloudy;
    } else {
      greeting = 'Boa noite';
      icon = Icons.nights_stay;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bem-vindo ao Portal de Suporte',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_circle_outline,
            title: 'Novo Chamado TI',
            subtitle: 'Abrir um chamado de suporte técnico',
            color: AppColors.primary,
            isDarkMode: isDarkMode,
            onTap: () {
              _showNewTIChamadoDialog(context, isDarkMode);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            icon: Icons.build_outlined,
            title: 'Novo Chamado Manutenção',
            subtitle: 'Solicitar serviço de manutenção',
            color: Colors.teal,
            isDarkMode: isDarkMode,
            onTap: () {
              _showNewManutencaoChamadoDialog(context, isDarkMode);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            icon: Icons.help_outline,
            title: 'FAQ',
            subtitle: 'Perguntas frequentes',
            color: Colors.orange,
            isDarkMode: isDarkMode,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('FAQ em breve...')));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDarkMode ? 0.2 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildMeusChamadosTI(
    FirestoreService firestoreService,
    String? userId,
    bool isDarkMode,
  ) {
    if (userId == null) {
      return _buildEmptyState('Usuário não identificado', isDarkMode);
    }

    return StreamBuilder<List<Chamado>>(
      stream: firestoreService.getChamadosDoUsuario(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Erro: ${snapshot.error}', isDarkMode);
        }

        final chamados = snapshot.data ?? [];

        if (chamados.isEmpty) {
          return _buildEmptyState(
            'Você ainda não tem chamados de TI',
            isDarkMode,
          );
        }

        // Mostrar últimos 5 chamados
        final recentChamados = chamados.take(5).toList();

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${chamados.length} chamados',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navegar para tela de chamados
                      },
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
              ),
              // Lista
              ...recentChamados.map(
                (chamado) => _buildChamadoTIItem(chamado, isDarkMode),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChamadoTIItem(Chamado chamado, bool isDarkMode) {
    return InkWell(
      onTap: () => _showChamadoDetailDialog(chamado, isDarkMode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode
                  ? Colors.white12
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            // Número
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chamado.numeroFormatado,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Título e data
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chamado.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(chamado.dataCriacao),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white54
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Botão Avaliar (para chamados fechados)
            if (chamado.status == 'Fechado') ...[
              _buildAvaliarButton(chamado, isDarkMode),
              const SizedBox(width: 12),
            ],
            // Status
            _buildStatusBadge(chamado.status, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildAvaliarButton(Chamado chamado, bool isDarkMode) {
    return FutureBuilder<Avaliacao?>(
      future: context.read<FirestoreService>().getAvaliacaoPorChamado(
        chamado.id,
      ),
      builder: (context, snapshot) {
        final jaAvaliado = snapshot.data != null;

        return Tooltip(
          message: jaAvaliado
              ? 'Você já avaliou este chamado'
              : 'Avaliar atendimento',
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AvaliacaoDialog(chamado: chamado),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: jaAvaliado
                    ? Colors.amber.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: jaAvaliado
                      ? Colors.amber.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    jaAvaliado ? Icons.star : Icons.star_border,
                    size: 16,
                    color: jaAvaliado ? Colors.amber : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    jaAvaliado ? 'Avaliado' : 'Avaliar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: jaAvaliado
                          ? Colors.amber.shade700
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChamadoDetailDialog(Chamado chamado, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chamado.numeroFormatado,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chamado.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Status', chamado.status, isDarkMode),
                      _buildDetailRow('Tipo', chamado.tipo, isDarkMode),
                      _buildDetailRow('Setor', chamado.setor, isDarkMode),
                      _buildDetailRow(
                        'Prioridade',
                        _getPriorityLabel(chamado.prioridade),
                        isDarkMode,
                      ),
                      _buildDetailRow(
                        'Criado em',
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(chamado.dataCriacao),
                        isDarkMode,
                      ),
                      if (chamado.dataFechamento != null)
                        _buildDetailRow(
                          'Fechado em',
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(chamado.dataFechamento!),
                          isDarkMode,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Descrição:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white10
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chamado.descricao,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),

                      // Botão de avaliar se fechado
                      if (chamado.status == 'Fechado') ...[
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    AvaliacaoDialog(chamado: chamado),
                              );
                            },
                            icon: const Icon(Icons.star),
                            label: const Text('Avaliar Atendimento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(int prioridade) {
    switch (prioridade) {
      case 1:
        return 'Baixa';
      case 2:
        return 'Média';
      case 3:
        return 'Alta';
      case 4:
        return 'Crítica';
      default:
        return 'Normal';
    }
  }

  Widget _buildStatusBadge(String status, bool isDarkMode) {
    Color color;
    switch (status) {
      case 'Aberto':
        color = AppColors.statusOpen;
        break;
      case 'Em Andamento':
        color = AppColors.statusInProgress;
        break;
      case 'Fechado':
        color = AppColors.statusClosed;
        break;
      default:
        color = AppColors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMeusChamadosManutencao(String? userId, bool isDarkMode) {
    if (userId == null) {
      return _buildEmptyState('Usuário não identificado', isDarkMode);
    }

    return StreamBuilder<List<ChamadoManutencao>>(
      stream: _manutencaoService.getChamadosPorCriador(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Nenhum chamado de manutenção', isDarkMode);
        }

        final chamados = snapshot.data ?? [];

        if (chamados.isEmpty) {
          return _buildEmptyState(
            'Você ainda não tem chamados de manutenção',
            isDarkMode,
          );
        }

        final recentChamados = chamados.take(5).toList();

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${chamados.length} chamados',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navegar para tela de chamados
                      },
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
              ),
              // Lista
              ...recentChamados.map(
                (chamado) => _buildChamadoManutencaoItem(chamado, isDarkMode),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChamadoManutencaoItem(
    ChamadoManutencao chamado,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white12
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Número
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              chamado.numeroFormatado,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Título e data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chamado.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(chamado.dataAbertura),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.white54
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status
          _buildManutencaoStatusBadge(chamado.status.value, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildManutencaoStatusBadge(String status, bool isDarkMode) {
    Color color;
    String label;

    switch (status) {
      case 'aberto':
        color = Colors.blue;
        label = 'Aberto';
        break;
      case 'em_validacao':
        color = Colors.amber;
        label = 'Em Validação';
        break;
      case 'aguardando_aprovacao_gerente':
        color = Colors.orange;
        label = 'Aguardando';
        break;
      case 'orcamento_aprovado':
        color = Colors.green;
        label = 'Aprovado';
        break;
      case 'em_execucao':
        color = Colors.indigo;
        label = 'Em Execução';
        break;
      case 'concluido':
        color = Colors.teal;
        label = 'Concluído';
        break;
      case 'rejeitado':
        color = Colors.red;
        label = 'Rejeitado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: isDarkMode
                  ? Colors.white30
                  : Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  void _showNewTIChamadoDialog(BuildContext context, bool isDarkMode) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String categoria = 'Hardware';
    int prioridade = 2;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Novo Chamado TI',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white10 : Colors.grey.shade50,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white10 : Colors.grey.shade50,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) => Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        items: ['Hardware', 'Software', 'Rede', 'Outro']
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setDialogState(() => categoria = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: prioridade,
                        decoration: const InputDecoration(
                          labelText: 'Prioridade',
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Baixa')),
                          DropdownMenuItem(value: 2, child: Text('Média')),
                          DropdownMenuItem(value: 3, child: Text('Alta')),
                          DropdownMenuItem(value: 4, child: Text('Crítica')),
                        ],
                        onChanged: (v) => setDialogState(() => prioridade = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || descController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos')),
                );
                return;
              }

              final authService = context.read<AuthService>();
              final firestoreService = context.read<FirestoreService>();

              final chamado = Chamado(
                id: '',
                titulo: titleController.text,
                descricao: descController.text,
                setor: 'TI',
                tipo: categoria,
                prioridade: prioridade,
                status: 'Aberto',
                usuarioId: authService.firebaseUser?.uid ?? '',
                usuarioNome: authService.firebaseUser?.displayName ?? 'Usuário',
                dataCriacao: DateTime.now(),
              );

              try {
                await firestoreService.criarChamado(chamado);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chamado criado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar Chamado'),
          ),
        ],
      ),
    );
  }

  void _showNewManutencaoChamadoDialog(BuildContext context, bool isDarkMode) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Novo Chamado de Manutenção',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex: Reparo em ar-condicionado',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white10 : Colors.grey.shade50,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva o problema ou serviço necessário',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white10 : Colors.grey.shade50,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || descController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos')),
                );
                return;
              }

              final authService = context.read<AuthService>();

              try {
                await _manutencaoService.criarChamado(
                  titulo: titleController.text,
                  descricao: descController.text,
                  criadorId: authService.firebaseUser?.uid ?? '',
                  criadorNome:
                      authService.firebaseUser?.displayName ?? 'Usuário',
                  criadorTipo: TipoCriadorChamado.usuarioComum,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chamado de manutenção criado com sucesso!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar Chamado'),
          ),
        ],
      ),
    );
  }
}
