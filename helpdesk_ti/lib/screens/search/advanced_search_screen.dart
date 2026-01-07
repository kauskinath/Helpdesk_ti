import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';
import '../../data/firestore_service.dart';
import '../chamado/ticket_details_refactored.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';

/// Tela de Busca Avançada de Chamados
///
/// Permite buscar chamados com múltiplos filtros:
/// - Texto livre (título/descrição)
/// - Status
/// - Setor
/// - Prioridade
/// - Período
class AdvancedSearchScreen extends StatefulWidget {
  final FirestoreService firestoreService;
  final AuthService authService;

  const AdvancedSearchScreen({
    super.key,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  // ============ CONTROLADORES ============

  final _textoController = TextEditingController();
  String? _statusSelecionado;
  String? _setorSelecionado;
  int? _prioridadeSelecionada;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  // ============ ESTADO ============

  List<Chamado> _resultados = [];
  bool _buscando = false;
  bool _buscaRealizada = false;

  // ============ OPÇÕES DE FILTROS ============

  final List<String> _statusOptions = [
    'Aberto',
    'Em Andamento',
    'Aguardando',
    'Fechado',
    'Rejeitado',
  ];

  final List<String> _setorOptions = [
    'TI',
    'RH',
    'Financeiro',
    'Comercial',
    'Operacional',
    'Administrativo',
  ];

  final Map<int, String> _prioridadeOptions = {
    1: 'Baixa',
    2: 'Média',
    3: 'Alta',
    4: 'Crítica',
  };

  // ============ LIFECYCLE ============

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  // ============ MÉTODOS DE BUSCA ============

  /// Realiza a busca com os filtros aplicados
  Future<void> _realizarBusca() async {
    setState(() {
      _buscando = true;
      _buscaRealizada = true;
    });

    try {
      // Buscar todos os chamados
      final todosChamados = await widget.firestoreService
          .getTodosChamadosStream()
          .first;

      // Aplicar filtros
      List<Chamado> resultadosFiltrados = todosChamados;

      // Filtro: Texto livre
      if (_textoController.text.isNotEmpty) {
        final textoBusca = _textoController.text.toLowerCase();
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.titulo.toLowerCase().contains(textoBusca) ||
              chamado.descricao.toLowerCase().contains(textoBusca) ||
              chamado.numero.toString().contains(textoBusca);
        }).toList();
      }

      // Filtro: Status
      if (_statusSelecionado != null) {
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.status == _statusSelecionado;
        }).toList();
      }

