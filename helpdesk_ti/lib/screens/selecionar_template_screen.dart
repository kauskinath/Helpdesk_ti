import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/features/ti/models/chamado_template.dart';
import '../data/firestore_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'template_form_screen.dart';

class SelecionarTemplateScreen extends StatefulWidget {
  final FirestoreService firestoreService;

  const SelecionarTemplateScreen({super.key, required this.firestoreService});

  @override
  State<SelecionarTemplateScreen> createState() =>
      _SelecionarTemplateScreenState();
}

class _SelecionarTemplateScreenState extends State<SelecionarTemplateScreen> {
  String _filtroTag = 'todos';
  String _buscaTexto = '';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Filtros
              _buildFiltros(),

              // Lista de templates
              Expanded(
                child: StreamBuilder<List<ChamadoTemplate>>(
                  stream: widget.firestoreService.getTemplatesAtivos(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    var templates = snapshot.data ?? [];

                    // Filtrar por tag
                    if (_filtroTag != 'todos') {
                      templates = templates
                          .where((t) => t.tags.contains(_filtroTag))
                          .toList();
                    }

                    // Filtrar por busca de texto
                    if (_buscaTexto.isNotEmpty) {
                      templates = templates
                          .where(
                            (t) =>
                                t.titulo.toLowerCase().contains(
                                  _buscaTexto.toLowerCase(),
                                ) ||
                                t.tags.any(
                                  (tag) => tag.toLowerCase().contains(
                                    _buscaTexto.toLowerCase(),
                                  ),
                                ),
                          )
                          .toList();
                    }

                    if (templates.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum template encontrado',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filtroTag = 'todos';
                                  _buscaTexto = '';
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Limpar Filtros'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        return FadeInUp(
                          delay: Duration(milliseconds: 50 * index),
                          duration: const Duration(milliseconds: 400),
                          child: _buildTemplateCard(templates[index]),
                        );
                      },
                    );
                  },
                ),
              ),

              // Botão para criar sem template
              _buildCriarSemTemplate(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecione um Template',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escolha um modelo para facilitar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de busca
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar templates...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _buscaTexto = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFiltroChip('todos', '📋 Todos'),
          _buildFiltroChip('rede', '🌐 Rede'),
          _buildFiltroChip('impressora', '🖨️ Impressora'),
          _buildFiltroChip('software', '💻 Software'),
          _buildFiltroChip('hardware', '🖥️ Hardware'),
          _buildFiltroChip('email', '📧 Email'),
          _buildFiltroChip('senha', '🔐 Senha'),
          _buildFiltroChip('compra', '🛒 Compra'),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String tag, String label) {
    final isSelected = _filtroTag == tag;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroTag = selected ? tag : 'todos';
          });
        },
        backgroundColor: isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.blue.shade100)
            : (Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Colors.grey.shade100),
        selectedColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.blue.shade200,
        labelStyle: TextStyle(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.blue.shade900)
              : (Theme.of(context).brightness == Brightness.dark
                    ? null
                    : Colors.grey.shade700),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : Colors.blue.shade600)
              : (Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).dividerColor
                    : Colors.grey.shade400),
          width: isSelected ? 2 : 1.5,
        ),
      ),
    );
  }

  Widget _buildTemplateCard(ChamadoTemplate template) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Theme.of(context).cardColor.withValues(alpha: 0.95)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Theme.of(context).dividerColor
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.08 : 0.15),
            blurRadius: isDarkMode ? 8 : 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Se template tem campos estruturados, usar formulário dinâmico
            if (template.campos != null && template.campos!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TemplateFormScreen(template: template),
                ),
              );
            } else {
              // Se não, usar formulário tradicional
              Navigator.pop(context, template);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ícone
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [
                                  Theme.of(context).colorScheme.primaryContainer
                                      .withValues(alpha: 0.3),
                                  Theme.of(context).colorScheme.primaryContainer
                                      .withValues(alpha: 0.2),
                                ]
                              : [Colors.blue.shade100, Colors.blue.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.transparent
                              : Colors.blue.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          template.iconeSugerido,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Título e tipo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.titulo,
                            style: TextStyle(
                              color: isDarkMode ? null : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: template.tipo == 'Solicitação'
                                        ? isDarkMode
                                              ? [
                                                  Colors.purple.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  Colors.purple.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                ]
                                              : [
                                                  Colors.purple.shade100,
                                                  Colors.purple.shade50,
                                                ]
                                        : isDarkMode
                                        ? [
                                            Colors.blue.withValues(alpha: 0.3),
                                            Colors.blue.withValues(alpha: 0.2),
                                          ]
                                        : [
                                            Colors.blue.shade100,
                                            Colors.blue.shade50,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: template.tipo == 'Solicitação'
                                        ? (isDarkMode
                                              ? Colors.purple
                                              : Colors.purple.shade600)
                                        : (isDarkMode
                                              ? Colors.blue
                                              : Colors.blue.shade600),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  template.tipo,
                                  style: TextStyle(
                                    color: template.tipo == 'Solicitação'
                                        ? (isDarkMode
                                              ? Colors.purple.shade200
                                              : Colors.purple.shade900)
                                        : (isDarkMode
                                              ? Colors.blue.shade200
                                              : Colors.blue.shade900),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDarkMode
                                        ? [
                                            _getCorPrioridade(
                                              template.prioridade,
                                            ).withValues(alpha: 0.3),
                                            _getCorPrioridade(
                                              template.prioridade,
                                            ).withValues(alpha: 0.2),
                                          ]
                                        : [
                                            _getCorPrioridadeClara(
                                              template.prioridade,
                                            ),
                                            _getCorPrioridadeClara(
                                              template.prioridade,
                                            ).withValues(alpha: 0.5),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? _getCorPrioridade(template.prioridade)
                                        : _getCorPrioridadeEscura(
                                            template.prioridade,
                                          ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  template.prioridadeLabel,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? _getCorPrioridadeTexto(
                                            template.prioridade,
                                          )
                                        : _getCorPrioridadeTextoClaro(
                                            template.prioridade,
                                          ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Seta
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isDarkMode
                          ? Theme.of(
                              context,
                            ).iconTheme.color?.withValues(alpha: 0.5)
                          : Colors.grey.shade600,
                      size: 16,
                    ),
                  ],
                ),

                if (template.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: template.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.transparent
                                : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: isDarkMode ? null : Colors.grey.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriarSemTemplate() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit_note),
            label: const Text('Criar do Zero (Sem Template)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCorPrioridade(int prioridade) {
    switch (prioridade) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getCorPrioridadeTexto(int prioridade) {
    switch (prioridade) {
      case 1:
        return Colors.green.shade800;
      case 2:
        return Colors.blue.shade800;
      case 3:
        return Colors.orange.shade900;
      case 4:
        return Colors.red.shade900;
      default:
        return Colors.grey.shade800;
    }
  }

  Color _getCorPrioridadeClara(int prioridade) {
    switch (prioridade) {
      case 1:
        return Colors.green.shade100;
      case 2:
        return Colors.blue.shade100;
      case 3:
        return Colors.orange.shade100;
      case 4:
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getCorPrioridadeEscura(int prioridade) {
    switch (prioridade) {
      case 1:
        return Colors.green.shade700;
      case 2:
        return Colors.blue.shade700;
      case 3:
        return Colors.orange.shade800;
      case 4:
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getCorPrioridadeTextoClaro(int prioridade) {
    switch (prioridade) {
      case 1:
        return Colors.green.shade900;
      case 2:
        return Colors.blue.shade900;
      case 3:
        return Colors.orange.shade900;
      case 4:
        return Colors.red.shade900;
      default:
        return Colors.grey.shade900;
    }
  }
}
