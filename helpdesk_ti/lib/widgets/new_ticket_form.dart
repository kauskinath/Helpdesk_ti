import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';

class NewTicketForm extends StatefulWidget {
  final Function(
    String titulo,
    String setor,
    String tipo,
    String descricao,
    String? linkOuEspecificacao,
    int prioridade,
    List<XFile> imagens,
  )?
  onSubmit;

  const NewTicketForm({super.key, this.onSubmit});

  @override
  State<NewTicketForm> createState() => _NewTicketFormState();
}

class _NewTicketFormState extends State<NewTicketForm> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedTipo = 'Solicitação';
  int _prioridadeSelecionada = 2; // Padrão: Média
  final bool _isLoading = false;
  final List<XFile> _selectedImages = []; // Múltiplas imagens

  @override
  void initState() {
    super.initState();
  }

  // Mapa para exibir nome legível do setor
  final Map<String, String> _setoresNomes = {
    'almoxarifado': 'Almoxarifado',
    'atendimento': 'Atendimento',
    'cesar': 'Estoque G6',
    'comex': 'Comex',
    'compras': 'Compras',
    'desenvolvimento': 'Desenvolvimento',
    'dev': 'Dev',
    'devolucao': 'Devolução',
    'entrada': 'Entrada',
    'estoque': 'Estoque',
    'financeiro_fiscal': 'Financeiro Fiscal',
    'financeiro_giordani': 'Financeiro Contas',
    'financeiro_mayra': 'Financeiro Contábil',
    'galpao5': 'Estoque G5',
    'gerencia': 'Gerência',
    'impressao': 'Impressão',
    'javier': 'Estoque G9',
    'juridico': 'Jurídico',
    'logistica': 'Logística',
    'marketing': 'Marketing',
    'market_place': 'Market Place',
    'nota_fiscal': 'Nota Fiscal',
    'nota_pc': 'Nota Fiscal PC',
    'pichau_empresas': 'Pichau Empresas',
    'plp': 'PLP',
    'rh': 'RH',
    'rma_fornecedor': 'RMA Fornecedor',
    'rma_pc': 'RMA PC',
    'rma_pecas': 'RMA Peças',
    'rma_pichaugaming': 'RMA Pichau Gaming',
    'vendas': 'Vendas PC',
    'ti': 'TI',
  };

  final List<String> _tiposDisponiveis = ['Solicitação', 'Serviço'];

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();

      if (source == ImageSource.gallery) {
        // Da galeria, permitir múltiplas seleções
        final images = await picker.pickMultiImage();

        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${images.length} imagem(ns) selecionada(s)!'),
              ),
            );
          }
        }
      } else {
        // Da câmera, apenas uma por vez
        final image = await picker.pickImage(source: source);

        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto tirada com sucesso!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Imagem removida')));
  }

  Future<void> _submit() async {
    final authService = context.read<AuthService>();
    final userSetor = authService.userSetor ?? 'ti';

    if (_descricaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a descrição do chamado')),
      );
      return;
    }

    // Gerar título automático baseado no setor e tipo
    final setorNome = _setoresNomes[userSetor] ?? userSetor;
    final titulo = _tituloController.text.isNotEmpty
        ? _tituloController.text
        : '$_selectedTipo - $setorNome';

    widget.onSubmit?.call(
      titulo,
      userSetor,
      _selectedTipo,
      _descricaoController.text,
      _linkController.text.isNotEmpty ? _linkController.text : null,
      _prioridadeSelecionada, // Prioridade selecionada pelo usuário
      _selectedImages, // Enviando as fotos selecionadas
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildPriorityChip(
    String label,
    int value,
    Color color,
    IconData icon,
  ) {
    final isSelected = _prioridadeSelecionada == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _prioridadeSelecionada = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(80) : DS.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : DS.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : DS.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : DS.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userSetor = authService.userSetor ?? 'ti';
    final setorNome = _setoresNomes[userSetor] ?? userSetor;
    final userName = authService.userName ?? 'Usuário';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: DS.background,
      appBar: AppBar(
        title: const Text(
          'Novo Chamado TI',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: DS.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: DS.textPrimary),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: DS.background,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card com informações do solicitante
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DS.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DS.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: DS.action, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Solicitante: $userName',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: DS.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.business,
                            color: DS.action,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Setor: $setorNome',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: DS.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.support_agent, color: DS.action, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Destino: TI - Suporte Técnico',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: DS.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tipo de Chamado
                const Text(
                  'Tipo de Chamado',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: DS.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DS.border),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTipo,
                    dropdownColor: DS.card,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: DS.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.category,
                        color: DS.textSecondary,
                      ),
                      filled: true,
                      fillColor: DS.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DS.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _tiposDisponiveis
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() => _selectedTipo = valor ?? 'Solicitação');
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Prioridade
                const Text(
                  'Prioridade do Chamado',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DS.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DS.border),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPriorityChip(
                        'Baixa',
                        1,
                        DS.success,
                        Icons.arrow_downward,
                      ),
                      _buildPriorityChip('Média', 2, DS.action, Icons.remove),
                      _buildPriorityChip(
                        'Alta',
                        3,
                        DS.warning,
                        Icons.arrow_upward,
                      ),
                      _buildPriorityChip(
                        'CRÍTICA',
                        4,
                        DS.error,
                        Icons.priority_high,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Título
                const Text(
                  'Título do Chamado (Opcional)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tituloController,
                  style: const TextStyle(color: DS.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ex: Computador não liga, Instalar programa...',
                    hintStyle: const TextStyle(color: DS.textTertiary),
                    prefixIcon: const Icon(
                      Icons.title,
                      color: DS.textSecondary,
                    ),
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
                      borderSide: const BorderSide(color: DS.action, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Descrição
                const Text(
                  'Descrição do Problema *',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descricaoController,
                  style: const TextStyle(color: DS.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        'Descreva detalhadamente o problema ou solicitação...',
                    hintStyle: const TextStyle(color: DS.textTertiary),
                    prefixIcon: const Icon(
                      Icons.description,
                      color: DS.textSecondary,
                    ),
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
                      borderSide: const BorderSide(color: DS.action, width: 2),
                    ),
                  ),
                  maxLines: 4,
                  minLines: 3,
                ),

                const SizedBox(height: 24),

                // Link (para Solicitação)
                if (_selectedTipo == 'Solicitação') ...[
                  const Text(
                    'Link do Produto ou Especificação',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _linkController,
                    style: const TextStyle(color: DS.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'URL do produto ou especificações técnicas',
                      hintStyle: const TextStyle(color: DS.textTertiary),
                      prefixIcon: const Icon(
                        Icons.link,
                        color: DS.textSecondary,
                      ),
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
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                  const SizedBox(height: 24),
                ],

                // Anexos
                const Text(
                  'Anexar Foto (Opcional)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Galeria de imagens
                if (_selectedImages.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DS.card,
                      border: Border.all(color: DS.action, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 24,
                              color: DS.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedImages.length} imagem(ns) selecionada(s)',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: DS.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: DS.card,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: DS.border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _selectedImages[index].path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) {
                                        return const Center(
                                          child: Icon(
                                            Icons.image,
                                            color: DS.textSecondary,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: DS.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Botões câmera/galeria
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Câmera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DS.card,
                          foregroundColor: DS.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: DS.border, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DS.card,
                          foregroundColor: DS.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: DS.border, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Botão Criar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DS.action,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Criar Chamado',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
