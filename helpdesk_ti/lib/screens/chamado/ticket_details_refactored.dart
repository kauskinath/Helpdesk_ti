import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../widgets/chamado/status_badge.dart';
import '../../widgets/chamado/comentarios_paginados_widget.dart';
import '../../widgets/avaliacao/avaliacao_chamado_widget.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';

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
        return const Color(0xFF4CAF50);
      case 'Em Andamento':
        return const Color(0xFF2196F3);
      case 'Pendente Aprovação':
      case 'Aguardando':
        return const Color(0xFFFFA726);
      case 'Fechado':
        return const Color(0xFF9E9E9E);
      case 'Rejeitado':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
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
        return const Color(0xFF66BB6A);
      case 2:
        return const Color(0xFF42A5F5);
      case 3:
        return const Color(0xFFFF9800);
      case 4:
        return const Color(0xFFEF5350);
      default:
        return Colors.blue;
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      body: Container(
        color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.chamado.numeroFormatado,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                    // Botão de deletar (apenas para admin TI)
                    if (isAdmin)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _confirmarExclusao(context),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card principal com informações
                      _buildInfoCard(),
                      const SizedBox(height: 16),

                      // Prioridade do chamado (apenas visualização, não editável)
                      _buildPriorityDisplay(),
                      const SizedBox(height: 16),

                      // Botões de ação (admin pode aceitar/recusar se Aberto, ou finalizar se Em Andamento)
                      if (canEditStatus || canFinalize) ...[
                        _buildActionButtons(canEditStatus, canFinalize),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data de criação
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Text(
                'Criado em ${DateFormat('dd/MM/yyyy \'\u00e0s\' HH:mm').format(widget.chamado.dataCriacao)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Última atualização
          if (widget.chamado.dataAtualizacao != null)
            Row(
              children: [
                const Icon(Icons.update, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Atualizado em ${DateFormat('dd/MM/yyyy \'\u00e0s\' HH:mm').format(widget.chamado.dataAtualizacao!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Status badge
          StatusBadge(status: widget.chamado.status),
          const SizedBox(height: 16),

          // Título (sem prefixo SERVIÇO)
          Text(
            widget.chamado.titulo
                .replaceFirst('Serviço - ', '')
                .replaceFirst('Solicitação - ', ''),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Solicitante
          _buildInfoRow(
            Icons.person,
            'Solicitante',
            widget.chamado.usuarioNome,
          ),
          const SizedBox(height: 12),

          // Responsável (se houver)
          if (widget.chamado.adminNome != null &&
              widget.chamado.adminNome!.isNotEmpty)
            _buildInfoRow(
              Icons.engineering,
              'Responsável TI',
              widget.chamado.adminNome!,
            ),
          const SizedBox(height: 12),

          // Setor
          _buildInfoRow(Icons.business, 'Setor', widget.chamado.setor),
          const SizedBox(height: 16),

          // Descrição
          Text(
            'Descrição',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.chamado.descricao,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),

          // Anexos/Fotos (se houver)
          if (widget.chamado.anexos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Anexos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
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
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Motivo da Rejeição',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.chamado.motivoRejeicao!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.flag, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prioridade',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
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
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Aceitar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _mostrarDialogoRejeicao,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Recusar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
              icon: const Icon(Icons.done_all),
              label: const Text('Finalizar Chamado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComentariosSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isClosed = widget.chamado.status == 'Fechado';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withAlpha(8)
            : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withAlpha(15) : Colors.grey.shade200,
        ),
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
                  color: isDarkMode
                      ? const Color(0xFF2196F3).withAlpha(30)
                      : const Color(0xFF2196F3).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: isDarkMode
                      ? const Color(0xFF64B5F6)
                      : const Color(0xFF2196F3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      isClosed
                          ? 'Este chamado foi encerrado'
                          : 'Troque mensagens com a TI',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Colors.white54
                            : Colors.grey.shade600,
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
                      ? Colors.grey.withAlpha(50)
                      : Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isClosed ? Icons.lock : Icons.circle,
                      size: isClosed ? 14 : 8,
                      color: isClosed ? Colors.grey : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isClosed ? 'Encerrado' : 'Ativo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isClosed ? Colors.grey : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(color: isDarkMode ? Colors.white12 : Colors.grey.shade200),

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
                color: isDarkMode
                    ? Colors.grey.withAlpha(30)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.withAlpha(50)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chamado fechado. Não é possível enviar mensagens.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white38 : Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            // Campo de entrada de mensagem (estilo WhatsApp)
            Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withAlpha(10)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withAlpha(20)
                      : Colors.grey.shade300,
                ),
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
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white38
                              : Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),

                  // Botão de enviar
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: Material(
                      color: const Color(0xFF2196F3),
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
