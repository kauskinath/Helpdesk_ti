import 'package:flutter/material.dart';

/// Mixin para adicionar funcionalidade de filtros em dashboards
/// 
/// Fornece estado e lógica para filtrar listas de items por:
/// - Status (enum genérico)
/// - Texto de busca (título, descrição, etc)
/// 
/// Uso:
/// ```dart
/// class _MyDashboardState extends State<MyDashboard> 
///     with FilterableMixin<Chamado, StatusChamado> {
///   
///   @override
///   bool matchesFilter(Chamado item, StatusChamado? status, String texto) {
///     // Implementar lógica específica
///   }
/// }
/// ```
mixin FilterableMixin<T, S> on State {
  /// Status selecionado para filtro (null = todos)
  S? filtroStatus;
  
  /// Texto de busca (vazio = sem filtro)
  String buscaTexto = '';

  /// Método abstrato que cada tela deve implementar
  /// Define como um item deve ser filtrado baseado em status e texto
  bool matchesFilter(T item, S? status, String texto);

  /// Aplica filtros em uma lista de items
  List<T> aplicarFiltros(List<T> items) {
    return items.where((item) => matchesFilter(item, filtroStatus, buscaTexto)).toList();
  }

  /// Atualiza o filtro de status
  void atualizarFiltroStatus(S? novoStatus) {
    setState(() {
      filtroStatus = novoStatus;
    });
  }

  /// Atualiza o texto de busca
  void atualizarBuscaTexto(String novoTexto) {
    setState(() {
      buscaTexto = novoTexto.toLowerCase();
    });
  }

  /// Limpa todos os filtros
  void limparFiltros() {
    setState(() {
      filtroStatus = null;
      buscaTexto = '';
    });
  }

  /// Verifica se há algum filtro ativo
  bool get temFiltrosAtivos => filtroStatus != null || buscaTexto.isNotEmpty;

  /// Widget helper para exibir badge de filtro ativo
  Widget? buildFiltroBadge({
    required String statusLabel,
    required String statusEmoji,
    Color? backgroundColor,
  }) {
    if (filtroStatus == null) return null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(statusEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Filtro: $statusLabel',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: limparFiltros,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Limpar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Widget helper para campo de busca
  Widget buildCampoBusca({
    String hint = '🔍 Buscar por título ou descrição...',
    EdgeInsets padding = const EdgeInsets.all(8.0),
  }) {
    return Padding(
      padding: padding,
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: atualizarBuscaTexto,
      ),
    );
  }
}
