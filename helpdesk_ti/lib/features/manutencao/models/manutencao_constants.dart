/// Constantes para o módulo de manutenção
class ManutencaoConstants {
  // ========== FIRESTORE ==========
  static const String collectionChamados = 'chamados';
  static const String collectionUsuarios = 'users';

  // ========== FIREBASE STORAGE ==========
  static const String storagePath = 'manutencao';
  static const String storageOrcamentos = 'orcamentos';
  static const String storageFotos = 'fotos';
  static const String storageNotasFiscais = 'notas_fiscais';

  // ========== TIPO DE CHAMADO ==========
  static const String tipoManutencao = 'MANUTENCAO';
  static const String tipoTI = 'TI';

  // ========== MENSAGENS DE ERRO ==========
  static const String erroTituloVazio = 'O título não pode estar vazio';
  static const String erroDescricaoVazia = 'A descrição não pode estar vazia';
  static const String erroMotivoRecusaVazio =
      'O motivo da recusa é obrigatório';
  static const String erroFotoObrigatoria =
      'A foto comprovante é obrigatória para finalizar';
  static const String erroChamadoNaoEncontrado = 'Chamado não encontrado';
  static const String erroExecutorNaoAtribuido =
      'Nenhum executor foi atribuído a este chamado';
  static const String erroStatusInvalido =
      'Status do chamado não permite esta ação';
  static const String erroPermissaoNegada =
      'Você não tem permissão para realizar esta ação';
  static const String erroOrcamentoNaoEncontrado = 'Orçamento não encontrado';
  static const String erroUploadArquivo = 'Erro ao enviar arquivo';

  // ========== MENSAGENS DE SUCESSO ==========
  static const String sucessoChamadoCriado = 'Chamado criado com sucesso';
  static const String sucessoChamadoValidado = 'Chamado validado com sucesso';
  static const String sucessoOrcamentoAprovado =
      'Orçamento aprovado com sucesso';
  static const String sucessoOrcamentoRejeitado = 'Orçamento rejeitado';
  static const String sucessoExecutorAtribuido =
      'Executor atribuído com sucesso';
  static const String sucessoExecucaoIniciada = 'Execução iniciada';
  static const String sucessoChamadoFinalizado =
      'Chamado finalizado com sucesso';
  static const String sucessoChamadoRecusado = 'Chamado recusado';
  static const String sucessoCompraAtualizada = 'Status da compra atualizado';

  // ========== VALIDAÇÕES ==========
  static const int tituloMinLength = 3;
  static const int tituloMaxLength = 100;
  static const int descricaoMinLength = 10;
  static const int descricaoMaxLength = 1000;
  static const int motivoRecusaMinLength = 10;
  static const int motivoRecusaMaxLength = 500;

  // ========== TIPOS DE ARQUIVO ACEITOS ==========
  static const List<String> extensoesOrcamento = ['pdf', 'doc', 'docx'];
  static const List<String> extensoesFoto = ['jpg', 'jpeg', 'png'];

  // ========== LIMITES ==========
  static const int maxNotasFiscais = 10;
  static const int maxItensOrcamento = 50;
  static const double maxTamanhoArquivoMB = 10.0;
  static const double maxTamanhoFotoMB = 5.0;
}