      // Filtro: Setor
      if (_setorSelecionado != null) {
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.setor == _setorSelecionado;
        }).toList();
      }

      // Filtro: Prioridade
      if (_prioridadeSelecionada != null) {
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.prioridade == _prioridadeSelecionada;
        }).toList();
      }

      // Filtro: Data início
      if (_dataInicio != null) {
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.dataCriacao.isAfter(_dataInicio!) ||
              chamado.dataCriacao.isAtSameMomentAs(_dataInicio!);
        }).toList();
      }

      // Filtro: Data fim
      if (_dataFim != null) {
        final dataFimFinal = DateTime(
          _dataFim!.year,
          _dataFim!.month,
          _dataFim!.day,
          23,
          59,
          59,
        );
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.dataCriacao.isBefore(dataFimFinal) ||
              chamado.dataCriacao.isAtSameMomentAs(dataFimFinal);
        }).toList();
      }

      // Ordenar por data (mais recentes primeiro)
      resultadosFiltrados.sort(
        (a, b) => b.dataCriacao.compareTo(a.dataCriacao),
      );

      setState(() {
        _resultados = resultadosFiltrados;
        _buscando = false;
      });
    } catch (e) {
      setState(() {
        _buscando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao buscar: $e')));
      }
    }
  }

  /// Limpa todos os filtros
  void _limparFiltros() {
    setState(() {
      _textoController.clear();
      _statusSelecionado = null;
      _setorSelecionado = null;
      _prioridadeSelecionada = null;
      _dataInicio = null;
      _dataFim = null;
      _resultados = [];
      _buscaRealizada = false;
    });
  }

  /// Seleciona data início
  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() {
        _dataInicio = data;
      });
    }
  }

  /// Seleciona data fim
  Future<void> _selecionarDataFim() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? DateTime.now(),
      firstDate: _dataInicio ?? DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() {
        _dataFim = data;
      });
    }
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Busca Avançada',
          style: TextStyle(color: DS.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DS.textPrimary),
      ),
      body: Column(
        children: [
          // Área de filtros
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de texto livre
                  TextField(
                    controller: _textoController,
                    style: const TextStyle(color: DS.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Buscar por texto',
                      labelStyle: const TextStyle(color: DS.textSecondary),
                      hintText: 'Título, descrição ou número do chamado',
                      hintStyle: const TextStyle(color: DS.textTertiary),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: DS.textSecondary,
                      ),
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
                        borderSide: const BorderSide(color: DS.action),
                      ),
                      filled: true,
                      fillColor: DS.card,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filtro: Status
                  DropdownButtonFormField<String>(
                    value: _statusSelecionado,
                    dropdownColor: DS.card,
                    style: const TextStyle(color: DS.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: const TextStyle(color: DS.textSecondary),
                      prefixIcon: const Icon(
                        Icons.flag,
                        color: DS.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DS.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DS.border),
                      ),
                      filled: true,
                      fillColor: DS.card,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Todos',
                          style: TextStyle(color: DS.textPrimary),
                        ),
                      ),
                      ..._statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(color: DS.textPrimary),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusSelecionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtro: Setor
                  DropdownButtonFormField<String>(
                    value: _setorSelecionado,
                    dropdownColor: DS.card,
                    style: const TextStyle(color: DS.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Setor',
                      labelStyle: const TextStyle(color: DS.textSecondary),
                      prefixIcon: const Icon(
                        Icons.business,
                        color: DS.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DS.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DS.border),
                      ),
                      filled: true,
                      fillColor: DS.card,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Todos',
                          style: TextStyle(color: DS.textPrimary),
                        ),
                      ),
                      ..._setorOptions.map((setor) {
                        return DropdownMenuItem(
                          value: setor,
                          child: Text(
                            setor,
                            style: const TextStyle(color: DS.textPrimary),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _setorSelecionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtro: Prioridade
                  DropdownButtonFormField<int>(
                    value: _prioridadeSelecionada,
                    dropdownColor: DS.card,
                    style: const TextStyle(color: DS.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Prioridade',
                      labelStyle: const TextStyle(color: DS.textSecondary),
                      prefixIcon: const Icon(
                        Icons.priority_high,
                        color: DS.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DS.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DS.border),
                      ),
                      filled: true,
                      fillColor: DS.card,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Todas',
                          style: TextStyle(color: DS.textPrimary),
                        ),
                      ),
                      ..._prioridadeOptions.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: const TextStyle(color: DS.textPrimary),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _prioridadeSelecionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtro: Período
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DS.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DS.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Período',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DS.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selecionarDataInicio,
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  _dataInicio != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_dataInicio!)
                                      : 'Data Início',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: DS.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selecionarDataFim,
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  _dataFim != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_dataFim!)
                                      : 'Data Fim',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _limparFiltros,
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _buscando ? null : _realizarBusca,
                          icon: _buscando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(_buscando ? 'Buscando...' : 'Buscar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Resultados
                  if (_buscaRealizada) ...[
                    const Divider(color: DS.border),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.list_alt, color: DS.action),
                        const SizedBox(width: 8),
                        Text(
                          '${_resultados.length} resultado(s) encontrado(s)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DS.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._resultados.map((chamado) => _buildChamadoCard(chamado)),
                    if (_resultados.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: DS.textTertiary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum chamado encontrado',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: DS.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ WIDGETS AUXILIARES ============

  Widget _buildChamadoCard(Chamado chamado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailsRefactored(
                chamado: chamado,
                firestoreService: widget.firestoreService,
                authService: widget.authService,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DS.action,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${chamado.numero.toString().padLeft(4, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(chamado.status),
                  const Spacer(),
                  _buildPrioridadeBadge(chamado.prioridade),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                chamado.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DS.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: DS.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    chamado.setor,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DS.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.person, size: 14, color: DS.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      chamado.usuarioNome,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DS.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: DS.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(chamado.dataCriacao),
                    style: const TextStyle(
                      fontSize: 12,
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color cor;
    switch (status) {
      case 'Aberto':
        cor = Colors.blue;
        break;
      case 'Em Andamento':
        cor = Colors.orange;
        break;
      case 'Fechado':
        cor = Colors.green;
        break;
      case 'Rejeitado':
        cor = Colors.red;
        break;
      default:
        cor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPrioridadeBadge(int prioridade) {
    String texto;
    Color cor;

    switch (prioridade) {
      case 4:
        texto = 'Crítica';
        cor = Colors.red;
        break;
      case 3:
        texto = 'Alta';
        cor = Colors.orange;
        break;
      case 2:
        texto = 'Média';
        cor = Colors.blue;
        break;
      case 1:
      default:
        texto = 'Baixa';
        cor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, size: 12, color: cor),
          const SizedBox(width: 2),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
