import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';
import '../../services/manutencao_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../models/chamado_manutencao_model.dart';

/// Tela para gerente aprovar ou rejeitar orçamento de manutenção
class ManutencaoAprovarOrcamentoScreen extends StatefulWidget {
  final ChamadoManutencao chamado;

  const ManutencaoAprovarOrcamentoScreen({super.key, required this.chamado});

  @override
  State<ManutencaoAprovarOrcamentoScreen> createState() =>
      _ManutencaoAprovarOrcamentoScreenState();
}

class _ManutencaoAprovarOrcamentoScreenState
    extends State<ManutencaoAprovarOrcamentoScreen> {
  final ManutencaoService _manutencaoService = ManutencaoService();
  final AuthService _authService = AuthService();
  final TextEditingController _motivoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _aprovarOuRejeitar(bool aprovado) async {
    // Validar motivo se for rejeitar
    if (!aprovado && _motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Digite o motivo da rejeição'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmar ação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          aprovado ? '✅ Aprovar Orçamento?' : '❌ Rejeitar Orçamento?',
        ),
        content: Text(
          aprovado
              ? 'Confirma a aprovação deste orçamento? O processo de compra será iniciado.'
              : 'Confirma a rejeição deste orçamento? O chamado será cancelado.\n\nMotivo: ${_motivoController.text.trim()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: aprovado ? Colors.green : Colors.red,
            ),
            child: Text(aprovado ? 'APROVAR' : 'REJEITAR'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.firebaseUser;
      if (user == null) throw Exception('Usuário não autenticado');

      await _manutencaoService.aprovarOrcamento(
        chamadoId: widget.chamado.id,
        gerenteId: user.uid,
        gerenteNome: _authService.userName ?? user.email ?? 'Gerente',
        aprovado: aprovado,
        motivoRejeicao: aprovado ? null : _motivoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aprovado
                  ? '✅ Orçamento aprovado com sucesso!'
                  : '❌ Orçamento rejeitado',
            ),
            backgroundColor: aprovado ? Colors.green : Colors.red,
          ),
        );
        // Voltar 2 telas (para o dashboard)
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // DS cores usadas diretamente

    return WallpaperScaffold(
      appBar: AppBar(
        title: const Text(
          'Aprovar Orçamento',
          style: TextStyle(color: DS.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: DS.textPrimary,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card de instrução
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Analise cuidadosamente o orçamento e decida se deve ser aprovado ou rejeitado.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informações do Chamado
            _buildSecao('📋 Informações do Chamado', [
              _buildInfoRow('Título', widget.chamado.titulo),
              _buildInfoRow('Descrição', widget.chamado.descricao),
              _buildInfoRow('Solicitado por', widget.chamado.criadorNome),
              _buildInfoRow(
                'Data de Abertura',
                _formatarData(widget.chamado.dataAbertura),
              ),
              if (widget.chamado.adminValidadorNome != null)
                _buildInfoRow(
                  'Validado por',
                  widget.chamado.adminValidadorNome!,
                ),
            ]),
            const SizedBox(height: 16),

            // Orçamento Detalhado
            if (widget.chamado.orcamento != null) ...[
              _buildSecao('💰 Detalhes do Orçamento', [
                if (widget.chamado.orcamento!.valorEstimado != null) ...[
                  const Text(
                    'Valor Estimado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${widget.chamado.orcamento!.valorEstimado!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.chamado.orcamento!.arquivoUrl != null)
                  _buildLinkButton(
                    '📄 Visualizar Documento do Orçamento',
                    widget.chamado.orcamento!.arquivoUrl!,
                  ),
                if (widget.chamado.orcamento!.link != null)
                  _buildLinkButton(
                    '🔗 Abrir Link Externo',
                    widget.chamado.orcamento!.link!,
                  ),
                if (widget.chamado.orcamento!.itens.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '📦 Lista de Materiais Necessários:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...widget.chamado.orcamento!.itens.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 16),
            ],

            // Card de próximo passo
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_forward, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Próximo Passo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✅ Se APROVAR: O supervisor de manutenção iniciará o processo de compra dos materiais.\n\n'
                      '❌ Se REJEITAR: O chamado será cancelado e o solicitante será notificado com o motivo.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Campo de motivo da rejeição
            const Text(
              'Motivo da Rejeição (obrigatório apenas se rejeitar)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _motivoController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Ex: Valor acima do orçamento aprovado, materiais desnecessários, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _aprovarOuRejeitar(false),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'REJEITAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _aprovarOuRejeitar(true),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text(
                      'APROVAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecao(String titulo, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Não foi possível abrir o link'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }
}


