import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import '../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../widgets/ticket_card_v2.dart';
import 'chamado/ticket_details_refactored.dart';

/// Tela de Histórico Completo para Gerente
///
/// Exibe SOMENTE chamados FECHADOS (concluídos) de TI e Manutenção juntos
class GerenteHistoricoCompletoScreen extends StatefulWidget {
  const GerenteHistoricoCompletoScreen({super.key});

  @override
  State<GerenteHistoricoCompletoScreen> createState() =>
      _GerenteHistoricoCompletoScreenState();
}

class _GerenteHistoricoCompletoScreenState
    extends State<GerenteHistoricoCompletoScreen> {
  String _filtroSelecionado = '30'; // 7, 30, 90 ou 'todos'

  DateTime? get _dataInicio {
    if (_filtroSelecionado == 'todos') return null;
    final dias = int.parse(_filtroSelecionado);
    return DateTime.now().subtract(Duration(days: dias));
  }

  /// Stream que busca APENAS chamados FECHADOS de TI e Manutenção
  Stream<List<Chamado>> _getChamadosFechados() {
    final firestoreService = context.read<FirestoreService>();

    return firestoreService.getTodosChamadosStream().map((chamados) {
      // Filtrar apenas chamados FECHADOS (status: Fechado)
      var filtrados = chamados.where((c) => c.status == 'Fechado').toList();

      // Aplicar filtro de data se necessário
      if (_dataInicio != null) {
        filtrados = filtrados.where((c) {
          return c.dataCriacao.isAfter(_dataInicio!);
        }).toList();
      }

      // Ordenar por data de criação (mais recente primeiro)
      filtrados.sort((a, b) {
        return b.dataCriacao.compareTo(a.dataCriacao);
      });

      return filtrados;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userName = authService.userName ?? 'Gerente';
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header com botão voltar, saudação e tema
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Botão voltar
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Voltar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Saudação e título
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $userName!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                              shadows: isDarkMode
                                  ? null
                                  : [
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                          ),
                          Text(
                            '📋 Histórico - Chamados Fechados',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.black,
                              shadows: isDarkMode
                                  ? null
                                  : [
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                      const Shadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botão de alternar tema
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          context.read<ThemeProvider>().toggleTheme();
                        },
                        tooltip: isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                      ),
                    ),
                  ],
                ),
              ),

              // Filtro de período
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Período: ',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        shadows: isDarkMode
                            ? null
                            : [
                                const Shadow(
                                  color: Colors.white,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                                const Shadow(
                                  color: Colors.white,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFiltroChip('7', '7 dias'),
                            const SizedBox(width: 8),
                            _buildFiltroChip('30', '30 dias'),
                            const SizedBox(width: 8),
                            _buildFiltroChip('90', '90 dias'),
                            const SizedBox(width: 8),
                            _buildFiltroChip('todos', 'Todos'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lista de chamados fechados
              Expanded(
                child: StreamBuilder<List<Chamado>>(
                  stream: _getChamadosFechados(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: isDarkMode ? Colors.white : Colors.blue,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar histórico',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final chamados = snapshot.data ?? [];

                    if (chamados.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum chamado fechado',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'no período selecionado',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chamados.length,
                      itemBuilder: (context, index) {
                        final chamado = chamados[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TicketCardV2(
                            numeroFormatado: chamado.numeroFormatado,
                            titulo: chamado.titulo,
                            status: chamado.status,
                            prioridade: chamado.prioridade,
                            usuarioNome: chamado.usuarioNome,
                            lastUpdated: chamado.lastUpdated,
                            numeroComentarios: chamado.numeroComentarios,
                            temAnexos: chamado.anexos.isNotEmpty,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketDetailsRefactored(
                                    chamado: chamado,
                                    firestoreService: context
                                        .read<FirestoreService>(),
                                    authService: context.read<AuthService>(),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label) {
    final isSelected = _filtroSelecionado == valor;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroSelecionado = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : isDarkMode
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade300
                : isDarkMode
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDarkMode
                ? Colors.white
                : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
