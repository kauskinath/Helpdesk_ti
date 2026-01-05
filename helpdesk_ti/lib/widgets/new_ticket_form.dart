import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
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
          color: isSelected ? color.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).iconTheme.color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : null,
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
      appBar: AppBar(
        title: Text(
          'Novo Chamado TI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            shadows: Theme.of(context).brightness == Brightness.dark
                ? [const Shadow(color: Colors.black54, blurRadius: 4)]
                : [const Shadow(color: Colors.white70, blurRadius: 2)],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDarkMode = themeProvider.isDarkMode;

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: isDarkMode
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFF5F7FA),
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
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF1E88E5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Solicitante: $userName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.business,
                                color: Color(0xFF1E88E5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Setor: $setorNome',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(
                                Icons.support_agent,
                                color: Color(0xFF1E88E5),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Destino: TI - Suporte Técnico',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tipo de Chamado (Solicitação ou Serviço)
                    Text(
                      'Tipo de Chamado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTipo,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                      ),
                      items: _tiposDisponiveis
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        setState(() {
                          _selectedTipo = valor ?? 'Solicitação';
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Prioridade do Chamado
                    Text(
                      'Prioridade do Chamado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).cardColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPriorityChip(
                            'Baixa',
                            1,
                            const Color(0xFF66BB6A),
                            Icons.arrow_downward,
                          ),
                          _buildPriorityChip(
                            'Média',
                            2,
                            const Color(0xFF42A5F5),
                            Icons.remove,
                          ),
                          _buildPriorityChip(
                            'Alta',
                            3,
                            const Color(0xFFFF9800),
                            Icons.arrow_upward,
                          ),
                          _buildPriorityChip(
                            'CRÍTICA',
                            4,
                            const Color(0xFFEF5350),
                            Icons.priority_high,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Título (opcional)
                    Text(
                      'Título do Chamado (Opcional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        hintText:
                            'Ex: Computador não liga, Instalar programa...',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Descrição
                    Text(
                      'Descrição do Problema *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descricaoController,
                      decoration: InputDecoration(
                        hintText:
                            'Descreva detalhadamente o problema ou solicitação...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 4,
                      minLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Link ou Especificação (condicional para Solicitação)
                    if (_selectedTipo == 'Solicitação') ...[
                      Text(
                        'Link do Produto ou Especificação',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _linkController,
                        decoration: InputDecoration(
                          hintText: 'URL do produto ou especificações técnicas',
                          prefixIcon: const Icon(Icons.link),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(height: 24),
                    ], // Seção de Anexos
                    Text(
                      'Anexar Foto (Opcional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Galeria de imagens selecionadas
                    if (_selectedImages.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.3),
                          border: Border.all(
                            color: const Color(0xFF1E88E5),
                            width: 2,
                          ),
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
                                  color: Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedImages.length} imagem(ns) selecionada(s)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Grid de thumbnails
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
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _selectedImages[index].path,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stack) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    color: Colors.white54,
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
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,

                                            size: 16,
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

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Câmera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.white,
                              foregroundColor: isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
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
                              backgroundColor: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.white,
                              foregroundColor: isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
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
                                ),
                              )
                            : const Text(
                                'Criar Chamado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
