import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/features/ti/models/solicitacao.dart';
import '../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';

class SolicitacaoDetailsScreen extends StatefulWidget {
  final Solicitacao solicitacao;
  final FirestoreService firestoreService;
  final AuthService authService;

  const SolicitacaoDetailsScreen({
    super.key,
    required this.solicitacao,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<SolicitacaoDetailsScreen> createState() =>
      _SolicitacaoDetailsScreenState();
}

class _SolicitacaoDetailsScreenState extends State<SolicitacaoDetailsScreen> {
  bool _isLoading = false;

  Color _getStatusColor() {
    switch (widget.solicitacao.status) {
      case 'Pendente':
        return const Color(0xFFFFA726);
      case 'Aprovado':
        return const Color(0xFF4CAF50);
      case 'Reprovado':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy \'às\' HH:mm').format(date);
  }

  String _formatCurrency(double? value) {
    if (value == null) return 'Não informado';
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  Future<void> _atualizarStatus(String novoStatus) async {
    setState(() => _isLoading = true);

    try {
      final solicitacaoAtualizada = widget.solicitacao.copyWith(
        status: novoStatus,
        managerId: widget.authService.firebaseUser?.uid,
        managerNome: widget.authService.firebaseUser?.displayName ?? 'Gerente',
        dataAtualizacao: DateTime.now(),
      );

      await widget.firestoreService.atualizarSolicitacao(solicitacaoAtualizada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitação $novoStatus com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar solicitação: $e'),
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

  Future<void> _criarChamadoTecnico() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Chamado Técnico'),
        content: const Text(
          'Deseja criar um chamado técnico a partir desta solicitação aprovada?\n\n'
          'O chamado será enviado para a equipe de TI para execução.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Criar Chamado'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      // Criar chamado técnico baseado na solicitação
      final chamadoId = await widget.firestoreService.criarChamadoDeSolicitacao(
        solicitacao: widget.solicitacao,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Chamado técnico #$chamadoId criado com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao criar chamado: $e'),
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

  Future<void> _mostrarDialogoRejeicao() async {
    final motivoController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reprovar Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe o motivo da reprovação:'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
                hintText: 'Ex: Fora do orçamento, item desnecessário...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, informe o motivo da reprovação'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reprovar'),
          ),
        ],
      ),
    );

    if (resultado == true && motivoController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        final solicitacaoAtualizada = widget.solicitacao.copyWith(
          status: 'Reprovado',
          managerId: widget.authService.firebaseUser?.uid,
          managerNome:
              widget.authService.firebaseUser?.displayName ?? 'Gerente',
          dataAtualizacao: DateTime.now(),
          motivoRejeicao: motivoController.text.trim(),
        );

        await widget.firestoreService.atualizarSolicitacao(
          solicitacaoAtualizada,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitação reprovada!'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao reprovar solicitação: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final isManager = widget.authService.userRole == 'manager';
    final canEdit = isManager && widget.solicitacao.status == 'Pendente';

    return Container(
      color: isDarkMode ? DS.background : const Color(0xFFF5F7FA),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Detalhes da Solicitação',
            style: TextStyle(color: isDarkMode ? DS.textPrimary : Colors.white),
          ),
          backgroundColor: isDarkMode ? DS.card : AppColors.primary,
          iconTheme: IconThemeData(
            color: isDarkMode ? DS.textPrimary : Colors.white,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Principal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.solicitacao.titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusChip(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informações do Item
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações do Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.shopping_cart,
                        'Item Solicitado',
                        widget.solicitacao.itemSolicitado,
                      ),
                      _buildInfoRow(
                        Icons.attach_money,
                        'Custo Estimado',
                        _formatCurrency(widget.solicitacao.custoEstimado),
                      ),
                      _buildInfoRow(
                        Icons.business,
                        'Setor',
                        widget.solicitacao.setor,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Descrição',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.solicitacao.descricao),
                      const SizedBox(height: 12),
                      const Text(
                        'Justificativa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.solicitacao.justificativa),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informações do Solicitante
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solicitante',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.person,
                        'Nome',
                        widget.solicitacao.usuarioNome,
                      ),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Data da Solicitação',
                        _formatDate(widget.solicitacao.dataCriacao),
                      ),
                      if (widget.solicitacao.dataAtualizacao != null)
                        _buildInfoRow(
                          Icons.update,
                          'Última Atualização',
                          _formatDate(widget.solicitacao.dataAtualizacao!),
                        ),
                      if (widget.solicitacao.managerNome != null)
                        _buildInfoRow(
                          Icons.admin_panel_settings,
                          'Analisado por',
                          widget.solicitacao.managerNome!,
                        ),
                    ],
                  ),
                ),
              ),

              // Motivo da Reprovação
              if (widget.solicitacao.status == 'Reprovado' &&
                  widget.solicitacao.motivoRejeicao != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Motivo da Reprovação',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.solicitacao.motivoRejeicao!),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: canEdit ? _buildActionButtons() : null,
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          const SizedBox(width: 8),
          Text(
            widget.solicitacao.status,
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.solicitacao.status) {
      case 'Pendente':
        return Icons.pending;
      case 'Aprovado':
        return Icons.check_circle;
      case 'Reprovado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Se a solicitação foi aprovada, mostrar botão para criar chamado técnico
    if (widget.solicitacao.status == 'Aprovado') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _criarChamadoTecnico,
              icon: const Icon(Icons.engineering),
              label: const Text('Criar Chamado Técnico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      );
    }

    // Se pendente, mostrar botões de aprovar/reprovar
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _mostrarDialogoRejeicao,
                icon: const Icon(Icons.close),
                label: const Text('Reprovar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _atualizarStatus('Aprovado'),
                icon: const Icon(Icons.check),
                label: const Text('Aprovar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
