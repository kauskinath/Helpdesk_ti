import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../widgets/chamado/status_badge.dart';

/// Dialog modal com detalhes completos do chamado
class ChamadoDetailDialog extends StatefulWidget {
  final Chamado chamado;

  const ChamadoDetailDialog({super.key, required this.chamado});

  @override
  State<ChamadoDetailDialog> createState() => _ChamadoDetailDialogState();
}

class _ChamadoDetailDialogState extends State<ChamadoDetailDialog> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return AppColors.statusOpen;
      case 2:
        return AppColors.statusInProgress;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.error;
      default:
        return AppColors.grey;
    }
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
        return 'CRÍTICA';
      default:
        return 'Normal';
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();

      await firestoreService.adicionarComentario(
        chamadoId: widget.chamado.id,
        autorId: authService.firebaseUser?.uid ?? '',
        autorNome: authService.userName ?? 'Admin',
        autorRole: 'admin',
        mensagem: _commentController.text.trim(),
      );

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Comentário adicionado com sucesso'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao adicionar comentário: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isSubmitting = true);

    try {
      final firestoreService = context.read<FirestoreService>();

      await firestoreService.atualizarChamado(widget.chamado.id, {
        'status': newStatus,
        'dataAtualizacao': DateTime.now(),
        if (newStatus == 'Fechado') 'dataFechamento': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Status atualizado para: $newStatus'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao atualizar status: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.confirmation_number,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chamado.numeroFormatado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.chamado.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

            // Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Details
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status e Prioridade
                          Row(
                            children: [
                              StatusBadge(status: widget.chamado.status),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(
                                    widget.chamado.prioridade,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getPriorityColor(
                                      widget.chamado.prioridade,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.priority_high,
                                      size: 16,
                                      color: _getPriorityColor(
                                        widget.chamado.prioridade,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getPriorityLabel(
                                        widget.chamado.prioridade,
                                      ),
                                      style: TextStyle(
                                        color: _getPriorityColor(
                                          widget.chamado.prioridade,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Descrição
                          const Text(
                            '📝 Descrição',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.chamado.descricao,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Timeline de Comentários
                          const Text(
                            '💬 Comentários',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: context
                                .read<FirestoreService>()
                                .getComentariosStream(widget.chamado.id),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: AppColors.greyLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 48,
                                          color: AppColors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Nenhum comentário ainda',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final comentariosData = snapshot.data!.reversed
                                  .toList();

                              return Column(
                                children: comentariosData.map((comentarioMap) {
                                  final isAdmin =
                                      comentarioMap['autorRole'] == 'admin';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: isAdmin
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.end,
                                      children: [
                                        if (isAdmin) ...[
                                          CircleAvatar(
                                            backgroundColor: AppColors.primary
                                                .withValues(alpha: 0.2),
                                            child: const Icon(
                                              Icons.support_agent,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: 400,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: isAdmin
                                                  ? LinearGradient(
                                                      colors: [
                                                        AppColors.primary
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        AppColors.primaryLight
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                      ],
                                                    )
                                                  : LinearGradient(
                                                      colors: [
                                                        AppColors.statusOpen
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        AppColors.statusOpen
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                      ],
                                                    ),
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(
                                                  16,
                                                ),
                                                topRight: const Radius.circular(
                                                  16,
                                                ),
                                                bottomLeft: Radius.circular(
                                                  isAdmin ? 4 : 16,
                                                ),
                                                bottomRight: Radius.circular(
                                                  isAdmin ? 16 : 4,
                                                ),
                                              ),
                                              border: Border.all(
                                                color: isAdmin
                                                    ? AppColors.primary
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                    : AppColors.statusOpen
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isAdmin
                                                            ? AppColors.primary
                                                            : AppColors
                                                                  .statusOpen,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        isAdmin ? 'TI' : 'Você',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      comentarioMap['autorNome'] ??
                                                          'Anônimo',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  comentarioMap['mensagem'] ??
                                                      '',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat(
                                                    'dd/MM/yy HH:mm',
                                                  ).format(
                                                    (comentarioMap['dataHora']
                                                                as dynamic)
                                                            ?.toDate() ??
                                                        DateTime.now(),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (!isAdmin) ...[
                                          const SizedBox(width: 8),
                                          CircleAvatar(
                                            backgroundColor: AppColors
                                                .statusOpen
                                                .withValues(alpha: 0.2),
                                            child: const Icon(
                                              Icons.person,
                                              color: AppColors.statusOpen,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo de adicionar comentário
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Adicionar um comentário...',
                                    border: InputBorder.none,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _addComment,
                                      icon: _isSubmitting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.send),
                                      label: const Text('Enviar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right side - Info & Actions
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      border: Border(
                        left: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ℹ️ Informações',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildInfoItem(
                            'Usuário',
                            widget.chamado.usuarioNome,
                            Icons.person,
                          ),
                          _buildInfoItem(
                            'Tipo',
                            widget.chamado.tipo,
                            Icons.category,
                          ),
                          _buildInfoItem(
                            'Criado em',
                            DateFormat(
                              'dd/MM/yy HH:mm',
                            ).format(widget.chamado.dataCriacao),
                            Icons.calendar_today,
                          ),
                          if (widget.chamado.dataFechamento != null)
                            _buildInfoItem(
                              'Fechado em',
                              DateFormat(
                                'dd/MM/yy HH:mm',
                              ).format(widget.chamado.dataFechamento!),
                              Icons.check_circle,
                            ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Ações Rápidas
                          const Text(
                            '⚡ Ações Rápidas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (widget.chamado.status != 'Em Andamento')
                            _buildActionButton(
                              'Iniciar Atendimento',
                              Icons.play_arrow,
                              AppColors.statusInProgress,
                              () => _updateStatus('Em Andamento'),
                            ),

                          if (widget.chamado.status == 'Em Andamento')
                            _buildActionButton(
                              'Marcar como Fechado',
                              Icons.check_circle,
                              AppColors.success,
                              () => _updateStatus('Fechado'),
                            ),

                          if (widget.chamado.status != 'Rejeitado')
                            _buildActionButton(
                              'Rejeitar',
                              Icons.cancel,
                              AppColors.error,
                              () => _updateStatus('Rejeitado'),
                            ),

                          if (widget.chamado.status == 'Fechado')
                            _buildActionButton(
                              'Reabrir Chamado',
                              Icons.refresh,
                              AppColors.warning,
                              () => _updateStatus('Aberto'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



