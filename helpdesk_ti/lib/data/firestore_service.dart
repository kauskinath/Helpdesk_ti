import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'services/chamado_service.dart';
import 'services/avaliacao_service.dart';
import 'services/template_service.dart';
import 'solicitacao_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/features/ti/models/avaliacao.dart';
import 'package:helpdesk_ti/features/ti/models/chamado_template.dart';
import 'package:helpdesk_ti/features/ti/models/solicitacao.dart';

/// FirestoreService Principal - Fachada unificada para todos os serviços
///
/// Esta classe atua como ponto de entrada único para todas as operações de
/// dados do aplicativo. Ela delega as operações para serviços especializados:
///
/// - **ChamadoService**: Gerencia chamados/tickets (CRUD, status, anexos)
/// - **AvaliacaoService**: Gerencia avaliações de atendimento
/// - **TemplateService**: Gerencia templates reutilizáveis
/// - **SolicitacaoService**: Gerencia solicitações que precisam aprovação
///
/// ## Benefícios da Arquitetura Modular:
///
/// 1. **Separação de Responsabilidades**: Cada serviço tem uma responsabilidade clara
/// 2. **Manutenibilidade**: Mais fácil encontrar e corrigir bugs
/// 3. **Testabilidade**: Serviços podem ser testados independentemente
/// 4. **Escalabilidade**: Novos serviços podem ser adicionados sem afetar existentes
/// 5. **Legibilidade**: Código organizado em arquivos menores e focados
///
/// ## Como usar:
///
/// ```dart
/// final firestoreService = FirestoreService();
///
/// // Criar chamado
/// await firestoreService.criarChamado(chamado);
///
/// // Criar avaliação
/// await firestoreService.criarAvaliacao(avaliacao);
///
/// // Buscar templates
/// firestoreService.getTemplatesAtivos();
/// ```
///
/// ## Migração do código antigo:
///
/// O código antigo (FirestoreService monolítico com 1077 linhas) foi refatorado
/// em 4 serviços especializados. Todas as funcionalidades foram preservadas,
/// apenas reorganizadas para melhor manutenção.
class FirestoreService {
  // Instâncias dos serviços especializados
  final ChamadoService _chamadoService = ChamadoService();
  final AvaliacaoService _avaliacaoService = AvaliacaoService();
  final TemplateService _templateService = TemplateService();
  final SolicitacaoService _solicitacaoService = SolicitacaoService();

  // ============================================================
  // MÉTODOS DE CHAMADOS - Delegam para ChamadoService
  // ============================================================

  /// Gera próximo número sequencial para chamados
  /// Delegado para: ChamadoService.gerarProximoNumero()
  Future<int> gerarProximoNumero() => _chamadoService.gerarProximoNumero();

  /// Cria um novo chamado
  /// Delegado para: ChamadoService.criarChamado()
  Future<String> criarChamado(Chamado chamado) =>
      _chamadoService.criarChamado(chamado);

  /// Busca um chamado específico por ID
  /// Delegado para: ChamadoService.getChamado()
  Future<Chamado?> getChamado(String chamadoId) =>
      _chamadoService.getChamado(chamadoId);

  /// Stream de chamados de um usuário
  /// Delegado para: ChamadoService.getChamadosDoUsuario()
  Stream<List<Chamado>> getChamadosDoUsuario(String userId) =>
      _chamadoService.getChamadosDoUsuario(userId);

  /// Stream de todos os chamados (para admin)
  /// Delegado para: ChamadoService.getTodosChamadosStream()
  Stream<List<Chamado>> getTodosChamadosStream() =>
      _chamadoService.getTodosChamadosStream();

  /// Stream de chamados por status
  /// Delegado para: ChamadoService.getChamadosPorStatus()
  Stream<List<Chamado>> getChamadosPorStatus(String status) =>
      _chamadoService.getChamadosPorStatus(status);

  /// Atualiza status de um chamado
  /// Delegado para: ChamadoService.atualizarStatus()
  Future<void> atualizarStatus(String chamadoId, String novoStatus) =>
      _chamadoService.atualizarStatus(chamadoId, novoStatus);

  /// Atribui admin a um chamado
  /// Delegado para: ChamadoService.atribuirAdmin()
  Future<void> atribuirAdmin(
    String chamadoId,
    String adminId,
    String adminNome,
  ) => _chamadoService.atribuirAdmin(chamadoId, adminId, adminNome);

  /// Atualiza prioridade de um chamado
  /// Delegado para: ChamadoService.atualizarPrioridade()
  Future<void> atualizarPrioridade(String chamadoId, int prioridade) =>
      _chamadoService.atualizarPrioridade(chamadoId, prioridade);

