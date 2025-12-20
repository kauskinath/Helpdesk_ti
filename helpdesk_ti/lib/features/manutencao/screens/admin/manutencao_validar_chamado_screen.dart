import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';

/// Tela para admin validar chamado
class ManutencaoValidarChamadoScreen extends StatefulWidget {
  final ChamadoManutencao chamado;

  const ManutencaoValidarChamadoScreen({super.key, required this.chamado});

  @override
  State<ManutencaoValidarChamadoScreen> createState() =>
      _ManutencaoValidarChamadoScreenState();
}

class _ManutencaoValidarChamadoScreenState
    extends State<ManutencaoValidarChamadoScreen> {
  final _manutencaoService = ManutencaoService();
  final _authService = AuthService();

  bool _isLoading = false;

  Future<void> _validar(bool aprovado) async {
    // Confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(aprovado ? '✅ Validar Chamado?' : '❌ Rejeitar Chamado?'),
        content: Text(
          aprovado
              ? 'Confirma a validação deste chamado? Ele seguirá para o próximo passo do fluxo.'
              : 'Confirma a rejeição deste chamado? Ele será cancelado.',
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
            child: Text(aprovado ? 'Validar' : 'Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.firebaseUser;
      if (user == null) throw 'Usuário não autenticado';

      await _manutencaoService.validarChamado(
        chamadoId: widget.chamado.id,
        adminId: user.uid,
        adminNome: _authService.userName ?? user.email ?? 'Admin',
        aprovado: aprovado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aprovado
                  ? '✅ Chamado validado com sucesso!'
                  : '❌ Chamado rejeitado',
            ),
            backgroundColor: aprovado ? Colors.green : Colors.red,
          ),
        );

        // Voltar duas telas
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chamado = widget.chamado;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WallpaperScaffold(
      appBar: AppBar(
        title: Text(
          '🔍 Validar Chamado',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de informação
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Analise o chamado e decida se ele deve prosseguir ou ser rejeitado.',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Informações do chamado
                  _buildSecao('📋 Informações Básicas', [
                    _buildInfoRow('Título', chamado.titulo),
                    _buildInfoRow('Descrição', chamado.descricao),
                    _buildInfoRow('Criado por', chamado.criadorNome),
                    _buildInfoRow('Data', _formatarData(chamado.dataAbertura)),
                  ]),
                  const SizedBox(height: 16),

                  // Orçamento
                  if (chamado.orcamento != null) ...[
                    _buildSecao('💰 Orçamento', [
                      if (chamado.orcamento!.valorEstimado != null)
                        _buildInfoRow(
                          'Valor Estimado',
                          'R\$ ${chamado.orcamento!.valorEstimado!.toStringAsFixed(2)}',
                        ),
                      if (chamado.orcamento!.arquivoUrl != null)
                        _buildInfoRow('Arquivo', 'PDF/DOCX anexado'),
                      if (chamado.orcamento!.link != null)
                        _buildInfoRow('Link', chamado.orcamento!.link!),
                      if (chamado.orcamento!.itens.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '📦 Materiais:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...chamado.orcamento!.itens.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              top: 4.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Próximo passo
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Próximo Passo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chamado.orcamento != null
                                ? '✅ Se VALIDAR: Vai para aprovação do gerente\n'
                                      '❌ Se REJEITAR: Chamado será cancelado'
                                : '✅ Se VALIDAR: Vai direto para execução\n'
                                      '❌ Se REJEITAR: Chamado será cancelado',
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => _validar(false),
                          icon: const Icon(Icons.cancel),
                          label: const Text('REJEITAR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _validar(true),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('VALIDAR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }
}
