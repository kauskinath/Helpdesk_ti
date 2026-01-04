import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/features/manutencao/services/manutencao_service.dart';
import 'package:helpdesk_ti/features/manutencao/models/chamado_manutencao_model.dart';
import '../../widgets/chamado/status_badge.dart';
import '../widgets/chamado_detail_dialog.dart';
import 'web_manutencao_detail_screen.dart';

/// Tela de gerenciamento completo de chamados
class WebChamadosScreen extends StatefulWidget {
  const WebChamadosScreen({super.key});

  @override
  State<WebChamadosScreen> createState() => _WebChamadosScreenState();
}

class _WebChamadosScreenState extends State<WebChamadosScreen> {
  String _searchQuery = '';
  String _statusFilter = 'Todos';
  String _prioridadeFilter = 'Todas';
  String _tipoFilter = 'TI'; // TI ou Manutenção
  int _rowsPerPage = 10;
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  final ManutencaoService _manutencaoService = ManutencaoService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Chamado> _filterChamados(List<Chamado> chamados) {
    var filtered = chamados;

    // Filtro de busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.numeroFormatado.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            c.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.usuarioNome.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtro de status
    if (_statusFilter != 'Todos') {
      filtered = filtered.where((c) => c.status == _statusFilter).toList();
    }

    // Filtro de prioridade
    if (_prioridadeFilter != 'Todas') {
      final prioridadeMap = {'Baixa': 1, 'Média': 2, 'Alta': 3, 'Crítica': 4};
      final prioridade = prioridadeMap[_prioridadeFilter];
      if (prioridade != null) {
        filtered = filtered.where((c) => c.prioridade == prioridade).toList();
      }
    }

    return filtered;
  }

  Color _getPriorityColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return AppColors.statusOpen;
      case 2:
        return AppColors.statusInProgress;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _getPriorityLabel(int prioridade) {
    switch (prioridade) {
      case 1:
        return 'Baixa';
      case 2:
        return 'Média';
      case 3:
        return 'Alta';
      case 4:
        return 'CRÍTICA';
      default:
        return 'Normal';
    }
  }

