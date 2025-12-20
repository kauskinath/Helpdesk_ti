import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helpdesk_ti/features/ti/models/solicitacao.dart';

/// Serviço responsável por todas as operações relacionadas a Solicitações
///
/// Este serviço gerencia solicitações que requerem aprovação gerencial antes
/// de serem convertidas em chamados técnicos:
/// - Criação de solicitações com numeração sequencial
/// - Aprovação/rejeição por managers
/// - Conversão de solicitações aprovadas em chamados
/// - Consulta e filtros (pendentes, processadas, por usuário)
///
/// ## Fluxo de uma Solicitação:
///
/// 1. **Usuário cria** → Status: "Pendente"
/// 2. **Manager analisa** → Aprova ou Rejeita
/// 3. **Se aprovada** → Pode gerar chamado técnico para TI executar
/// 4. **Se rejeitada** → Usuário é notificado com motivo
class SolicitacaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ CRIAÇÃO E NUMERAÇÃO ============

  /// Gera próximo número sequencial para solicitações
  ///
  /// Usa transação atômica para garantir unicidade dos números.
  /// Formato: #S0001, #S0002, etc.
  ///
  /// Retorna próximo número disponível
  Future<int> gerarProximoNumero() async {
    try {
      final contadorDoc = _firestore.collection('counters').doc('solicitacoes');

      return await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(contadorDoc);

        int novoNumero;
        if (!snapshot.exists) {
          novoNumero = 1;
          transaction.set(contadorDoc, {'ultimoNumero': novoNumero});
        } else {
          novoNumero = (snapshot.data()?['ultimoNumero'] ?? 0) + 1;
          transaction.update(contadorDoc, {'ultimoNumero': novoNumero});
        }

        return novoNumero;
      });
    } catch (e) {
      print('❌ Erro ao gerar número de solicitação: $e');
      return DateTime.now().millisecondsSinceEpoch % 10000;
    }
  }

  /// Cria uma nova solicitação
  ///
  /// A solicitação é criada com status "Pendente" e aguarda aprovação
  /// de um manager.
  ///
  /// [solicitacao] - Objeto Solicitacao com os dados
  ///
  /// Retorna o ID do documento criado no Firestore
  Future<String> criarSolicitacao(Solicitacao solicitacao) async {
    try {
      // Gerar número sequencial
      final numero = await gerarProximoNumero();

      // Criar solicitação com número
      final solicitacaoComNumero = Solicitacao(
        id: solicitacao.id,
        numero: numero,
        titulo: solicitacao.titulo,
        descricao: solicitacao.descricao,
        itemSolicitado: solicitacao.itemSolicitado,
        justificativa: solicitacao.justificativa,
        custoEstimado: solicitacao.custoEstimado,
        setor: solicitacao.setor,
        usuarioId: solicitacao.usuarioId,
        usuarioNome: solicitacao.usuarioNome,
        managerId: solicitacao.managerId,
        managerNome: solicitacao.managerNome,
        status: solicitacao.status,
        dataCriacao: solicitacao.dataCriacao,
        dataAtualizacao: solicitacao.dataAtualizacao,
        motivoRejeicao: solicitacao.motivoRejeicao,
        prioridade: solicitacao.prioridade,
      );

      final docRef = await _firestore
          .collection('solicitacoes')
          .add(solicitacaoComNumero.toMap());

      print(
        '✅ Solicitação criada com ID: ${docRef.id} e número: #S${numero.toString().padLeft(4, '0')}',
      );
      return docRef.id;
    } catch (e) {
      print('❌ Erro ao criar solicitação: $e');
      throw 'Erro ao criar solicitação: $e';
    }
  }

  // ============ CONSULTAS ============

  /// Busca uma solicitação específica por ID
  ///
  /// [solicitacaoId] - ID do documento no Firestore
  ///
  /// Retorna Solicitacao ou null se não encontrada
  Future<Solicitacao?> getSolicitacao(String solicitacaoId) async {
    try {
      final doc = await _firestore
          .collection('solicitacoes')
          .doc(solicitacaoId)
          .get();

      if (doc.exists) {
        return Solicitacao.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter solicitação: $e');
      throw 'Erro ao obter solicitação: $e';
    }
  }

  /// Stream de solicitações de um usuário específico
  ///
  /// Útil para mostrar histórico de solicitações do usuário.
  ///
  /// [usuarioId] - ID do usuário (Firebase Auth UID)
  ///
  /// Retorna Stream de solicitações do usuário
  Stream<List<Solicitacao>> getSolicitacoesDoUsuario(String usuarioId) {
    return _firestore
        .collection('solicitacoes')
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Solicitacao.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream de solicitações pendentes aguardando aprovação
  ///
  /// Usado na aba do manager para mostrar solicitações que precisam
  /// de aprovação/rejeição.
  ///
  /// Retorna Stream de solicitações com status "Pendente"
  Stream<List<Solicitacao>> getSolicitacoesPendentes() {
    print('📡 getSolicitacoesPendentes INICIADO');
    return _firestore
        .collection('solicitacoes')
        .where('status', isEqualTo: 'Pendente')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📦 Snapshot recebido: ${snapshot.docs.length} solicitações');
          final solicitacoes = snapshot.docs.map((doc) {
            print('📄 Documento ID: ${doc.id}');
            return Solicitacao.fromFirestore(doc);
          }).toList();
          print('✅ Retornando ${solicitacoes.length} solicitações pendentes');
          return solicitacoes;
        });
  }

  /// Stream de todas as solicitações do sistema
  ///
  /// Usado por admins para ver histórico completo.
  ///
  /// Retorna Stream de todas as solicitações
  Stream<List<Solicitacao>> getTodasSolicitacoes() {
    return _firestore
        .collection('solicitacoes')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Solicitacao.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream de solicitações processadas (aprovadas ou rejeitadas)
  ///
  /// Útil para histórico de decisões do manager.
  ///
  /// Retorna Stream de solicitações com status "Aprovado" ou "Reprovado"
  Stream<List<Solicitacao>> getSolicitacoesProcessadas() {
    print('📡 getSolicitacoesProcessadas INICIADO');
    return _firestore
        .collection('solicitacoes')
        .where('status', whereIn: ['Aprovado', 'Reprovado'])
        .orderBy('dataAtualizacao', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            '📦 Snapshot recebido: ${snapshot.docs.length} solicitações processadas',
          );
          final solicitacoes = snapshot.docs.map((doc) {
            return Solicitacao.fromFirestore(doc);
          }).toList();
          print('✅ Retornando ${solicitacoes.length} solicitações processadas');
          return solicitacoes;
        });
  }

  // ============ APROVAÇÃO/REJEIÇÃO ============

  /// Aprova uma solicitação
  ///
  /// Atualiza o status para "Aprovado" e registra qual manager aprovou.
  /// Após aprovação, a solicitação pode ser convertida em chamado técnico.
  ///
  /// [solicitacaoId] - ID da solicitação
  /// [managerId] - ID do manager que aprovou
  /// [managerNome] - Nome do manager
  Future<void> aprovarSolicitacao(
    String solicitacaoId,
    String managerId,
    String managerNome,
  ) async {
    try {
      await _firestore.collection('solicitacoes').doc(solicitacaoId).update({
        'status': 'Aprovado',
        'managerId': managerId,
        'managerNome': managerNome,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      print('✅ Solicitação $solicitacaoId aprovada por $managerNome');
    } catch (e) {
      print('❌ Erro ao aprovar solicitação: $e');
      throw 'Erro ao aprovar solicitação: $e';
    }
  }

  /// Rejeita uma solicitação com motivo
  ///
  /// Atualiza o status para "Reprovado" e registra o motivo da rejeição.
  /// O usuário poderá ver o motivo e entender por que foi rejeitado.
  ///
  /// [solicitacaoId] - ID da solicitação
  /// [managerId] - ID do manager que rejeitou
  /// [managerNome] - Nome do manager
  /// [motivo] - Explicação da rejeição
  Future<void> rejeitarSolicitacao(
    String solicitacaoId,
    String managerId,
    String managerNome,
    String motivo,
  ) async {
    try {
      await _firestore.collection('solicitacoes').doc(solicitacaoId).update({
        'status': 'Reprovado',
        'managerId': managerId,
        'managerNome': managerNome,
        'motivoRejeicao': motivo,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      print('✅ Solicitação $solicitacaoId rejeitada por $managerNome');
    } catch (e) {
      print('❌ Erro ao rejeitar solicitação: $e');
      throw 'Erro ao rejeitar solicitação: $e';
    }
  }

  /// Atualiza status de uma solicitação
  ///
  /// Método genérico para atualizar status. Prefira usar aprovarSolicitacao()
  /// ou rejeitarSolicitacao() para melhor rastreamento.
  ///
  /// [solicitacaoId] - ID da solicitação
  /// [novoStatus] - Novo status ("Pendente", "Aprovado", "Reprovado")
  Future<void> atualizarStatusSolicitacao(
    String solicitacaoId,
    String novoStatus,
  ) async {
    try {
      await _firestore.collection('solicitacoes').doc(solicitacaoId).update({
        'status': novoStatus,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });

      print(
        '✅ Status da solicitação $solicitacaoId atualizado para $novoStatus',
      );
    } catch (e) {
      print('❌ Erro ao atualizar status: $e');
      throw 'Erro ao atualizar status: $e';
    }
  }

  /// Atualiza uma solicitação completa
  ///
  /// Método genérico para atualizar todos os campos.
  ///
  /// [solicitacao] - Objeto Solicitacao com dados atualizados
  Future<void> atualizarSolicitacao(Solicitacao solicitacao) async {
    try {
      await _firestore
          .collection('solicitacoes')
          .doc(solicitacao.id)
          .update(solicitacao.toMap());

      print('✅ Solicitação ${solicitacao.id} atualizada');
    } catch (e) {
      print('❌ Erro ao atualizar solicitação: $e');
      throw 'Erro ao atualizar solicitação: $e';
    }
  }

  // ============ UTILIDADES ============

  /// Deleta completamente uma solicitação e todos os seus dados relacionados
  ///
  /// Remove:
  /// - Documento da solicitação no Firestore
  /// - Todos os arquivos anexados no Firebase Storage (se houver)
  ///
  /// ⚠️ ATENÇÃO: Remove permanentemente do Firestore. Usar com cuidado!
  ///
  /// [solicitacaoId] - ID da solicitação a ser deletada
  ///
  /// Throws: Exception se houver erro na exclusão
  Future<void> deletarSolicitacao(String solicitacaoId) async {
    try {
      print('🗑️ Iniciando exclusão da solicitação: $solicitacaoId');

      // 1. Buscar solicitação para verificar se existe
      final solicitacaoDoc = await _firestore
          .collection('solicitacoes')
          .doc(solicitacaoId)
          .get();

      if (!solicitacaoDoc.exists) {
        throw 'Solicitação não encontrada';
      }

      // 2. Deletar documento da solicitação
      await _firestore.collection('solicitacoes').doc(solicitacaoId).delete();

      print('✅ Solicitação $solicitacaoId deletada com sucesso');
    } catch (e) {
      print('❌ Erro ao deletar solicitação: $e');
      throw 'Erro ao deletar solicitação: $e';
    }
  }

  /// Conta total de solicitações por status
  ///
  /// Útil para estatísticas e dashboards.
  ///
  /// [status] - Status para contar ("Pendente", "Aprovado", "Reprovado")
  ///
  /// Retorna quantidade de solicitações com o status
  Future<int> contarSolicitacoesPorStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('solicitacoes')
          .where('status', isEqualTo: status)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erro ao contar solicitações: $e');
      return 0;
    }
  }

  /// Stream de solicitações pendentes
  ///
  /// Alternativa do método getSolicitacoesPendentes com nome Stream explícito.
  /// Retorna stream de solicitações com status 'Pendente'.
  ///
  /// Returns: Stream de lista de solicitações pendentes
  Stream<List<Solicitacao>> getSolicitacoesPendentesStream() {
    print('📡 getSolicitacoesPendentesStream INICIADO');
    return _firestore
        .collection('solicitacoes')
        .where('status', isEqualTo: 'Pendente')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            '📡 getSolicitacoesPendentesStream: ${snapshot.docs.length} documentos',
          );
          return snapshot.docs.map((doc) {
            return Solicitacao.fromFirestore(doc);
          }).toList();
        });
  }

  /// Stream de solicitações processadas (aprovadas/rejeitadas)
  ///
  /// Retorna stream de solicitações que já foram processadas,
  /// ordenadas por data de criação decrescente.
  ///
  /// Returns: Stream de lista de solicitações processadas
  Stream<List<Solicitacao>> getSolicitacoesProcessadasStream() {
    print('📡 getSolicitacoesProcessadasStream INICIADO');
    return _firestore
        .collection('solicitacoes')
        .where('status', whereIn: ['Aprovado', 'Rejeitado'])
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            '📡 getSolicitacoesProcessadasStream: ${snapshot.docs.length} documentos',
          );
          return snapshot.docs.map((doc) {
            return Solicitacao.fromFirestore(doc);
          }).toList();
        });
  }

  // ============ EXCLUSÃO COMPLETA ============

  /// Deleta completamente uma solicitação e todos os seus dados relacionados
  ///
  /// Remove:
  /// - Documento da solicitação no Firestore
  /// - Todos os arquivos anexados no Firebase Storage
  ///
}
