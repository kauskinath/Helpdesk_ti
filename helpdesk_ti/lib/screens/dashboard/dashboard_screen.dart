import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/chamado_service.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';

/// Dashboard com estatísticas e gráficos do sistema
///
/// Esta tela exibe:
/// - Cards com resumo de números (Total, Abertos, Em Andamento, Fechados)
/// - Gráfico de Pizza mostrando distribuição por Status
/// - Gráfico de Barras mostrando distribuição por Setor
/// - Gráfico de Prioridades
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============ SERVIÇOS ============
  final ChamadoService _chamadoService = ChamadoService();

  // ============ ESTADO ============
  Map<String, dynamic> _stats = {};
  bool _carregando = true;

  // ============ LIFECYCLE ============

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// Carrega as estatísticas do banco de dados
  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    try {
      // Buscar estatísticas gerais de admin
      final stats = await _chamadoService.getStatsAdmin();

      setState(() {
        _stats = stats;
        _carregando = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar dashboard: $e');
      setState(() => _carregando = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  /// Confirma e deleta todos os chamados (APENAS PARA TESTES!)
  Future<void> _confirmarDeletarTodos() async {
    // PRIMEIRA CONFIRMAÇÃO
    final confirmar1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('⚠️ ATENÇÃO!'),
          ],
        ),
        content: const Text(
          'Você está prestes a DELETAR TODOS OS CHAMADOS do sistema!\n\n'
          'Esta ação é IRREVERSÍVEL e só deve ser usada em ambiente de TESTE.\n\n'
          'Deseja continuar?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Continuar'),
          ),
        ],
      ),
    );

    if (confirmar1 != true) return;

    // SEGUNDA CONFIRMAÇÃO (segurança extra)
    if (!mounted) return;
    final confirmar2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ CONFIRMAÇÃO FINAL'),
        content: const Text(
          'Tem CERTEZA ABSOLUTA?\n\n'
          'Todos os chamados, comentários e histórico serão PERDIDOS!\n\n'
          'Digite "DELETAR" para confirmar:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETAR TUDO',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar2 != true) return;

    // EXECUTAR DELEÇÃO
    try {
      // Mostrar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Text('Deletando todos os chamados...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Deletar todos os chamados
      final totalDeletado = await _chamadoService.deletarTodosChamados();

      // Recarregar dados
      await _carregarDados();

      // Mostrar sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $totalDeletado chamados deletados com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao deletar chamados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao deletar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        title: const Text(
          '📊 Dashboard',
          style: TextStyle(color: DS.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: DS.textPrimary),
        elevation: 0,
        actions: [
          // Botão de atualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar dados',
          ),
          // Botão de deletar todos os chamados (APENAS PARA TESTES!)
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _confirmarDeletarTodos,
            tooltip: 'Deletar todos os chamados (TESTE)',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========== CARDS DE RESUMO ==========
                    _buildCardsResumo(),

                    const SizedBox(height: 24),

                    // ========== GRÁFICO DE PIZZA - STATUS ==========
                    _buildSecaoGraficoPizza(),

                    const SizedBox(height: 24),

                    // ========== GRÁFICO DE PRIORIDADES ==========
                    _buildSecaoGraficoPrioridades(),

                    const SizedBox(height: 24),

                    // ========== GRÁFICO DE BARRAS - SETORES ==========
                    _buildSecaoGraficoBarras(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ============ WIDGETS DE CARDS ==========

  /// Constrói os 4 cards de resumo no topo
  Widget _buildCardsResumo() {
    final total = _stats['total'] ?? 0;
    final abertos = _stats['abertos'] ?? 0;
    final emAndamento = _stats['emAndamento'] ?? 0;
    final fechados = _stats['fechados'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo Geral',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DS.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCard(
                titulo: 'Total',
                valor: total.toString(),
                icone: Icons.confirmation_number,
                cor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                titulo: 'Abertos',
                valor: abertos.toString(),
                icone: Icons.fiber_new,
                cor: AppColors.statusOpen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCard(
                titulo: 'Em Andamento',
                valor: emAndamento.toString(),
                icone: Icons.pending_actions,
                cor: AppColors.statusInProgress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                titulo: 'Fechados',
                valor: fechados.toString(),
                icone: Icons.check_circle,
                cor: AppColors.statusClosed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói um card individual de estatística
  ///
  /// [titulo] - Texto do título do card (ex: "Total")
  /// [valor] - Número a exibir (ex: "150")
  /// [icone] - Ícone a mostrar
  /// [cor] - Cor do card
  Widget _buildCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: DS.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(fontSize: 14, color: DS.textSecondary),
          ),
        ],
      ),
    );
  }

  // ============ GRÁFICO DE PIZZA (STATUS) ==========

  /// Constrói a seção do gráfico de pizza
  Widget _buildSecaoGraficoPizza() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuição por Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DS.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 250, child: _buildGraficoPizza()),
        ],
      ),
    );
  }

  /// Constrói o gráfico de pizza mostrando status
  Widget _buildGraficoPizza() {
    final abertos = (_stats['abertos'] ?? 0).toDouble();
    final emAndamento = (_stats['emAndamento'] ?? 0).toDouble();
    final fechados = (_stats['fechados'] ?? 0).toDouble();
    final total = abertos + emAndamento + fechados;

    // Se não há dados, mostrar mensagem
    if (total == 0) {
      return const Center(
        child: Text(
          'Nenhum chamado registrado',
          style: TextStyle(color: DS.textSecondary),
        ),
      );
    }

    return Row(
      children: [
        // Gráfico
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                // Abertos
                PieChartSectionData(
                  value: abertos,
                  title: '${((abertos / total) * 100).toStringAsFixed(0)}%',
                  color: AppColors.statusOpen,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Em Andamento
                PieChartSectionData(
                  value: emAndamento,
                  title: '${((emAndamento / total) * 100).toStringAsFixed(0)}%',
                  color: AppColors.statusInProgress,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Fechados
                PieChartSectionData(
                  value: fechados,
                  title: '${((fechados / total) * 100).toStringAsFixed(0)}%',
                  color: AppColors.statusClosed,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Legenda
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendaItem(
                cor: AppColors.statusOpen,
                texto: 'Abertos',
                valor: abertos.toInt(),
              ),
              const SizedBox(height: 8),
              _buildLegendaItem(
                cor: AppColors.statusInProgress,
                texto: 'Em Andamento',
                valor: emAndamento.toInt(),
              ),
              const SizedBox(height: 8),
              _buildLegendaItem(
                cor: AppColors.statusClosed,
                texto: 'Fechados',
                valor: fechados.toInt(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Item da legenda do gráfico
  Widget _buildLegendaItem({
    required Color cor,
    required String texto,
    required int valor,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$texto: $valor',
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  // ============ GRÁFICO DE PRIORIDADES ==========

  /// Constrói a seção do gráfico de prioridades
  Widget _buildSecaoGraficoPrioridades() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chamados por Prioridade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DS.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildGraficoPrioridades(),
        ],
      ),
    );
  }

  /// Constrói barras horizontais de prioridades
  Widget _buildGraficoPrioridades() {
    final critica = _stats['prioridadeCritica'] ?? 0;
    final alta = _stats['prioridadeAlta'] ?? 0;
    final media = _stats['prioridadeMedia'] ?? 0;
    final baixa = _stats['prioridadeBaixa'] ?? 0;

    final total = critica + alta + media + baixa;

    if (total == 0) {
      return const Center(
        child: Text(
          'Nenhum chamado registrado',
          style: TextStyle(color: DS.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        _buildBarraPrioridade(
          label: '⚠️ Crítica',
          valor: critica,
          total: total,
          cor: Colors.red,
        ),
        const SizedBox(height: 12),
        _buildBarraPrioridade(
          label: '🔼 Alta',
          valor: alta,
          total: total,
          cor: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildBarraPrioridade(
          label: '➖ Média',
          valor: media,
          total: total,
          cor: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildBarraPrioridade(
          label: '🔽 Baixa',
          valor: baixa,
          total: total,
          cor: Colors.green,
        ),
      ],
    );
  }

  /// Barra horizontal de prioridade
  Widget _buildBarraPrioridade({
    required String label,
    required int valor,
    required int total,
    required Color cor,
  }) {
    final percentual = total > 0 ? (valor / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$valor (${(percentual * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentual,
            minHeight: 24,
            backgroundColor: cor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ],
    );
  }

  // ============ GRÁFICO DE BARRAS (SETORES) ==========

  /// Constrói a seção do gráfico de barras de setores
  Widget _buildSecaoGraficoBarras() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chamados por Setor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DS.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: _buildGraficoBarras()),
        ],
      ),
    );
  }

  /// Constrói o gráfico de barras mostrando setores
  Widget _buildGraficoBarras() {
    final Map<String, int> porSetor = Map<String, int>.from(
      _stats['chamadosPorSetor'] ?? {},
    );

    // Se não há dados
    if (porSetor.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum chamado registrado',
          style: TextStyle(color: DS.textSecondary),
        ),
      );
    }

    // Preparar dados para o gráfico
    final setores = porSetor.keys.toList();
    final valores = porSetor.values.toList();
    final maxValor = valores.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValor * 1.2, // 20% acima do máximo
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${setores[groupIndex]}\n${rod.toY.toInt()} chamados',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < setores.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      setores[value.toInt()],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12, color: DS.textSecondary),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValor / 5,
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: AppColors.greyLight, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          setores.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: valores[index].toDouble(),
                color: AppColors.primary,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
