import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../widgets/chamado/comentarios_paginados_widget.dart';
import '../../widgets/avaliacao/avaliacao_chamado_widget.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';

class TicketDetailsRefactored extends StatefulWidget {
  final Chamado chamado;
  final FirestoreService firestoreService;
  final AuthService authService;

  const TicketDetailsRefactored({
    super.key,
    required this.chamado,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<TicketDetailsRefactored> createState() =>
      _TicketDetailsRefactoredState();
}

class _TicketDetailsRefactoredState extends State<TicketDetailsRefactored> {
  bool _isLoading = false;
  final TextEditingController _comentarioController = TextEditingController();
  final GlobalKey _comentariosKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.chamado.status) {
      case 'Aberto':
        return DS.success;
      case 'Em Andamento':
        return DS.action;
      case 'Pendente Aprovação':
      case 'Aguardando':
        return DS.warning;
      case 'Fechado':
        return DS.textSecondary;
      case 'Rejeitado':
        return DS.error;
      default:
        return DS.textSecondary;
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

  Color _getPriorityColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return DS.success;
      case 2:
        return DS.action;
      case 3:
        return DS.warning;
      case 4:
        return DS.error;
      default:
        return DS.action;
    }
  }

  Future<void> _atualizarStatus(String novoStatus, {String? motivo}) async {
    setState(() => _isLoading = true);

    try {
      final adminId = widget.authService.firebaseUser?.uid ?? '';
      final adminNome = widget.authService.firebaseUser?.displayName ?? 'Admin';

      final chamadoAtualizado = Chamado(
        id: widget.chamado.id,
        numero: widget.chamado.numero,
        titulo: widget.chamado.titulo,
        descricao: widget.chamado.descricao,
        setor: widget.chamado.setor,
        tipo: widget.chamado.tipo,
        status: novoStatus,
        usuarioId: widget.chamado.usuarioId,
        usuarioNome: widget.chamado.usuarioNome,
        adminId: adminId,
        adminNome: adminNome,
        linkOuEspecificacao: widget.chamado.linkOuEspecificacao,
        anexos: widget.chamado.anexos,
        custoEstimado: widget.chamado.custoEstimado,
        dataCriacao: widget.chamado.dataCriacao,
        dataAtualizacao: DateTime.now(),
        dataFechamento: novoStatus == 'Fechado'
            ? DateTime.now()
            : widget.chamado.dataFechamento,
        motivoRejeicao: motivo ?? widget.chamado.motivoRejeicao,
        prioridade: widget.chamado.prioridade,
      );

      await widget.firestoreService.atualizarChamadoCompleto(chamadoAtualizado);

      // Adicionar comentário automático de mudança de status
      await widget.firestoreService.adicionarComentario(
        chamadoId: widget.chamado.id,
        autorId: adminId,
        autorNome: adminNome,
        autorRole: 'admin',
        mensagem: motivo != null
            ? 'Status alterado para "$novoStatus". Motivo: $motivo'
            : 'Status alterado para "$novoStatus"',
        tipo: 'mudanca_status',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status atualizado para: $novoStatus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _adicionarComentario() async {
    if (_comentarioController.text.trim().isEmpty) return;

    final userId = widget.authService.firebaseUser?.uid ?? '';
    final userName = widget.authService.firebaseUser?.displayName ?? 'Usuário';
    final userRole = widget.authService.userRole ?? 'user';

    try {
      await widget.firestoreService.adicionarComentario(
        chamadoId: widget.chamado.id,
        autorId: userId,
        autorNome: userName,
        autorRole: userRole,
        mensagem: _comentarioController.text.trim(),
        tipo: 'comentario',
      );

      _comentarioController.clear();

      // Recarregar comentários automaticamente
      if (mounted) {
        final state = _comentariosKey.currentState as dynamic;
        await state?.recarregar();
      }

      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atualização adicionada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _mostrarDialogoRejeicao() async {
    final TextEditingController motivoController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Rejeitar Chamado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor, informe o motivo da rejeição:'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Motivo da rejeição...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, informe o motivo'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _atualizarStatus(
                'Rejeitado',
                motivo: motivoController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.authService.userRole == 'admin';
    final canEditStatus = isAdmin && widget.chamado.status == 'Aberto';
    final canFinalize = isAdmin && widget.chamado.status == 'Em Andamento';

    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Apenas ID e lixeira
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: DS.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DS.border, width: 1),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: DS.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.chamado.numeroFormatado,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DS.textPrimary,
                      ),
                    ),
                  ),
                  // Botão de deletar (apenas para admin TI)
                  if (isAdmin)
                    Container(
                      decoration: BoxDecoration(
                        color: DS.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DS.border, width: 1),
                      ),
                      child: IconButton(
                        onPressed: () => _confirmarExclusao(context),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: DS.error,
                          size: 28,
                        ),
                        tooltip: 'Deletar chamado',
                      ),
                    ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card principal com informações
                    _buildInfoCard(),
                    const SizedBox(height: 16),

                    // Prioridade do chamado
                    _buildPriorityDisplay(),
                    const SizedBox(height: 16),

                    // Botões Aceitar/Recusar (apenas se Aberto)
                    if (canEditStatus) ...[
                      _buildActionButtons(canEditStatus, false),
                      const SizedBox(height: 16),
                    ],

                    // Widget de avaliação (apenas para usuário comum em chamados fechados)
                    if (!isAdmin && widget.chamado.status == 'Fechado')
                      AvaliacaoChamadoWidget(
                        chamado: widget.chamado,
                        onAvaliacaoEnviada: () {
                          // Pode recarregar a tela se necessário
                        },
                      ),

                    // Seção de atualizações (sempre visível após aceitar o chamado)
                    if (widget.chamado.status != 'Aberto') ...[
                      _buildComentariosSection(),
                    ],

                    // Espaço extra para o botão fixo no rodapé
                    if (canFinalize) const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Botão Finalizar Chamado fixo no rodapé
      bottomNavigationBar: canFinalize
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: DS.card,
                border: Border(top: BorderSide(color: DS.border, width: 1)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _atualizarStatus('Fechado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DS.action,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Finalizar Chamado',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoCard() {
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(DS.cardRadius),
        border: Border.all(color: DS.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status e Prioridade Badges no topo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.chamado.status,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    widget.chamado.prioridade,
                  ).withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPriorityLabel(widget.chamado.prioridade),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(widget.chamado.prioridade),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Datas
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: DS.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Criado em ${DateFormat('dd/MM/yyyy \'\u00e0s\' HH:mm').format(widget.chamado.dataCriacao)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: DS.textSecondary,
                ),
              ),
            ],
          ),
          if (widget.chamado.dataAtualizacao != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.update_outlined,
                  size: 16,
                  color: DS.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Atualizado em ${DateFormat('dd/MM/yyyy \'\u00e0s\' HH:mm').format(widget.chamado.dataAtualizacao!)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: DS.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Título
          Text(
            widget.chamado.titulo
                .replaceFirst('Serviço - ', '')
                .replaceFirst('Solicitação - ', ''),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DS.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Card de Pessoas (Solicitante, Responsável, Setor)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DS.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DS.border, width: 1),
            ),
            child: Column(
              children: [
                // Solicitante
                _buildInfoRowCompact(
                  Icons.person_outline,
                  'Solicitante',
                  widget.chamado.usuarioNome,
                ),
                const SizedBox(height: 16),
                // Responsável TI (se houver)
                if (widget.chamado.adminNome != null &&
                    widget.chamado.adminNome!.isNotEmpty) ...[
                  _buildInfoRowCompact(
                    Icons.engineering_outlined,
                    'Responsável TI',
                    widget.chamado.adminNome!,
                  ),
                  const SizedBox(height: 16),
                ],
                // Setor
                _buildInfoRowCompact(
                  Icons.business_outlined,
                  'Setor',
                  widget.chamado.setor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Descrição
          const Text(
            'Descrição',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DS.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.chamado.descricao,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              height: 1.6,
              color: DS.textSecondary,
            ),
          ),
          // Anexos/Fotos (se houver)
          if (widget.chamado.anexos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Anexos',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DS.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.chamado.anexos.map((anexoUrl) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          children: [
                            Center(
                              child: InteractiveViewer(
                                child: CachedNetworkImage(
                                  imageUrl: anexoUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 32),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: anexoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image, size: 32),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Motivo de rejeição (se houver)
          if (widget.chamado.motivoRejeicao != null &&
              widget.chamado.motivoRejeicao!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DS.error.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DS.error, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: DS.error, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Motivo da Rejeição',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: DS.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.chamado.motivoRejeicao!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Widget compacto para informações agrupadas (ícones outlined)
  Widget _buildInfoRowCompact(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DS.textTertiary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: DS.textTertiary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DS.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de exibição da prioridade (apenas visualização, não editável)
  Widget _buildPriorityDisplay() {
    final prioridade = widget.chamado.prioridade;
    final color = _getPriorityColor(prioridade);
    final label = _getPriorityLabel(prioridade);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(DS.cardRadius),
        border: Border.all(color: DS.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.flag, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prioridade',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: DS.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool showAcceptReject, bool showFinalize) {
    return Column(
      children: [
        // Botões Aceitar e Recusar (apenas se status == Aberto)
        if (showAcceptReject)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _atualizarStatus('Em Andamento'),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Aceitar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.buttonRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _mostrarDialogoRejeicao,
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    'Recusar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.buttonRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),

        // Espaço entre botões
        if (showAcceptReject && showFinalize) const SizedBox(height: 8),

        // Botão Finalizar (apenas se status == Em Andamento)
        if (showFinalize)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _atualizarStatus('Fechado'),
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text(
                'Finalizar Chamado',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DS.action,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.buttonRadius),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComentariosSection() {
    final isClosed = widget.chamado.status == 'Fechado';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(DS.cardRadius),
        border: Border.all(color: DS.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho estilo chat
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DS.action.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: DS.action,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conversa',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DS.textPrimary,
                      ),
                    ),
                    Text(
                      isClosed
                          ? 'Este chamado foi encerrado'
                          : 'Troque mensagens com a TI',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: DS.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status da conversa
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isClosed
                      ? DS.textTertiary.withAlpha(38)
                      : DS.success.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isClosed ? Icons.lock : Icons.circle,
                      size: isClosed ? 14 : 8,
                      color: isClosed ? DS.textTertiary : DS.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isClosed ? 'Encerrado' : 'Ativo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isClosed ? DS.textTertiary : DS.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          const Divider(color: DS.border),

          const SizedBox(height: 12),

          // Timeline de comentários com paginação (estilo chat)
          ComentariosPaginadosWidget(
            key: _comentariosKey,
            chamadoId: widget.chamado.id,
            firestoreService: widget.firestoreService,
          ),

          const SizedBox(height: 16),

          // Campo de texto para adicionar comentário (desabilitado se fechado)
          if (isClosed)
            // Mensagem de chamado encerrado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DS.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: DS.textTertiary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chamado fechado. Não é possível enviar mensagens.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: DS.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Campo de entrada de mensagem (estilo WhatsApp)
            Container(
              decoration: BoxDecoration(
                color: DS.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DS.border, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _comentarioController,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: DS.textTertiary,
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: DS.card,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: DS.textPrimary,
                      ),
                    ),
                  ),

                  // Botão de enviar
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: Material(
                      color: DS.action,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _adicionarComentario,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Confirma exclusão do chamado
  Future<void> _confirmarExclusao(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja deletar este chamado?\n\n'
          'Esta ação irá remover:\n'
          '• O chamado do Firestore\n'
          '• Todos os comentários\n'
          '• Todas as avaliações\n'
          '• Todos os arquivos do Storage\n\n'
          '⚠️ ESTA AÇÃO NÃO PODE SER DESFEITA!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await widget.firestoreService.deletarChamadoTI(widget.chamado.id);

        if (context.mounted) {
          Navigator.pop(context); // Fechar loading
          Navigator.pop(context); // Voltar para lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Chamado deletado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Fechar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao deletar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
