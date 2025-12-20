import 'package:flutter/material.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';

/// Tela para executor recusar chamado atribuído
class ManutencaoRecusarScreen extends StatefulWidget {
  final ChamadoManutencao chamado;

  const ManutencaoRecusarScreen({super.key, required this.chamado});

  @override
  State<ManutencaoRecusarScreen> createState() =>
      _ManutencaoRecusarScreenState();
}

class _ManutencaoRecusarScreenState extends State<ManutencaoRecusarScreen> {
  final ManutencaoService _manutencaoService = ManutencaoService();
  final AuthService _authService = AuthService();
  final TextEditingController _motivoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _recusar() async {
    // Validar motivo
    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ O motivo da recusa é obrigatório'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_motivoController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ O motivo deve ter pelo menos 10 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚫 Recusar Trabalho?'),
        content: Text(
          'Confirma a recusa deste trabalho?\n\n'
          'Motivo: ${_motivoController.text.trim()}\n\n'
          'O supervisor de manutenção será notificado e precisará atribuir outro executor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.firebaseUser;
      if (user == null) throw Exception('Usuário não autenticado');

      await _manutencaoService.recusarChamado(
        chamadoId: widget.chamado.id,
        executorId: user.uid,
        executorNome: _authService.userName ?? user.email ?? 'Executor',
        motivo: _motivoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chamado recusado'),
            backgroundColor: Colors.orange,
          ),
        );

        // Voltar para o dashboard
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WallpaperScaffold(
      appBar: AppBar(
        title: Text(
          '🚫 Recusar Trabalho',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de alerta
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Atenção! Ao recusar este trabalho, ele voltará para o supervisor atribuir outro executor.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informações do chamado
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.construction, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Trabalho a Ser Recusado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Título', widget.chamado.titulo),
                    _buildInfoRow('Descrição', widget.chamado.descricao),
                    _buildInfoRow('Solicitante', widget.chamado.criadorNome),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Campo de motivo
            const Text(
              'Motivo da Recusa *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explique por que você não pode executar este trabalho. O motivo será enviado ao supervisor.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivoController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Ex: Falta de equipamento adequado, sobrecarga de trabalho, problema de saúde, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _recusar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cancel),
                    label: const Text(
                      'RECUSAR TRABALHO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
