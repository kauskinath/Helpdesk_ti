import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../models/manutencao_constants.dart';
import 'manutencao_atribuir_executor_screen.dart';

/// Tela para Admin Manutenção criar próprios chamados
class ManutencaoCriarChamadoAdminScreen extends StatefulWidget {
  const ManutencaoCriarChamadoAdminScreen({super.key});

  @override
  State<ManutencaoCriarChamadoAdminScreen> createState() =>
      _ManutencaoCriarChamadoAdminScreenState();
}

class _ManutencaoCriarChamadoAdminScreenState
    extends State<ManutencaoCriarChamadoAdminScreen> {
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('📷 Tirar Foto'),
              onTap: () {
                Navigator.pop(context);
                _adicionarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('🖼️ Escolher da Galeria'),
              onTap: () {
                Navigator.pop(context);
                _adicionarFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancelar'),
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
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao capturar foto: $e'),
            backgroundColor: Colors.red,
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
        backgroundColor: Colors.orange,
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
              backgroundColor: Colors.green,
            ),
          );
        }
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
        criadorNome: _authService.userName ?? user.email ?? 'Admin',
        criadorTipo: TipoCriadorChamado.adminManutencao,
        orcamento: orcamento,
      );

      // PASSO 2: Se tem arquivo, fazer upload e atualizar chamado
      if (_temOrcamento && _arquivoOrcamento != null) {
        final arquivoUrl = await _manutencaoService.uploadOrcamento(
          chamadoId,
          _arquivoOrcamento!,
        );

        // Atualizar orçamento com URL do arquivo
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
        // PASSO 4: Se NÃO tem orçamento, redirecionar para atribuir executor
        if (!_temOrcamento) {
          // Buscar o chamado criado
          final chamadoCriado = await _manutencaoService.getChamadoById(
            chamadoId,
          );

          if (!mounted) return;

          // Mostrar snackbar ANTES de navegar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Chamado criado! Agora atribua um executor.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Aguardar um pouco para o usuário ver a mensagem
          await Future.delayed(const Duration(milliseconds: 500));

          // Usar push ao invés de pushReplacement para evitar tela preta
          if (mounted) {
            // Fechar a tela atual primeiro
            Navigator.pop(context, true);

            // Depois abrir a tela de atribuir executor
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ManutencaoAtribuirExecutorScreen(chamado: chamadoCriado),
              ),
            );
          }
        } else {
          // Se tem orçamento, mostrar mensagem e voltar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Chamado criado com sucesso! Aguardando aprovação do gerente.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WallpaperScaffold(
      appBar: AppBar(
        title: Text(
          '📋 Admin - Criar Chamado',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
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
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        labelText: '📝 Título *',
                        hintText: 'Ex: Reparo no portão principal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
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
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        labelText: '📄 Descrição *',
                        hintText:
                            'Descreva detalhadamente o trabalho necessário',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
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
                    // Se��o de Fotos
                    _buildSecaoFotos(),
                    const SizedBox(height: 20),

                    // Switch para orçamento
                    Card(
                      child: SwitchListTile(
                        title: const Text('💰 Requer orçamento/materiais?'),
                        subtitle: const Text(
                          'Se SIM: Precisa aprovação do gerente\n'
                          'Se NÃO: Pode atribuir executor direto',
                        ),
                        value: _temOrcamento,
                        onChanged: (value) {
                          setState(() => _temOrcamento = value);
                        },
                        secondary: const Icon(Icons.attach_money),
                      ),
                    ),

                    // Seção de Orçamento
                    if (_temOrcamento) ...[
                      const SizedBox(height: 16),
                      const Divider(thickness: 2),
                      const SizedBox(height: 16),
                      Text(
                        '📋 Informações do Orçamento',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Arquivo
                      Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.upload_file,
                                  color: Colors.teal.shade700,
                                ),
                                title: Text(
                                  'Anexar Orçamento (PDF/DOC)',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black87
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: _nomeArquivo != null
                                    ? Text(
                                        '✅ $_nomeArquivo',
                                        style: TextStyle(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.black54
                                              : Colors.black54,
                                        ),
                                      )
                                    : Text(
                                        'Opcional',
                                        style: TextStyle(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.black54
                                              : Colors.black54,
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
                                    backgroundColor: Colors.teal,
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
                        decoration: const InputDecoration(
                          labelText: '💵 Valor Estimado (R\$)',
                          hintText: '2500.00',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.monetization_on),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Itens
                      TextFormField(
                        controller: _itensController,
                        decoration: const InputDecoration(
                          labelText: '📦 Lista de Materiais',
                          hintText:
                              'Um item por linha:\nDobradiça grande\nTinta branca\nPincéis',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Botão criar
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
                          backgroundColor: Colors.green,
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

  Widget _buildSecaoFotos() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📸 Fotos do Local',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.black87 : Colors.black,
                        ),
                      ),
                      Text(
                        'Adicione fotos para ilustrar o problema',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.black54 : Colors.black54,
                        ),
                      ),
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
                    backgroundColor: Colors.blue,
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
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '${_fotos.length} foto(s) anexada(s)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
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
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
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
