import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../models/manutencao_constants.dart';

/// Tela para executor criar chamado solicitando materiais
class ManutencaoCriarChamadoExecutorScreen extends StatefulWidget {
  const ManutencaoCriarChamadoExecutorScreen({super.key});

  @override
  State<ManutencaoCriarChamadoExecutorScreen> createState() =>
      _ManutencaoCriarChamadoExecutorScreenState();
}

class _ManutencaoCriarChamadoExecutorScreenState
    extends State<ManutencaoCriarChamadoExecutorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorEstimadoController = TextEditingController();
  final _itensController = TextEditingController();

  final _manutencaoService = ManutencaoService();
  final _authService = AuthService();

  File? _arquivoOrcamento;
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorEstimadoController.dispose();
    _itensController.dispose();
    super.dispose();
  }

  Future<void> _selecionarArquivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize >
            (ManutencaoConstants.maxTamanhoArquivoMB * 1024 * 1024)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Arquivo muito grande! Tamanho máximo: 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _arquivoOrcamento = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao selecionar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _criarChamado() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar se tem pelo menos um item de material
    if (_itensController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Liste pelo menos um material necessário'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.firebaseUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // PASSO 1: Preparar dados e criar chamado SEM arquivo
      final itens = _itensController.text
          .trim()
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      double? valorEstimado;
      if (_valorEstimadoController.text.trim().isNotEmpty) {
        valorEstimado = double.tryParse(
          _valorEstimadoController.text.trim().replaceAll(',', '.'),
        );
      }

      var orcamento = Orcamento(
        arquivoUrl: null, // Será atualizado depois
        valorEstimado: valorEstimado,
        itens: itens,
      );

      final chamadoId = await _manutencaoService.criarChamado(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        criadorId: user.uid,
        criadorNome: _authService.userName ?? user.email ?? 'Executor',
        criadorTipo: TipoCriadorChamado.executor,
        orcamento: orcamento,
        autoAtribuicao: true,
      );

      // PASSO 2: Se tem arquivo, fazer upload e atualizar
      if (_arquivoOrcamento != null) {
        final arquivoUrl = await _manutencaoService.uploadOrcamento(
          chamadoId,
          _arquivoOrcamento!,
        );

        orcamento = Orcamento(
          arquivoUrl: arquivoUrl,
          valorEstimado: valorEstimado,
          itens: itens,
        );

        await _manutencaoService.atualizarOrcamento(chamadoId, orcamento);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Solicitação criada! Após aprovação e chegada dos materiais, será automaticamente atribuída a você.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
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
    // DS cores usadas diretamente

    return WallpaperScaffold(
      appBar: AppBar(
        title: const Text(
          '🔨 Solicitar Materiais',
          style: TextStyle(color: DS.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: DS.textPrimary,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de informação
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Use este formulário para solicitar materiais necessários para um trabalho. Após a aprovação do gerente e a chegada dos materiais, o trabalho será automaticamente atribuído a você.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Título
              const Text(
                'Título *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tituloController,
                maxLength: ManutencaoConstants.tituloMaxLength,
                decoration: InputDecoration(
                  hintText: 'Ex: Materiais para reparo do telhado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite o título';
                  }
                  if (value.trim().length <
                      ManutencaoConstants.tituloMinLength) {
                    return 'Título deve ter pelo menos ${ManutencaoConstants.tituloMinLength} caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              const Text(
                'Descrição *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                maxLength: ManutencaoConstants.descricaoMaxLength,
                decoration: InputDecoration(
                  hintText:
                      'Descreva o trabalho que precisa ser realizado e por que esses materiais são necessários...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite a descrição';
                  }
                  if (value.trim().length <
                      ManutencaoConstants.descricaoMinLength) {
                    return 'Descrição deve ter pelo menos ${ManutencaoConstants.descricaoMinLength} caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Seção de orçamento
              const Text(
                '💰 Orçamento dos Materiais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Arquivo do orçamento
              const Text(
                'Documento do Orçamento (opcional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (_arquivoOrcamento != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _arquivoOrcamento!.path.split('/').last,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _arquivoOrcamento = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _selecionarArquivo,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Anexar Documento (PDF, DOC, DOCX)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Valor estimado
              const Text(
                'Valor Estimado (opcional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valorEstimadoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final numero = double.tryParse(value.replaceAll(',', '.'));
                    if (numero == null || numero <= 0) {
                      return 'Digite um valor válido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Lista de materiais
              const Text(
                'Lista de Materiais *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Digite um material por linha',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itensController,
                maxLines: 6,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'Ex:\nTelhas de cerâmica (100 unidades)\nArgamassa (5 sacos)\nPregos (1 kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Liste os materiais necessários';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão criar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _criarChamado,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text(
                    'ENVIAR SOLICITAÇÃO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


