/// Enums para o módulo de Manutenção
library;

/// Status do chamado de manutenção
enum StatusChamadoManutencao {
  // Fluxo inicial
  aberto('ABERTO', 'Aberto', '🆕'),
  emValidacaoAdmin('EM_VALIDACAO_ADMIN', 'Em Validação', '🔍'),
  
  // Fluxo COM orçamento
  aguardandoAprovacaoGerente('AGUARDANDO_APROVACAO_GERENTE', 'Aguardando Aprovação', '⏳'),
  orcamentoAprovado('ORCAMENTO_APROVADO', 'Orçamento Aprovado', '✅'),
  orcamentoRejeitado('ORCAMENTO_REJEITADO', 'Orçamento Rejeitado', '❌'),
  emCompra('EM_COMPRA', 'Em Compra', '🛒'),
  aguardandoMateriais('AGUARDANDO_MATERIAIS', 'Aguardando Materiais', '📦'),
  
  // Fluxo SEM orçamento (direto)
  liberadoParaExecucao('LIBERADO_PARA_EXECUCAO', 'Liberado para Execução', '🟢'),
  
  // Execução (ambos os fluxos)
  atribuidoExecutor('ATRIBUIDO_EXECUTOR', 'Atribuído ao Executor', '👷'),
  emExecucao('EM_EXECUCAO', 'Em Execução', '🔧'),
  recusadoExecutor('RECUSADO_EXECUTOR', 'Recusado pelo Executor', '🚫'),
  
  // Finalização
  finalizado('FINALIZADO', 'Finalizado', '✔️'),
  cancelado('CANCELADO', 'Cancelado', '❌');

  final String value;
  final String label;
  final String emoji;

  const StatusChamadoManutencao(this.value, this.label, this.emoji);

  /// Retorna cor do status
  String get colorHex {
    switch (this) {
      case StatusChamadoManutencao.aberto:
      case StatusChamadoManutencao.emValidacaoAdmin:
        return '#2196F3'; // Azul
      case StatusChamadoManutencao.aguardandoAprovacaoGerente:
        return '#FF9800'; // Laranja
      case StatusChamadoManutencao.orcamentoAprovado:
      case StatusChamadoManutencao.liberadoParaExecucao:
        return '#4CAF50'; // Verde
      case StatusChamadoManutencao.orcamentoRejeitado:
      case StatusChamadoManutencao.recusadoExecutor:
      case StatusChamadoManutencao.cancelado:
        return '#F44336'; // Vermelho
      case StatusChamadoManutencao.emCompra:
      case StatusChamadoManutencao.aguardandoMateriais:
        return '#9C27B0'; // Roxo
      case StatusChamadoManutencao.atribuidoExecutor:
      case StatusChamadoManutencao.emExecucao:
        return '#009688'; // Teal
      case StatusChamadoManutencao.finalizado:
        return '#607D8B'; // Cinza
    }
  }

  /// Converte string para enum
  static StatusChamadoManutencao fromString(String value) {
    return StatusChamadoManutencao.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StatusChamadoManutencao.aberto,
    );
  }
}

/// Tipo de criador do chamado
enum TipoCriadorChamado {
  usuarioComum('user', 'Usuário Comum', '👤'),
  adminManutencao('admin_manutencao', 'Supervisor Manutenção', '🛠️'),
  executor('executor', 'Executor', '🔧');

  final String value;
  final String label;
  final String emoji;

  const TipoCriadorChamado(this.value, this.label, this.emoji);

  static TipoCriadorChamado fromString(String value) {
    return TipoCriadorChamado.values.firstWhere(
      (tipo) => tipo.value == value,
      orElse: () => TipoCriadorChamado.usuarioComum,
    );
  }
}

/// Status da compra de materiais
enum StatusCompra {
  naoIniciado('NAO_INICIADO', 'Não Iniciado'),
  emAndamento('EM_ANDAMENTO', 'Em Andamento'),
  concluido('CONCLUIDO', 'Concluído');

  final String value;
  final String label;

  const StatusCompra(this.value, this.label);

  static StatusCompra fromString(String value) {
    return StatusCompra.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StatusCompra.naoIniciado,
    );
  }
}