  /// Faz upload de imagem
  /// Delegado para: ChamadoService.uploadImage()
  Future<String> uploadImage(String chamadoId, XFile imageFile) =>
      _chamadoService.uploadImage(chamadoId, imageFile);

  /// Adiciona comentário em coleção separada (versão named params)
  /// Delegado para: ChamadoService.adicionarComentarioNamed()
  Future<void> adicionarComentario({
    required String chamadoId,
    required String autorId,
    required String autorNome,
    required String autorRole,
    required String mensagem,
    String? tipo,
  }) => _chamadoService.adicionarComentarioNamed(
    chamadoId: chamadoId,
    autorId: autorId,
    autorNome: autorNome,
    autorRole: autorRole,
    mensagem: mensagem,
    tipo: tipo,
  );

  /// Adiciona comentário no array do documento (versão com mapa)
  /// Delegado para: ChamadoService.adicionarComentarioMap()
  Future<void> adicionarComentarioMap(
    String chamadoId,
    Map<String, dynamic> comentario,
  ) => _chamadoService.adicionarComentarioMap(chamadoId, comentario);

  /// Atualiza chamado com dados parciais
  /// Delegado para: ChamadoService.atualizarChamado()
  Future<void> atualizarChamado(String chamadoId, Map<String, dynamic> dados) =>
      _chamadoService.atualizarChamado(chamadoId, dados);

  /// Atualiza chamado completo com objeto
  /// Delegado para: ChamadoService.atualizarChamadoCompleto()
  Future<void> atualizarChamadoCompleto(Chamado chamado) =>
      _chamadoService.atualizarChamadoCompleto(chamado);

  /// Estatísticas de chamados do usuário
  /// Delegado para: ChamadoService.getStatsUsuario()
  Future<Map<String, dynamic>> getStatsUsuario(String userId) =>
      _chamadoService.getStatsUsuario(userId);

  /// Estatísticas gerais para admin
  /// Delegado para: ChamadoService.getStatsAdmin()
  Future<Map<String, dynamic>> getStatsAdmin() =>
      _chamadoService.getStatsAdmin();

  /// Deleta um chamado
  /// Delegado para: ChamadoService.deletarChamado()
  Future<void> deletarChamado(String chamadoId) =>
      _chamadoService.deletarChamado(chamadoId);

  /// Deleta todos os chamados (desenvolvimento)
  /// Delegado para: ChamadoService.deletarTodosChamados()
  Future<int> deletarTodosChamados() => _chamadoService.deletarTodosChamados();

  // ============================================================
  // MÉTODOS DE AVALIAÇÕES - Delegam para AvaliacaoService
  // ============================================================

  /// Cria avaliação para um chamado
  /// Delegado para: AvaliacaoService.criarAvaliacao()
  Future<void> criarAvaliacao(Avaliacao avaliacao) =>
      _avaliacaoService.criarAvaliacao(avaliacao);

  /// Busca avaliação de um chamado
  /// Delegado para: AvaliacaoService.getAvaliacaoPorChamado()
  Future<Avaliacao?> getAvaliacaoPorChamado(String chamadoId) =>
      _avaliacaoService.getAvaliacaoPorChamado(chamadoId);

  /// Stream de avaliações de um admin
  /// Delegado para: AvaliacaoService.getAvaliacoesDoAdmin()
  Stream<List<Avaliacao>> getAvaliacoesDoAdmin(String adminId) =>
      _avaliacaoService.getAvaliacoesDoAdmin(adminId);

  /// Stream de todas as avaliações
  /// Delegado para: AvaliacaoService.getTodasAvaliacoes()
  Stream<List<Avaliacao>> getTodasAvaliacoes() =>
      _avaliacaoService.getTodasAvaliacoes();

  /// Estatísticas de avaliação de um admin
  /// Delegado para: AvaliacaoService.getEstatisticasAvaliacoes()
  Future<Map<String, dynamic>> getEstatisticasAvaliacoes(String adminId) =>
      _avaliacaoService.getEstatisticasAvaliacoes(adminId);

  /// Estatísticas gerais de avaliações
  /// Delegado para: AvaliacaoService.getEstatisticasGeraisAvaliacoes()
  Future<Map<String, dynamic>> getEstatisticasGeraisAvaliacoes() =>
      _avaliacaoService.getEstatisticasGeraisAvaliacoes();

  /// Deleta uma avaliação
  /// Delegado para: AvaliacaoService.deletarAvaliacao()
  Future<void> deletarAvaliacao(String avaliacaoId) =>
      _avaliacaoService.deletarAvaliacao(avaliacaoId);

