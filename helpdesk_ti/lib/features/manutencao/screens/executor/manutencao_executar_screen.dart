import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';

/// Tela para executor iniciar, executar e finalizar chamado
class ManutencaoExecutarScreen extends StatefulWidget {
  final ChamadoManutencao chamado;

  const ManutencaoExecutarScreen({super.key, required this.chamado});

  @override
  State<ManutencaoExecutarScreen> createState() =>
      _ManutencaoExecutarScreenState();
}

class _ManutencaoExecutarScreenState extends State<ManutencaoExecutarScreen> {
  final ManutencaoService _manutencaoService = ManutencaoService();
  final ImagePicker _picker = ImagePicker();

  File? _fotoComprovante;
  bool _isLoading = false;

  Future<void> _iniciarExecucao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('▶️ Iniciar Execução?'),
        content: const Text(
          'Confirma o início da execução deste trabalho?\n\n'
          'O status será alterado para "Em Execução".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      await _manutencaoService.iniciarExecucao(widget.chamado.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Execução iniciada!'),
            backgroundColor: Colors.green,
          ),
        );
        // Recarregar a tela
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ManutencaoExecutarScreen(chamado: widget.chamado),
          ),
        );
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

  Future<void> _tirarFoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _fotoComprovante = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao tirar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selecionarFotoGaleria() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _fotoComprovante = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao selecionar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finalizarChamado() async {
    // Validar foto
    if (_fotoComprovante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ A foto comprovante é obrigatória!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Finalizar Trabalho?'),
        content: const Text(
          'Confirma a finalização deste trabalho?\n\n'
          'A foto comprovante será enviada e o chamado será marcado como concluído.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      await _manutencaoService.finalizarChamado(
        chamadoId: widget.chamado.id,
        fotoComprovante: _fotoComprovante!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabalho finalizado com sucesso!'),
            backgroundColor: Colors.green,
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
    final bool jaIniciado =
        widget.chamado.status == StatusChamadoManutencao.emExecucao;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WallpaperScaffold(
      appBar: AppBar(
        title: Text(
          '🔧 Executar Trabalho',
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
            // Card de informações do chamado
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
                          'Informações do Trabalho',
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
                    if (widget.chamado.orcamento != null &&
                        widget.chamado.orcamento!.itens.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '📦 Materiais:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...widget.chamado.orcamento!.itens.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card de status
            Card(
              color: jaIniciado ? Colors.orange.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      jaIniciado ? Icons.build : Icons.play_circle_outline,
                      color: jaIniciado ? Colors.orange : Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jaIniciado ? 'Em Execução' : 'Pronto para Iniciar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: jaIniciado ? Colors.orange : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jaIniciado
                                ? 'Tire uma foto do trabalho concluído para finalizar'
                                : 'Clique em "Iniciar" para começar o trabalho',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seção de foto comprovante (apenas se já iniciado)
            if (jaIniciado) ...[
              const Text(
                '📷 Foto Comprovante *',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tire uma foto do trabalho concluído. Esta foto é obrigatória para finalizar o chamado.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Preview da foto ou botões para tirar/selecionar
              if (_fotoComprovante != null) ...[
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _fotoComprovante!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _fotoComprovante = null;
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Remover'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _tirarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tirar Outra'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selecionarFotoGaleria,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Da Galeria'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _tirarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tirar Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Botão de ação principal
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : (jaIniciado ? _finalizarChamado : _iniciarExecucao),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(jaIniciado ? Icons.check_circle : Icons.play_arrow),
                label: Text(
                  jaIniciado ? 'FINALIZAR TRABALHO' : 'INICIAR EXECUÇÃO',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: jaIniciado ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
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