  Widget _buildTypeTab(
    String label,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    final isSelected = _tipoFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _tipoFilter = label;
          _currentPage = 0;
          _statusFilter = 'Todos';
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNovoChamadoDialog(BuildContext context, bool isDarkMode) {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();
    String categoria = 'Hardware';
    int prioridade = 2;
    String setor = 'TI';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        (_tipoFilter == 'TI' ? AppColors.primary : Colors.teal)
                            .withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _tipoFilter == 'TI'
                              ? AppColors.primary
                              : Colors.teal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _tipoFilter == 'TI' ? Icons.computer : Icons.build,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Novo Chamado ${_tipoFilter == 'TI' ? 'TI' : 'Manutenção'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              'Preencha os dados abaixo',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Formulário
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          TextFormField(
                            controller: tituloController,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Título do Chamado *',
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              hintText: 'Ex: Computador não liga',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o título do chamado';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Descrição
                          TextFormField(
                            controller: descricaoController,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Descrição *',
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              hintText: 'Descreva o problema detalhadamente...',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe a descrição do chamado';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Categoria e Prioridade
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: categoria,
                                  dropdownColor: isDarkMode
                                      ? const Color(0xFF2D2D2D)
                                      : Colors.white,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Categoria',
                                    labelStyle: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey[50],
                                  ),
                                  items:
                                      ['Hardware', 'Software', 'Rede', 'Outro']
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) =>
                                      setDialogState(() => categoria = v!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: prioridade,
                                  dropdownColor: isDarkMode
                                      ? const Color(0xFF2D2D2D)
                                      : Colors.white,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Prioridade',
                                    labelStyle: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey[50],
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text('Baixa'),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text('Média'),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text('Alta'),
                                    ),
                                    DropdownMenuItem(
                                      value: 4,
                                      child: Text('Crítica'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setDialogState(() => prioridade = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Setor
                          DropdownButtonFormField<String>(
                            initialValue: setor,
                            dropdownColor: isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : Colors.white,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Setor',
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey[50],
                            ),
                            items:
                                [
                                      'TI',
                                      'Almoxarifado',
                                      'Atendimento',
                                      'Comercial',
                                      'Financeiro',
                                      'RH',
                                      'Logística',
                                      'Outro',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setDialogState(() => setor = v!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botões
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode ? Colors.white12 : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setDialogState(() => isLoading = true);

                                try {
                                  final authService = context
                                      .read<AuthService>();
                                  final firestoreService = context
                                      .read<FirestoreService>();

                                  final novoChamado = Chamado(
                                    id: '',
                                    titulo: tituloController.text.trim(),
                                    descricao: descricaoController.text.trim(),
                                    setor: setor,
                                    tipo: categoria,
                                    prioridade: prioridade,
                                    status: 'Aberto',
                                    usuarioId:
                                        authService.firebaseUser?.uid ?? '',
                                    usuarioNome:
                                        authService.userName ?? 'Usuário',
                                    dataCriacao: DateTime.now(),
                                  );

                                  await firestoreService.criarChamado(
                                    novoChamado,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Chamado criado com sucesso!'),
                                          ],
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao criar chamado: $e',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => isLoading = false);
                                  }
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isLoading ? 'Salvando...' : 'Criar Chamado',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoFilter == 'TI'
                              ? AppColors.primary
                              : Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final userRole = authService.userRole;
    final canSeeManutencao = [
      'admin',
      'manager',
      'admin_manutencao',
      'executor',
    ].contains(userRole);
    final canSeeTI = ['admin', 'manager', 'user'].contains(userRole);

    // Ajustar tipo inicial baseado na role
    if (!canSeeTI && canSeeManutencao && _tipoFilter == 'TI') {
      _tipoFilter = 'Manutenção';
    }

    return Container(
      // Fundo limpo para web
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da página com seletor de tipo
            Row(
              children: [
                Text(
                  'Gerenciamento de Chamados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                // Botão Novo Chamado
                ElevatedButton.icon(
                  onPressed: () => _showNovoChamadoDialog(context, isDarkMode),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo Chamado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tipoFilter == 'TI'
                        ? AppColors.primary
                        : Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Spacer(),
                // Botões de ação (tema, atualizar)
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: isDarkMode ? Colors.amber : AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () =>
                        context.read<ThemeProvider>().toggleTheme(),
                    tooltip: isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDarkMode ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => setState(() {}),
                    tooltip: 'Atualizar',
                  ),
                ),
                const SizedBox(width: 12),
                // Seletor de tipo (só mostrar se pode ver ambos)
                if (canSeeTI && canSeeManutencao)
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildTypeTab(
                          'TI',
                          Icons.computer,
                          AppColors.primary,
                          isDarkMode,
                        ),
                        _buildTypeTab(
                          'Manutenção',
                          Icons.build,
                          Colors.teal,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra de ferramentas (Pesquisa + Filtros)
            Container(
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: isDarkMode
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkMode ? 0.2 : 0.08,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Campo de pesquisa
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar por número, título ou usuário...',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white54
                                  : AppColors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDarkMode
                                  ? Colors.white54
                                  : AppColors.grey,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : AppColors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _currentPage = 0;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppColors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[50],
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Filtro de Status
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          isExpanded: true,
                          dropdownColor: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : Colors.white,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : AppColors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.filter_list,
                              color: isDarkMode
                                  ? Colors.white54
                                  : AppColors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppColors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Todos',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem(
                              value: 'Aberto',
                              child: Text('Aberto'),
                            ),
                            DropdownMenuItem(
                              value: 'Em Andamento',
                              child: Text('Em Andamento'),
                            ),
                            DropdownMenuItem(
                              value: 'Pendente Aprovação',
                              child: Text('Pendente Aprovação'),
                            ),
                            DropdownMenuItem(
                              value: 'Fechado',
                              child: Text('Fechado'),
                            ),
                            DropdownMenuItem(
                              value: 'Rejeitado',
                              child: Text('Rejeitado'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value!;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Filtro de Prioridade
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _prioridadeFilter,
                          isExpanded: true,
                          dropdownColor: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : Colors.white,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Prioridade',
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : AppColors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.priority_high,
                              color: isDarkMode
                                  ? Colors.white54
                                  : AppColors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppColors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Todas',
                              child: Text('Todas'),
                            ),
                            DropdownMenuItem(
                              value: 'Baixa',
                              child: Text('Baixa'),
                            ),
                            DropdownMenuItem(
                              value: 'Média',
                              child: Text('Média'),
                            ),
                            DropdownMenuItem(
                              value: 'Alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'Crítica',
                              child: Text('Crítica'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _prioridadeFilter = value!;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tabela de chamados - condicional por tipo
            if (_tipoFilter == 'TI')
              _buildTIChamadosTable(
                firestoreService,
                isDarkMode,
                userRole,
                authService.firebaseUser?.uid,
              )
            else
              _buildManutencaoChamadosTable(
                isDarkMode,
                userRole,
                authService.firebaseUser?.uid,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTIChamadosTable(
    FirestoreService firestoreService,
    bool isDarkMode,
    String? role,
    String? userId,
  ) {
    Stream<List<Chamado>> stream;
    if (role == 'user' && userId != null) {
      stream = firestoreService.getChamadosDoUsuario(userId);
    } else {
      stream = firestoreService.getTodosChamadosStream();
    }

    return StreamBuilder<List<Chamado>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(
              color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
            ),
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${snapshot.error}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allChamados = snapshot.data ?? [];
        final filteredChamados = _filterChamados(allChamados);
        final totalItems = filteredChamados.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();

        // Paginação
        final startIndex = _currentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
        final paginatedChamados = filteredChamados.sublist(
          startIndex,
          endIndex,
        );

        if (filteredChamados.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.2 : 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: (isDarkMode ? Colors.white : AppColors.grey)
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum chamado encontrado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tente ajustar os filtros de busca',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.white70
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Estatísticas rápidas
            Row(
              children: [
                _buildQuickStat(
                  'Total',
                  filteredChamados.length.toString(),
                  Icons.confirmation_number,
                  AppColors.primary,
                  isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildQuickStat(
                  'Abertos',
                  filteredChamados
                      .where((c) => c.status == 'Aberto')
                      .length
                      .toString(),
                  Icons.pending,
                  AppColors.statusOpen,
                  isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildQuickStat(
                  'Em Andamento',
                  filteredChamados
                      .where((c) => c.status == 'Em Andamento')
                      .length
                      .toString(),
                  Icons.loop,
                  AppColors.statusInProgress,
                  isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildQuickStat(
                  'Fechados',
                  filteredChamados
                      .where((c) => c.status == 'Fechado')
                      .length
                      .toString(),
                  Icons.check_circle,
                  AppColors.statusClosed,
                  isDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tabela
            Container(
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: isDarkMode
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkMode ? 0.2 : 0.08,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        border: TableBorder.all(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.15),
                          width: 0.5,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        headingRowColor: WidgetStateProperty.all(
                          isDarkMode
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.greyLight,
                        ),
                        dataRowColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.greyLight.withValues(alpha: 0.5);
                          }
                          return Colors.transparent;
                        }),
                        columns: [
                          DataColumn(
                            label: Text(
                              'Nº',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Título',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Usuário',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Tipo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Prioridade',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Data',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Ações',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                        rows: paginatedChamados.map((chamado) {
                          final textColor = isDarkMode
                              ? Colors.white70
                              : Colors.black87;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color>((
                              states,
                            ) {
                              if (states.contains(WidgetState.hovered)) {
                                return isDarkMode
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppColors.primary.withValues(alpha: 0.05);
                              }
                              return Colors.transparent;
                            }),
                            cells: [
                              DataCell(
                                Text(
                                  chamado.numeroFormatado,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 250,
                                  ),
                                  child: Text(
                                    chamado.titulo,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  chamado.usuarioNome,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    chamado.tipo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(
                                      chamado.prioridade,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getPriorityLabel(chamado.prioridade),
                                    style: TextStyle(
                                      color: _getPriorityColor(
                                        chamado.prioridade,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(StatusBadge(status: chamado.status)),
                              DataCell(
                                Text(
                                  DateFormat(
                                    'dd/MM/yy HH:mm',
                                  ).format(chamado.dataCriacao),
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.visibility,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  ChamadoDetailDialog(
                                                    chamado: chamado,
                                                  ),
                                            );
                                          },
                                          tooltip: 'Visualizar',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Controles de paginação
                  if (totalPages > 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppColors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Linhas por página:',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _rowsPerPage,
                            dropdownColor: isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : Colors.white,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            items: [10, 25, 50, 100].map((value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _rowsPerPage = value!;
                                _currentPage = 0;
                              });
                            },
                          ),
                          const Spacer(),
                          Text(
                            '${startIndex + 1}-$endIndex de $totalItems',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                            onPressed: _currentPage > 0
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            'Página ${_currentPage + 1} de $totalPages',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right,
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                            onPressed: _currentPage < totalPages - 1
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManutencaoChamadosTable(
    bool isDarkMode,
    String? role,
    String? userId,
  ) {
    Stream<List<ChamadoManutencao>> stream;

    if (role == 'manager') {
      stream = _manutencaoService.getChamadosParaAdminManutencao();
    } else if (role == 'admin_manutencao') {
      stream = _manutencaoService.getChamadosParaAdminManutencao();
    } else if (role == 'executor' && userId != null) {
      stream = _manutencaoService.getChamadosParaExecutor(userId);
    } else {
      stream = _manutencaoService.getChamadosParaAdminManutencao();
    }

    return StreamBuilder<List<ChamadoManutencao>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(
              color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${snapshot.error}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final chamados = snapshot.data ?? [];

        if (chamados.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.2 : 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.build_outlined,
                    size: 80,
                    color: Colors.teal.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum chamado de manutenção',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    role == 'manager'
                        ? 'Não há orçamentos pendentes de aprovação'
                        : 'Nenhum chamado encontrado',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.white54
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Tabela de manutenção
        return Container(
          decoration: BoxDecoration(
            color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Stats rápidos de manutenção
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildQuickStat(
                      'Total',
                      chamados.length.toString(),
                      Icons.build,
                      Colors.teal,
                      isDarkMode,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      'Aguardando',
                      chamados
                          .where(
                            (c) =>
                                c.status.value ==
                                'aguardando_aprovacao_gerente',
                          )
                          .length
                          .toString(),
                      Icons.hourglass_empty,
                      Colors.orange,
                      isDarkMode,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      'Em Execução',
                      chamados
                          .where((c) => c.status.value == 'em_execucao')
                          .length
                          .toString(),
                      Icons.engineering,
                      Colors.blue,
                      isDarkMode,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      'Concluídos',
                      chamados
                          .where((c) => c.status.value == 'concluido')
                          .length
                          .toString(),
                      Icons.task_alt,
                      AppColors.statusClosed,
                      isDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tabela
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    border: TableBorder.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.15),
                      width: 0.5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    headingRowColor: WidgetStateProperty.all(
                      isDarkMode
                          ? Colors.teal.withValues(alpha: 0.2)
                          : Colors.teal.withValues(alpha: 0.1),
                    ),
                    showCheckboxColumn: false,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Nº',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Título',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Criador',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Orçamento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Data',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                    rows: chamados.take(20).map((chamado) {
                      return DataRow(
                        onSelectChanged: (_) {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                WebManutencaoDetailScreen(chamado: chamado),
                          );
                        },
                        cells: [
                          DataCell(
                            Text(
                              'M-${chamado.numero.toString().padLeft(4, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                chamado.titulo,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              chamado.criadorNome,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                          DataCell(
                            _buildManutencaoStatusBadge(chamado.status.value),
                          ),
                          DataCell(
                            Text(
                              chamado.orcamento?.valorEstimado != null
                                  ? 'R\$ ${chamado.orcamento!.valorEstimado!.toStringAsFixed(2)}'
                                  : '-',
                              style: TextStyle(
                                color: chamado.orcamento?.valorEstimado != null
                                    ? Colors.green
                                    : (isDarkMode
                                          ? Colors.white54
                                          : Colors.black38),
                                fontWeight:
                                    chamado.orcamento?.valorEstimado != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(chamado.dataAbertura),
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManutencaoStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'aberto':
        color = Colors.blue;
        label = 'Aberto';
        break;
      case 'em_validacao':
        color = Colors.amber;
        label = 'Em Validação';
        break;
      case 'aguardando_aprovacao_gerente':
        color = Colors.orange;
        label = 'Aguardando Aprovação';
        break;
      case 'orcamento_aprovado':
        color = Colors.green;
        label = 'Orçamento Aprovado';
        break;
      case 'atribuido_executor':
        color = Colors.purple;
        label = 'Atribuído';
        break;
      case 'em_execucao':
        color = Colors.indigo;
        label = 'Em Execução';
        break;
      case 'concluido':
        color = Colors.teal;
        label = 'Concluído';
        break;
      case 'rejeitado':
        color = Colors.red;
        label = 'Rejeitado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;
    final valueColor = isDarkMode ? Colors.white : AppColors.textPrimary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDarkMode ? 0.3 : 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: textColor)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
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