  // ============================================================
  // MÉTODOS DE TEMPLATES - Delegam para TemplateService
  // ============================================================

  /// Cria um novo template
  /// Delegado para: TemplateService.criarTemplate()
  Future<String> criarTemplate(ChamadoTemplate template) =>
      _templateService.criarTemplate(template);

  /// Atualiza template existente
  /// Delegado para: TemplateService.atualizarTemplate()
  Future<void> atualizarTemplate(ChamadoTemplate template) =>
      _templateService.atualizarTemplate(template);

  /// Desativa um template
  /// Delegado para: TemplateService.deletarTemplate()
  Future<void> deletarTemplate(String templateId) =>
      _templateService.deletarTemplate(templateId);

  /// Reativa um template
  /// Delegado para: TemplateService.reativarTemplate()
  Future<void> reativarTemplate(String templateId) =>
      _templateService.reativarTemplate(templateId);

  /// Stream de templates ativos
  /// Delegado para: TemplateService.getTemplatesAtivos()
  Stream<List<ChamadoTemplate>> getTemplatesAtivos() =>
      _templateService.getTemplatesAtivos();

  /// Stream de todos os templates
  /// Delegado para: TemplateService.getTodosTemplates()
  Stream<List<ChamadoTemplate>> getTodosTemplates() =>
      _templateService.getTodosTemplates();

  /// Stream de templates por setor
  /// Delegado para: TemplateService.getTemplatesPorSetor()
  Stream<List<ChamadoTemplate>> getTemplatesPorSetor(String setor) =>
      _templateService.getTemplatesPorSetor(setor);

  /// Busca template por ID
  /// Delegado para: TemplateService.getTemplatePorId()
  Future<ChamadoTemplate?> getTemplatePorId(String templateId) =>
      _templateService.getTemplatePorId(templateId);

  /// Stream de templates por tag
  /// Delegado para: TemplateService.getTemplatesPorTag()
  Stream<List<ChamadoTemplate>> getTemplatesPorTag(String tag) =>
      _templateService.getTemplatesPorTag(tag);

  /// Cria templates padrão do sistema
  /// Delegado para: TemplateService.criarTemplatesPadrao()
  Future<void> criarTemplatesPadrao(String adminId, String adminNome) =>
      _templateService.criarTemplatesPadrao(adminId, adminNome);

  /// Conta templates ativos
  /// Delegado para: TemplateService.contarTemplatesAtivos()
  Future<int> contarTemplatesAtivos() =>
      _templateService.contarTemplatesAtivos();

  /// Deleta template permanentemente
  /// Delegado para: TemplateService.deletarTemplatePermanente()
  Future<void> deletarTemplatePermanente(String templateId) =>
      _templateService.deletarTemplatePermanente(templateId);

  // ============================================================
  // MÉTODOS DE SOLICITAÇÕES - Delegam para SolicitacaoService
  // ============================================================

  /// Cria uma nova solicitação
  /// Delegado para: SolicitacaoService.criarSolicitacao()
  Future<String> criarSolicitacao(Solicitacao solicitacao) =>
      _solicitacaoService.criarSolicitacao(solicitacao);

  /// Busca solicitação por ID
  /// Delegado para: SolicitacaoService.getSolicitacao()
  Future<Solicitacao?> getSolicitacao(String solicitacaoId) =>
      _solicitacaoService.getSolicitacao(solicitacaoId);

  /// Stream de solicitações de um usuário
  /// Delegado para: SolicitacaoService.getSolicitacoesDoUsuario()
  Stream<List<Solicitacao>> getSolicitacoesDoUsuario(String userId) =>
      _solicitacaoService.getSolicitacoesDoUsuario(userId);

  /// Stream de solicitações pendentes
  /// Delegado para: SolicitacaoService.getSolicitacoesPendentes()
  Stream<List<Solicitacao>> getSolicitacoesPendentes() =>
      _solicitacaoService.getSolicitacoesPendentes();

  /// Stream de todas as solicitações
  /// Delegado para: SolicitacaoService.getTodasSolicitacoes()
  Stream<List<Solicitacao>> getTodasSolicitacoes() =>
      _solicitacaoService.getTodasSolicitacoes();

  /// Aprova uma solicitação
  /// Delegado para: SolicitacaoService.aprovarSolicitacao()
  Future<void> aprovarSolicitacao(
    String solicitacaoId,
    String managerId,
    String managerNome,
  ) => _solicitacaoService.aprovarSolicitacao(
    solicitacaoId,
    managerId,
    managerNome,
  );

