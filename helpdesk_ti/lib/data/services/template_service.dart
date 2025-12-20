import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helpdesk_ti/features/ti/models/chamado_template.dart';

/// Serviço responsável por todas as operações relacionadas a Templates de Chamados
///
/// Este serviço gerencia templates reutilizáveis que ajudam usuários a criar
/// chamados de forma mais rápida e padronizada:
/// - CRUD completo de templates
/// - Filtros por setor, tag, status (ativo/inativo)
/// - Sistema de tags para categorização
/// - Templates padrão pré-configurados
///
/// Os templates incluem:
/// - Título e descrição modelo
/// - Setor e tipo recomendados
/// - Prioridade sugerida
/// - Tags para filtros e ícones
class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ CRIAÇÃO E ATUALIZAÇÃO ============

  /// Cria um novo template de chamado
  ///
  /// O template é salvo na coleção 'templates' e pode ser usado por
  /// qualquer usuário ao criar um chamado novo.
  ///
  /// [template] - Objeto ChamadoTemplate com os dados do template
  ///
  /// Retorna ID do documento criado no Firestore
  Future<String> criarTemplate(ChamadoTemplate template) async {
    try {
      final docRef = await _firestore
          .collection('templates')
          .add(template.toMap());

      print('✅ Template ${docRef.id} criado com sucesso');
      return docRef.id;
    } catch (e) {
      print('❌ Erro ao criar template: $e');
      throw 'Erro ao criar template: $e';
    }
  }

  /// Atualiza um template existente
  ///
  /// [template] - Template com ID e dados atualizados
  Future<void> atualizarTemplate(ChamadoTemplate template) async {
    try {
      await _firestore
          .collection('templates')
          .doc(template.id)
          .update(template.toMap());

      print('✅ Template ${template.id} atualizado');
    } catch (e) {
      print('❌ Erro ao atualizar template: $e');
      throw 'Erro ao atualizar template: $e';
    }
  }

  /// Desativa um template - soft delete
  ///
  /// O template não é deletado, apenas marcado como inativo.
  /// Templates inativos não aparecem para usuários, mas podem ser
  /// reativados por admins.
  ///
  /// [templateId] - ID do template a ser desativado
  Future<void> deletarTemplate(String templateId) async {
    try {
      await _firestore.collection('templates').doc(templateId).update({
        'ativo': false,
      });

      print('✅ Template $templateId desativado');
    } catch (e) {
      print('❌ Erro ao deletar template: $e');
      throw 'Erro ao deletar template: $e';
    }
  }

  /// Reativa um template previamente desativado
  ///
  /// [templateId] - ID do template a ser reativado
  Future<void> reativarTemplate(String templateId) async {
    try {
      await _firestore.collection('templates').doc(templateId).update({
        'ativo': true,
      });

      print('✅ Template $templateId reativado');
    } catch (e) {
      print('❌ Erro ao reativar template: $e');
      throw 'Erro ao reativar template: $e';
    }
  }

  // ============ CONSULTAS ============

  /// Stream de todos os templates ativos
  ///
  /// Retorna apenas templates com ativo=true, ordenados alfabeticamente.
  /// Usado na tela de seleção de template para usuários.
  ///
  /// Retorna Stream de lista de templates ativos
  Stream<List<ChamadoTemplate>> getTemplatesAtivos() {
    return _firestore
        .collection('templates')
        .where('ativo', isEqualTo: true)
        .orderBy('titulo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChamadoTemplate.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream de todos os templates (incluindo inativos)
  ///
  /// Usado por admins para gerenciar todos os templates,
  /// incluindo os desativados.
  ///
  /// Retorna Stream de lista completa de templates
  Stream<List<ChamadoTemplate>> getTodosTemplates() {
    return _firestore
        .collection('templates')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChamadoTemplate.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream de templates filtrados por setor
  ///
  /// Útil para mostrar apenas templates relevantes para o setor
  /// do usuário logado.
  ///
  /// [setor] - Nome do setor
  ///
  /// Retorna Stream de templates do setor especificado
  Stream<List<ChamadoTemplate>> getTemplatesPorSetor(String setor) {
    return _firestore
        .collection('templates')
        .where('ativo', isEqualTo: true)
        .where('setor', isEqualTo: setor)
        .orderBy('titulo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChamadoTemplate.fromFirestore(doc))
              .toList(),
        );
  }

  /// Busca um template específico por ID
  ///
  /// [templateId] - ID do template
  ///
  /// Retorna ChamadoTemplate ou null se não encontrado
  Future<ChamadoTemplate?> getTemplatePorId(String templateId) async {
    try {
      final doc = await _firestore
          .collection('templates')
          .doc(templateId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ChamadoTemplate.fromFirestore(doc);
    } catch (e) {
      print('❌ Erro ao buscar template: $e');
      return null;
    }
  }

  /// Stream de templates filtrados por tag
  ///
  /// Os templates têm um array de tags (ex: 'rede', 'impressora', 'software').
  /// Este método filtra templates que contêm a tag especificada.
  ///
  /// [tag] - Tag para filtrar
  ///
  /// Retorna Stream de templates com a tag
  Stream<List<ChamadoTemplate>> getTemplatesPorTag(String tag) {
    return _firestore
        .collection('templates')
        .where('ativo', isEqualTo: true)
        .where('tags', arrayContains: tag)
        .orderBy('titulo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChamadoTemplate.fromFirestore(doc))
              .toList(),
        );
  }

  // ============ TEMPLATES PADRÃO ============

  /// Cria conjunto de 7 templates padrão para inicialização do sistema
  ///
  /// Templates criados:
  /// 1. Problema de Rede/Internet
  /// 2. Impressora Não Funciona
  /// 3. Instalação de Software
  /// 4. Problema com Email/Outlook
  /// 5. Esqueci Minha Senha
  /// 6. Computador Lento
  /// 7. Compra de Equipamento (tipo Solicitação)
  ///
  /// Cada template inclui:
  /// - Título descritivo
  /// - Modelo de descrição com campos guiados
  /// - Prioridade sugerida
  /// - Tags para filtros
  ///
  /// [adminId] - ID do admin que está criando (para rastreamento)
  /// [adminNome] - Nome do admin
  ///
  /// Uso recomendado: Executar uma vez na configuração inicial do sistema
  Future<void> criarTemplatesPadrao(String adminId, String adminNome) async {
    try {
      final templatesPadrao = [
        ChamadoTemplate(
          id: '',
          titulo: 'Problema de Rede/Internet',
          descricaoModelo: '''Internet não está funcionando.

Detalhes:
- Computador: [informar número/localização]
- O problema é só neste computador ou afeta outros?
- Quando começou?
- Alguma mensagem de erro aparece?''',
          setor: null,
          tipo: 'Chamado',
          prioridade: 3,
          tags: ['rede', 'internet', 'conectividade'],
          dataCriacao: DateTime.now(),
          criadoPorId: adminId,
          criadoPorNome: adminNome,
        ),
        ChamadoTemplate(
          id: '',
          titulo: 'Impressora Não Funciona',
          descricaoModelo: '''A impressora não está funcionando corretamente.

Detalhes:
- Modelo da impressora: [informar]
- Localização: [informar]
- O que está acontecendo? (não imprime, papel preso, manchas, etc.)
- Já tentou reiniciar?''',
          setor: null,
          tipo: 'Chamado',
          prioridade: 2,
          tags: ['impressora', 'hardware'],
          dataCriacao: DateTime.now(),
          criadoPorId: adminId,
          criadoPorNome: adminNome,
        ),
        ChamadoTemplate(
          id: '',
          titulo: 'Instalação de Software',
          descricaoModelo: '''Preciso instalar um software.

Detalhes:
- Nome do software: [informar]
- Versão (se souber): [informar]
- Para qual computador? [informar número/localização]
- Finalidade de uso: [informar]''',
          setor: null,
          tipo: 'Chamado',
          prioridade: 2,
          tags: ['software', 'instalacao'],
          dataCriacao: DateTime.now(),
          criadoPorId: adminId,
          criadoPorNome: adminNome,
        ),
        ChamadoTemplate(
          id: '',
          titulo: 'Problema com Email/Outlook',
          descricaoModelo: '''Estou com problema no email.

Detalhes:
- Qual o problema? (não abre, não envia, não recebe, etc.)
- Email afetado: [informar]
- Quando começou?
- Alguma mensagem de erro aparece?''',
          setor: null,
          tipo: 'Chamado',
          prioridade: 2,
          tags: ['email', 'outlook', 'comunicacao'],
          dataCriacao: DateTime.now(),
          criadoPorId: adminId,
          criadoPorNome: adminNome,
        ),
        ChamadoTemplate(
          id: '',
          titulo: 'Esqueci Minha Senha',
          descricaoModelo: '''Esqueci a senha e preciso resetar.

Detalhes:
- Senha de qual sistema? (Windows, email, sistema específico)
- Nome de usuário: [informar]
- Setor: [informar]''',
          setor: null,
          tipo: 'Chamado',
          prioridade: 3,
          tags: ['senha', 'acesso', 'seguranca'],
          dataCriacao: DateTime.now(),
          criadoPorId: adminId,
          criadoPorNome: adminNome,
        ),
        ChamadoTemplate(
          id: '',
          titulo: 'Computador Lento',
          descricaoModelo: '''O computador está muito lento.

Detalhes:
- Computador: [informar número/localização]
- Desde quando está lento?
- Fica lento sempre ou só em alguns momentos?
- Algum programa específico deixa lento?''',
          setor: null,
          tipo: 'Chamado',
          prioridade: 2,
          tags: ['performance', 'hardware', 'computador'],
          dataCriacao: DateTime.now(),
          criadoPorId: adminId,
          criadoPorNome: adminNome,
        ),
        ChamadoTemplate(
          id: '',
          titulo: 'Compra de Equipamento',
          descricaoModelo: '''Preciso solicitar a compra de um equipamento.

Detalhes:
- Item: [informar]
- Quantidade: [informar]
- Finalidade: [informar]
- Link/especificações (se tiver): [informar]
- Previsão de uso: [informar]''',
          setor: null,
          tipo: 'Solicitação',
          prioridade: 2,
          tags: ['compra', 'solicitacao', 'hardware'],
          dataCriacao: DateTime.now(),
          criadoPorId: adminId,
          criadoPorNome: adminNome,
        ),
      ];

      for (var template in templatesPadrao) {
        await criarTemplate(template);
      }

      print('✅ ${templatesPadrao.length} templates padrão criados');
    } catch (e) {
      print('❌ Erro ao criar templates padrão: $e');
      throw 'Erro ao criar templates padrão: $e';
    }
  }

  // ============ UTILIDADES ============

  /// Conta total de templates ativos no sistema
  ///
  /// Retorna quantidade de templates disponíveis para uso
  Future<int> contarTemplatesAtivos() async {
    try {
      final snapshot = await _firestore
          .collection('templates')
          .where('ativo', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erro ao contar templates: $e');
      return 0;
    }
  }

  /// Deleta permanentemente um template (hard delete)
  ///
  /// USE COM CUIDADO! Esta ação não pode ser desfeita.
  /// Prefira usar deletarTemplate() que faz soft delete.
  ///
  /// [templateId] - ID do template a ser deletado permanentemente
  Future<void> deletarTemplatePermanente(String templateId) async {
    try {
      await _firestore.collection('templates').doc(templateId).delete();
      print('✅ Template $templateId deletado permanentemente');
    } catch (e) {
      throw 'Erro ao deletar template permanentemente: $e';
    }
  }
}

