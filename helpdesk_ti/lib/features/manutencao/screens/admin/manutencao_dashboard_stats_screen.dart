import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/manutencao_service.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';

/// Dashboard com estatísticas de Manutenção (igual ao TI)
class ManutencaoDashboardStatsScreen extends StatefulWidget {
  const ManutencaoDashboardStatsScreen({super.key});

  @override
  State<ManutencaoDashboardStatsScreen> createState() =>
      _ManutencaoDashboardStatsScreenState();
}

class _ManutencaoDashboardStatsScreenState
    extends State<ManutencaoDashboardStatsScreen> {
  final ManutencaoService _manutencaoService = ManutencaoService();

  Map<String, dynamic> _stats = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    try {
      final stats = await _manutencaoService.getStatsAdmin();

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WallpaperScaffold(
      appBar: AppBar(
        title: Text(
          '📊 Estatísticas Manutenção',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
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
                    _buildCardsResumo(),
                    const SizedBox(height: 24),
                    _buildSecaoGraficoPizza(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCard(
                titulo: 'Total',
                valor: total.toString(),
                icone: Icons.construction,
                cor: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                titulo: 'Abertos',
                valor: abertos.toString(),
                icone: Icons.fiber_new,
                cor: const Color(0xFF2196F3),
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
                cor: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                titulo: 'Fechados',
                valor: fechados.toString(),
                icone: Icons.check_circle,
                cor: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                child: Icon(icone, color: cor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoGraficoPizza() {
    final statusMap = _stats['statusMap'] as Map<String, int>? ?? {};

    if (statusMap.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('📊 Nenhum dado para exibir')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribuição por Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(statusMap),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegenda(statusMap),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> statusMap) {
    final colors = <String, Color>{
      'Aberto': const Color(0xFF2196F3),
      'Em Validação': const Color(0xFF42A5F5),
      'Aguardando Aprovação': const Color(0xFFFF9800),
      'Aprovado': const Color(0xFF66BB6A),
      'Em Compra': const Color(0xFF9C27B0),
      'Liberado': const Color(0xFF4CAF50),
      'Atribuído': const Color(0xFF00BCD4),
      'Em Execução': const Color(0xFF00BCD4),
      'Finalizado': const Color(0xFF66BB6A),
      'Rejeitado': const Color(0xFFEF5350),
      'Cancelado': const Color(0xFFEF5350),
      'Recusado': const Color(0xFFEF5350),
    };

    return statusMap.entries.map((entry) {
      final color = colors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegenda(Map<String, int> statusMap) {
    final colors = <String, Color>{
      'Aberto': const Color(0xFF2196F3),
      'Em Validação': const Color(0xFF42A5F5),
      'Aguardando Aprovação': const Color(0xFFFF9800),
      'Aprovado': const Color(0xFF66BB6A),
      'Em Compra': const Color(0xFF9C27B0),
      'Liberado': const Color(0xFF4CAF50),
      'Atribuído': const Color(0xFF00BCD4),
      'Em Execução': const Color(0xFF00BCD4),
      'Finalizado': const Color(0xFF66BB6A),
      'Rejeitado': const Color(0xFFEF5350),
      'Cancelado': const Color(0xFFEF5350),
      'Recusado': const Color(0xFFEF5350),
    };

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: statusMap.entries.map((entry) {
        final color = colors[entry.key] ?? Colors.grey;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.key} (${entry.value})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
