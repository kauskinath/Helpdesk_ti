import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../models/manutencao_constants.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';

/// Tela para usuário comum criar chamado de manutenção
class ManutencaoCriarChamadoScreen extends StatefulWidget {
  const ManutencaoCriarChamadoScreen({super.key});

  @override
  State<ManutencaoCriarChamadoScreen> createState() =>
      _ManutencaoCriarChamadoScreenState();
}

class _ManutencaoCriarChamadoScreenState
    extends State<ManutencaoCriarChamadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorEstimadoController = TextEditingController();
  final _itensController = TextEditingController();

  final _manutencaoService = ManutencaoService();
  final _authService = AuthService();

  bool _temOrcamento = false;
  bool _isLoading = false;
  File? _arquivoOrcamento;
  String? _nomeArquivo;
  // ignore: prefer_final_fields
  List<File> _fotos = [];
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorEstimadoController.dispose();
    _itensController.dispose();
    super.dispose();
  }

  Future<void> _mostrarOpcoesFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: DS.card,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: DS.action),
              title: const Text(
                '📷 Tirar Foto',
                style: TextStyle(color: DS.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _adicionarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: DS.success),
              title: const Text(
                '🖼️ Escolher da Galeria',
                style: TextStyle(color: DS.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _adicionarFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: DS.error),
              title: const Text(
                'Cancelar',
                style: TextStyle(color: DS.textSecondary),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adicionarFoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _fotos.add(File(image.path));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Foto adicionada! Total: ${_fotos.length}'),
              backgroundColor: DS.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao capturar foto: $e'),
            backgroundColor: DS.error,
          ),
        );
      }
    }
  }

  void _removerFoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Foto removida'),
        backgroundColor: DS.warning,
      ),
    );
  }

  Future<void> _selecionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ManutencaoConstants.extensoesOrcamento,
      );

      if (result != null) {
        setState(() {
          _arquivoOrcamento = File(result.files.single.path!);
          _nomeArquivo = result.files.single.name;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Arquivo selecionado: $_nomeArquivo'),
              backgroundColor: DS.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao selecionar arquivo: $e'),
            backgroundColor: DS.error,
          ),
        );
      }
    }
  }

  Future<void> _criarChamado() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.firebaseUser;
      if (user == null) throw 'Usuário não autenticado';

      // PASSO 1: Criar chamado SEM arquivo primeiro
      Orcamento? orcamento;

      if (_temOrcamento) {
        double? valorEstimado;
        if (_valorEstimadoController.text.isNotEmpty) {
          valorEstimado = double.tryParse(
            _valorEstimadoController.text.replaceAll(',', '.'),
          );
        }

        List<String> itens = [];
        if (_itensController.text.isNotEmpty) {
          itens = _itensController.text
              .split('\n')
              .where((item) => item.trim().isNotEmpty)
              .map((item) => item.trim())
              .toList();
        }

        orcamento = Orcamento(
          arquivoUrl: null, // Será atualizado depois
          valorEstimado: valorEstimado,
          itens: itens,
        );
      }

      final chamadoId = await _manutencaoService.criarChamado(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        criadorId: user.uid,
        criadorNome:
            _authService.userName ??
            user.displayName ??
            user.email ??
            'Usuário',
        // Se for executor, usar tipo executor para que o chamado apareça na lista dele
        criadorTipo: _authService.isExecutor
            ? TipoCriadorChamado.executor
            : TipoCriadorChamado.usuarioComum,
        orcamento: orcamento,
        // Auto-atribuir ao executor se for ele criando
        autoAtribuicao: _authService.isExecutor,
      );

      // PASSO 2: Se tem arquivo, fazer upload e atualizar
      if (_temOrcamento && _arquivoOrcamento != null) {
        final arquivoUrl = await _manutencaoService.uploadOrcamento(
          chamadoId,
          _arquivoOrcamento!,
        );

        orcamento = Orcamento(
          arquivoUrl: arquivoUrl,
          valorEstimado: orcamento?.valorEstimado,
          itens: orcamento?.itens ?? [],
        );

        await _manutencaoService.atualizarOrcamento(chamadoId, orcamento);
      }

      // PASSO 3: Se tem fotos, fazer upload
      if (_fotos.isNotEmpty) {
        final fotosUrls = await _manutencaoService.uploadFotos(
          chamadoId,
          _fotos,
        );

        await _manutencaoService.atualizarFotos(chamadoId, fotosUrls);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chamado criado com sucesso!'),
            backgroundColor: DS.success,
          ),
        );

        // Voltar para tela anterior
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao criar chamado: $e'),
            backgroundColor: DS.error,
          ),
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
    final userName = _authService.userName ?? 'Usuário';
    // DS cores usadas diretamente

    return WallpaperScaffold(
      appBar: AppBar(
        title: Text(
          '🔧 $userName - Criar Chamado',
          style: const TextStyle(color: DS.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: DS.textPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextFormField(
                      controller: _tituloController,
                      style: const TextStyle(color: DS.textPrimary),
                      decoration: InputDecoration(
                        labelText: '📝 Título *',
                        labelStyle: const TextStyle(color: DS.textSecondary),
                        hintText: 'Ex: Reparo no portão principal',
                        hintStyle: const TextStyle(color: DS.textTertiary),
                        filled: true,
                        fillColor: DS.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DS.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DS.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: DS.action,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.title,
                          color: DS.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        counterStyle: const TextStyle(color: DS.textTertiary),
                      ),
                      maxLength: ManutencaoConstants.tituloMaxLength,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return ManutencaoConstants.erroTituloVazio;
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
                    TextFormField(
                      controller: _descricaoController,
                      style: const TextStyle(color: DS.textPrimary),
                      decoration: InputDecoration(
                        labelText: '📄 Descrição *',
                        labelStyle: const TextStyle(color: DS.textSecondary),
                        hintText:
                            'Descreva detalhadamente o trabalho necessário',
                        hintStyle: const TextStyle(color: DS.textTertiary),
                        filled: true,
                        fillColor: DS.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DS.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DS.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: DS.action,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.description,
                          color: DS.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        alignLabelWithHint: true,
                        counterStyle: const TextStyle(color: DS.textTertiary),
                      ),
                      maxLines: 5,
                      maxLength: ManutencaoConstants.descricaoMaxLength,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return ManutencaoConstants.erroDescricaoVazia;
                        }
                        if (value.trim().length <
                            ManutencaoConstants.descricaoMinLength) {
                          return 'Descrição deve ter pelo menos ${ManutencaoConstants.descricaoMinLength} caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Seção de Fotos
                    _buildSecaoFotos(),
                    const SizedBox(height: 20),

                    // Switch para orçamento
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DS.card,
                        borderRadius: BorderRadius.circular(DS.cardRadius),
                        border: Border.all(color: DS.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: DS.textTertiary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              '💰 Requer orçamento/materiais?',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: DS.textPrimary,
                              ),
                            ),
                          ),
                          Switch(
                            value: _temOrcamento,
                            onChanged: (value) {
                              setState(() => _temOrcamento = value);
                            },
                            activeThumbColor: DS.action,
                          ),
                        ],
                      ),
                    ),
                    // Seção de Orçamento
                    if (_temOrcamento) ...[
                      const SizedBox(height: 16),
                      const Divider(thickness: 2, color: DS.border),
                      const SizedBox(height: 16),
                      const Text(
                        '📋 Informações do Orçamento',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: DS.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Arquivo
                      Container(
                        decoration: BoxDecoration(
                          color: DS.card,
                          borderRadius: BorderRadius.circular(DS.cardRadius),
                          border: Border.all(color: DS.border, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.upload_file,
                                  color: DS.action,
                                ),
                                title: const Text(
                                  'Anexar Orçamento (PDF/DOC)',
                                  style: TextStyle(color: DS.textPrimary),
                                ),
                                subtitle: _nomeArquivo != null
                                    ? Text(
                                        '✅ $_nomeArquivo',
                                        style: const TextStyle(
                                          color: DS.success,
                                        ),
                                      )
                                    : const Text(
                                        'Opcional',
                                        style: TextStyle(
                                          color: DS.textSecondary,
                                        ),
                                      ),
                                trailing: ElevatedButton.icon(
                                  onPressed: _selecionarArquivo,
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(
                                    _nomeArquivo != null
                                        ? 'Alterar'
                                        : 'Selecionar',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DS.action,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Valor
                      TextFormField(
                        controller: _valorEstimadoController,
                        style: const TextStyle(color: DS.textPrimary),
                        decoration: InputDecoration(
                          labelText: '💵 Valor Estimado (R\$)',
                          labelStyle: const TextStyle(color: DS.textSecondary),
                          hintText: '2500.00',
                          hintStyle: const TextStyle(color: DS.textTertiary),
                          filled: true,
                          fillColor: DS.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: DS.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: DS.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: DS.action,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.monetization_on,
                            color: DS.textSecondary,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Itens
                      TextFormField(
                        controller: _itensController,
                        style: const TextStyle(color: DS.textPrimary),
                        decoration: InputDecoration(
                          labelText: '📦 Lista de Materiais',
                          labelStyle: const TextStyle(color: DS.textSecondary),
                          hintText:
                              'Um item por linha:\nDobradiça grande\nTinta branca\nPincéis',
                          hintStyle: const TextStyle(color: DS.textTertiary),
                          filled: true,
                          fillColor: DS.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: DS.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: DS.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: DS.action,
                              width: 2,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Botão de criar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _criarChamado,
                        icon: const Icon(Icons.send),
                        label: const Text(
                          'CRIAR CHAMADO',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DS.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DS.buttonRadius,
                            ),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecaoFotos() {
    return Container(
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(DS.cardRadius),
        border: Border.all(color: DS.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera, color: DS.action),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📸 Fotos do Local',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DS.textPrimary,
                        ),
                      ),
                      // Texto removido conforme solicitado
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _mostrarOpcoesFoto,
                  icon: const Icon(Icons.add_a_photo, color: Colors.white),
                  label: const Text(
                    'Adicionar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.action,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_fotos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(color: DS.border),
                  const SizedBox(height: 8),
                  Text(
                    '${_fotos.length} foto(s) anexada(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DS.action,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fotos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _fotos[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removerFoto(index),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: DS.error,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: DS.textPrimary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