  /// Rejeita uma solicitação
  /// Delegado para: SolicitacaoService.rejeitarSolicitacao()
  Future<void> rejeitarSolicitacao(
    String solicitacaoId,
    String managerId,
    String managerNome,
    String motivo,
  ) => _solicitacaoService.rejeitarSolicitacao(
    solicitacaoId,
    managerId,
    managerNome,
    motivo,
  );

  /// Atualiza status de uma solicitação
  /// Delegado para: SolicitacaoService.atualizarStatusSolicitacao()
  Future<void> atualizarStatusSolicitacao(
    String solicitacaoId,
    String novoStatus,
  ) =>
      _solicitacaoService.atualizarStatusSolicitacao(solicitacaoId, novoStatus);

  /// Atualiza solicitação completa
  /// Delegado para: SolicitacaoService.atualizarSolicitacao()
  Future<void> atualizarSolicitacao(Solicitacao solicitacao) =>
      _solicitacaoService.atualizarSolicitacao(solicitacao);

  /// Cria chamado a partir de solicitação aprovada
  /// Delegado para: ChamadoService.criarChamadoDeSolicitacao()
  Future<String> criarChamadoDeSolicitacao({
    required Solicitacao solicitacao,
  }) => _chamadoService.criarChamadoDeSolicitacao(solicitacao: solicitacao);

  /// Stream de solicitações pendentes
  /// Delegado para: SolicitacaoService.getSolicitacoesPendentesStream()
  Stream<List<Solicitacao>> getSolicitacoesPendentesStream() =>
      _solicitacaoService.getSolicitacoesPendentesStream();

  /// Stream de solicitações processadas (aprovadas/rejeitadas)
  /// Delegado para: SolicitacaoService.getSolicitacoesProcessadasStream()
  Stream<List<Solicitacao>> getSolicitacoesProcessadasStream() =>
      _solicitacaoService.getSolicitacoesProcessadasStream();

  /// Stream de comentários de um chamado
  /// Delegado para: ChamadoService.getComentariosStream()
  Stream<List<Map<String, dynamic>>> getComentariosStream(String chamadoId) =>
      _chamadoService.getComentariosStream(chamadoId);

  /// Busca comentários com paginação (versão otimizada)
  /// Delegado para: ChamadoService.getComentariosPaginados()
  Future<Map<String, dynamic>> getComentariosPaginados(
    String chamadoId, {
    int limite = 20,
    DocumentSnapshot? ultimoDocumento,
  }) => _chamadoService.getComentariosPaginados(
    chamadoId,
    limite: limite,
    ultimoDocumento: ultimoDocumento,
  );

  /// Conta o total de comentários de um chamado
  /// Delegado para: ChamadoService.getTotalComentarios()
  Future<int> getTotalComentarios(String chamadoId) =>
      _chamadoService.getTotalComentarios(chamadoId);

  /// Estatísticas para manager (por setor)
  /// Delegado para: ChamadoService.getStatsManager()
  Future<Map<String, dynamic>> getStatsManager(String setor) =>
      _chamadoService.getStatsManager(setor);

  /// Stream de chamados do usuário
  /// Delegado para: ChamadoService.getChamadosDoUsuarioStream()
  Stream<List<Chamado>> getChamadosDoUsuarioStream(String usuarioId) =>
      _chamadoService.getChamadosDoUsuarioStream(usuarioId);

  // ============================================================
  // NOVOS MÉTODOS DE OTIMIZAÇÃO - Delegam para ChamadoService
  // ============================================================

  /// Busca apenas chamados ativos (não arquivados)
  /// Delegado para: ChamadoService.getChamadosAtivosStream()
  Stream<List<Chamado>> getChamadosAtivosStream() =>
      _chamadoService.getChamadosAtivosStream();

  /// Busca contadores de chamados por prioridade
  /// Delegado para: ChamadoService.getChamadosPorPrioridade()
  Future<Map<String, int>> getChamadosPorPrioridade() =>
      _chamadoService.getChamadosPorPrioridade();

  // ============================================================
  // EXCLUSÃO COMPLETA - Delegam para Services
  // ============================================================

  /// Deleta completamente um chamado de TI e todos os dados relacionados
  /// Delegado para: ChamadoService.deletarChamado()
  Future<void> deletarChamadoTI(String chamadoId) =>
      _chamadoService.deletarChamado(chamadoId);

  /// Deleta completamente uma solicitação e todos os dados relacionados
  /// Delegado para: SolicitacaoService.deletarSolicitacao()
  Future<void> deletarSolicitacao(String solicitacaoId) =>
      _solicitacaoService.deletarSolicitacao(solicitacaoId);
}
