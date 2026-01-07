import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../services/manutencao_service.dart';
import '../../widgets/manutencao_card.dart';
import 'manutencao_detalhes_chamado_screen.dart';

/// Tela de Busca Avançada de Chamados de Manutenção
///
/// Permite buscar chamados com múltiplos filtros:
/// - Texto livre (título/descrição)
/// - Status
/// - Período
class ManutencaoAdvancedSearchScreen extends StatefulWidget {
  const ManutencaoAdvancedSearchScreen({super.key});

  @override
  State<ManutencaoAdvancedSearchScreen> createState() =>
      _ManutencaoAdvancedSearchScreenState();
}

class _ManutencaoAdvancedSearchScreenState
    extends State<ManutencaoAdvancedSearchScreen> {
  // ============ CONTROLADORES ============

  final _textoController = TextEditingController();
  StatusChamadoManutencao? _statusSelecionado;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  // ============ ESTADO ============

  List<ChamadoManutencao> _resultados = [];
  bool _buscando = false;
  bool _buscaRealizada = false;

  final _manutencaoService = ManutencaoService();

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
      final todosChamados = await _manutencaoService
          .getChamadosParaAdminManutencao()
          .first;

      // Aplicar filtros
      List<ChamadoManutencao> resultadosFiltrados = todosChamados;

      // Filtro: Texto livre
      if (_textoController.text.isNotEmpty) {
        final textoBusca = _textoController.text.toLowerCase();
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.titulo.toLowerCase().contains(textoBusca) ||
              chamado.descricao.toLowerCase().contains(textoBusca) ||
              chamado.criadorNome.toLowerCase().contains(textoBusca);
        }).toList();
      }

      // Filtro: Status
      if (_statusSelecionado != null) {
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.status == _statusSelecionado;
        }).toList();
      }

      // Filtro: Data início
      if (_dataInicio != null) {
        resultadosFiltrados = resultadosFiltrados.where((chamado) {
          return chamado.dataAbertura.isAfter(_dataInicio!) ||
              chamado.dataAbertura.isAtSameMomentAs(_dataInicio!);
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
          return chamado.dataAbertura.isBefore(dataFimFinal) ||
              chamado.dataAbertura.isAtSameMomentAs(dataFimFinal);
        }).toList();
      }

      // Ordenar por data (mais recentes primeiro)
      resultadosFiltrados.sort(
        (a, b) => b.dataAbertura.compareTo(a.dataAbertura),
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
    final theme = Theme.of(context);
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    // DS cores usadas diretamente

    return Container(
      color: isDarkMode ? DS.background : const Color(0xFFF5F7FA),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Busca Avançada',
            style: TextStyle(
              color: isDarkMode ? DS.textPrimary : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDarkMode ? DS.textPrimary : Colors.black87,
          ),
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
                      decoration: InputDecoration(
                        labelText: 'Buscar por texto',
                        hintText: 'Título, descrição ou solicitante',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtro: Status
                    DropdownButtonFormField<StatusChamadoManutencao>(
                      initialValue: _statusSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os status'),
                        ),
                        ...StatusChamadoManutencao.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Text(status.emoji),
                                const SizedBox(width: 8),
                                Text(status.label),
                              ],
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

                    // Filtro: Período
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Período',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                const Icon(Icons.arrow_forward, size: 20),
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
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.list_alt,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_resultados.length} resultado(s) encontrado(s)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Lista de resultados
            if (_buscaRealizada && _resultados.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _resultados.length,
                  itemBuilder: (context, index) {
                    final chamado = _resultados[index];
                    return ManutencaoCard(
                      chamado: chamado,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ManutencaoDetalhesChamadoScreen(
                                  chamadoId: chamado.id,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            // Mensagem de nenhum resultado
            if (_buscaRealizada && _resultados.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum resultado encontrado',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
