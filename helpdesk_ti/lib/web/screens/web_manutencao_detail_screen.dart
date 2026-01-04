import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/features/manutencao/services/manutencao_service.dart';
import 'package:helpdesk_ti/features/manutencao/models/chamado_manutencao_model.dart';

/// Tela de detalhes de chamado de manutenção para web
class WebManutencaoDetailScreen extends StatefulWidget {
  final ChamadoManutencao chamado;

  const WebManutencaoDetailScreen({super.key, required this.chamado});

  @override
  State<WebManutencaoDetailScreen> createState() =>
      _WebManutencaoDetailScreenState();
}

class _WebManutencaoDetailScreenState extends State<WebManutencaoDetailScreen> {
  final ManutencaoService _manutencaoService = ManutencaoService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final userRole = authService.userRole;
    final userId = authService.firebaseUser?.uid;
    final chamado = widget.chamado;

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.build,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chamado.numeroFormatado,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chamado.titulo,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(chamado.status.value, isDarkMode),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna esquerda - Detalhes
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoSection(
                                'Descrição',
                                chamado.descricao,
                                Icons.description,
                                isDarkMode,
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                'Criador',
                                chamado.criadorNome,
                                isDarkMode,
                              ),
                              _buildInfoRow(
                                'Data Abertura',
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(chamado.dataAbertura),
                                isDarkMode,
                              ),
                              if (chamado.dataFinalizacao != null)
                                _buildInfoRow(
                                  'Data Finalização',
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(chamado.dataFinalizacao!),
                                  isDarkMode,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Coluna direita - Orçamento e Aprovações
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Orçamento
                              if (chamado.orcamento != null) ...[
                                _buildSectionTitle('💰 Orçamento', isDarkMode),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (chamado.orcamento!.valorEstimado !=
                                          null)
                                        Text(
                                          'R\$ ${chamado.orcamento!.valorEstimado!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      if (chamado
                                          .orcamento!
                                          .itens
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Itens: ${chamado.orcamento!.itens.join(", ")}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Aprovação Gerente
                              if (chamado.aprovacaoGerente != null) ...[
                                _buildSectionTitle(
                                  '✅ Aprovação Gerente',
                                  isDarkMode,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: chamado.aprovacaoGerente!.aprovado
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            chamado.aprovacaoGerente!.aprovado
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color:
                                                chamado
                                                    .aprovacaoGerente!
                                                    .aprovado
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            chamado.aprovacaoGerente!.aprovado
                                                ? 'Aprovado'
                                                : 'Rejeitado',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  chamado
                                                      .aprovacaoGerente!
                                                      .aprovado
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Por: ${chamado.aprovacaoGerente!.gerenteNome}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Execução
                              if (chamado.execucao != null) ...[
                                _buildSectionTitle('🔧 Execução', isDarkMode),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Executor: ${chamado.execucao!.executorNome}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (chamado.execucao!.dataInicio !=
                                          null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Iniciado em: ${DateFormat('dd/MM/yyyy HH:mm').format(chamado.execucao!.dataInicio!)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActions(userRole, userId, chamado, isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    String? role,
    String? userId,
    ChamadoManutencao chamado,
    bool isDarkMode,
  ) {
    final actions = <Widget>[];
    final status = chamado.status.value;

    // Ações para Gerente
    if (role == 'manager' && status == 'aguardando_aprovacao_gerente') {
      actions.add(
        OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _rejectOrcamento(chamado),
          icon: const Icon(Icons.close, color: Colors.red),
          label: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
          ),
        ),
      );
      actions.add(const SizedBox(width: 12));
      actions.add(
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _approveOrcamento(chamado),
          icon: const Icon(Icons.check),
          label: const Text('Aprovar Orçamento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    // Ações para Admin Manutenção
    if (role == 'admin_manutencao') {
      if (status == 'aberto' || status == 'orcamento_aprovado') {
        actions.add(
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () => _showAtribuirExecutorDialog(chamado),
            icon: const Icon(Icons.person_add),
            label: const Text('Atribuir Executor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
    }

    // Ações para Executor
    if (role == 'executor' && chamado.execucao?.executorId == userId) {
      if (status == 'atribuido_executor') {
        actions.add(
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _iniciarExecucao(chamado),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Execução'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
      if (status == 'em_execucao') {
        actions.add(
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _concluirExecucao(chamado),
            icon: const Icon(Icons.check_circle),
            label: const Text('Concluir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
    }

    // Botão fechar sempre presente
    if (actions.isEmpty) {
      actions.add(
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      );
    } else {
      actions.insert(
        0,
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      );
      actions.insert(1, const SizedBox(width: 12));
    }

    return actions;
  }

  Widget _buildStatusBadge(String status, bool isDarkMode) {
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
        label = 'Aguardando Aprovação';
        break;
      case 'orcamento_aprovado':
        color = Colors.green;
        label = 'Orçamento Aprovado';
        break;
      case 'atribuido_executor':
        color = Colors.purple;
        label = 'Atribuído';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String content,
    IconData icon,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white54 : Colors.black54,
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

  Future<void> _approveOrcamento(ChamadoManutencao chamado) async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      await _manutencaoService.aprovarOrcamento(
        chamadoId: chamado.id,
        gerenteId: authService.firebaseUser?.uid ?? '',
        gerenteNome: authService.firebaseUser?.displayName ?? 'Gerente',
        aprovado: true,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento aprovado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectOrcamento(ChamadoManutencao chamado) async {
    final motivoController = TextEditingController();
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Rejeitar Orçamento',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: motivoController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Motivo da rejeição',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: isDarkMode ? Colors.white10 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
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
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final authService = context.read<AuthService>();
        await _manutencaoService.aprovarOrcamento(
          chamadoId: chamado.id,
          gerenteId: authService.firebaseUser?.uid ?? '',
          gerenteNome: authService.firebaseUser?.displayName ?? 'Gerente',
          aprovado: false,
          motivoRejeicao: motivoController.text,
        );
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orçamento rejeitado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAtribuirExecutorDialog(ChamadoManutencao chamado) async {
    // TODO: Implementar busca de executores disponíveis
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento...')),
    );
  }

  Future<void> _iniciarExecucao(ChamadoManutencao chamado) async {
    setState(() => _isLoading = true);
    try {
      await _manutencaoService.iniciarExecucao(chamado.id);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Execução iniciada!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _concluirExecucao(ChamadoManutencao chamado) async {
    // Na web, a finalização requer foto comprovante que só pode ser enviada pelo app mobile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Para concluir o chamado, use o aplicativo móvel (requer foto comprovante)',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }
}
