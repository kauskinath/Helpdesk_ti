import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:io';
import '../models/chamado_manutencao_model.dart';
import '../models/manutencao_enums.dart';
import 'package:helpdesk_ti/core/services/notification_service.dart';
import 'package:helpdesk_ti/core/utils/retry_helper.dart';

/// Serviço para gerenciar chamados de manutenção
class ManutencaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection principal
  static const String _chamadosCollection = 'chamados';

  // ========== LOGGING CONDICIONAL ==========
  void _log(String message) {
    if (kDebugMode) print(message);
  }

  // ========== NUMERAÇÃO AUTOMÁTICA ==========

  /// Gera o próximo número sequencial para chamados de manutenção
  /// Com retry automático para lidar com conflitos de transação
  Future<int> gerarProximoNumero() async {
    try {
      _log('🔢 Iniciando geração de número...');
      final contadorDoc = _firestore.collection('counters').doc('manutencao');

      // Usar transação com retry para garantir unicidade
      final novoNumero = await RetryHelper.withTransactionRetry<int>(
        transaction: () => _firestore.runTransaction<int>((transaction) async {
          final snapshot = await transaction.get(contadorDoc);
          _log('📊 Contador existe? ${snapshot.exists}');

          int numero;
          if (!snapshot.exists) {
            // Criar contador se não existir
            numero = 1;
            _log('✨ Criando contador inicial com número: $numero');
            transaction.set(contadorDoc, {'ultimoNumero': numero});
          } else {
            // Incrementar contador existente
            final ultimoNumero = snapshot.data()?['ultimoNumero'] ?? 0;
            numero = ultimoNumero + 1;
            _log('➕ Incrementando de $ultimoNumero para $numero');
            transaction.update(contadorDoc, {'ultimoNumero': numero});
          }

          return numero;
        }),
        maxAttempts: 3,
      );

      _log('✅ Número gerado com sucesso: $novoNumero');
      return novoNumero;
    } catch (e) {
      _log('❌ Erro ao gerar número via transação: $e');
      // Fallback: buscar o maior número existente na coleção e incrementar
      return await _gerarNumeroFallback();
    }
  }

  /// Fallback para gerar número quando a transação falha
  /// Busca o maior número existente na coleção chamados e incrementa
  Future<int> _gerarNumeroFallback() async {
    try {
      _log('⚠️ Usando fallback para gerar número...');

      // Buscar chamado com maior número
      final querySnapshot = await _firestore
          .collection(_chamadosCollection)
          .orderBy('numero', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _log('📊 Nenhum chamado existente, iniciando em 1');
        return 1;
      }

      final maiorNumero =
          querySnapshot.docs.first.data()['numero'] as int? ?? 0;
      final novoNumero = maiorNumero + 1;
      _log('📊 Maior número existente: $maiorNumero, novo número: $novoNumero');

      return novoNumero;
    } catch (e) {
      _log('❌ Erro no fallback: $e');
      // Último recurso: retornar número baseado em timestamp único
      // Isso só acontece se tanto a transação quanto a query falharem
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  // ========== CRIAR CHAMADO ==========

  /// Cria novo chamado de manutenção
  Future<String> criarChamado({
    required String titulo,
    required String descricao,
    required String criadorId,
    required String criadorNome,
    required TipoCriadorChamado criadorTipo,
    Orcamento? orcamento,
    bool autoAtribuicao = false,
  }) async {
    try {
      // Gerar número sequencial
      final numero = await gerarProximoNumero();
      _log('🎫 Chamado será criado com número: $numero');

      // Determinar se precisa validação
      // Admin Manutenção criando sem orçamento pode pular validação
      // Executor criando chamado SEM orçamento também não precisa validação (auto-atribui)
      final bool precisaValidacao =
          !((criadorTipo == TipoCriadorChamado.adminManutencao ||
                  (criadorTipo == TipoCriadorChamado.executor &&
                      autoAtribuicao)) &&
              orcamento == null);

      // Se executor está criando sem orçamento, já pré-atribuir a ele mesmo
      Execucao? execucaoInicial;
      StatusChamadoManutencao statusInicial = StatusChamadoManutencao.aberto;

      if (criadorTipo == TipoCriadorChamado.executor &&
          autoAtribuicao &&
          orcamento == null) {
        // Executor criando chamado sem orçamento: auto-atribuir
        execucaoInicial = Execucao(
          executorId: criadorId,
          executorNome: criadorNome,
          dataAtribuicao: DateTime.now(),
        );
        statusInicial = StatusChamadoManutencao.atribuidoExecutor;
        _log('🔧 Auto-atribuindo chamado ao executor: $criadorNome');
      }

      final chamado = ChamadoManutencao(
        id: '', // Será gerado pelo Firestore
        numero: numero,
        titulo: titulo,
        descricao: descricao,
        criadorId: criadorId,
        criadorNome: criadorNome,
        criadorTipo: criadorTipo,
        status: statusInicial,
        dataAbertura: DateTime.now(),
        orcamento: orcamento,
        precisaValidacao: precisaValidacao,
        autoAtribuicao: autoAtribuicao,
        execucao: execucaoInicial,
      );

      final docRef = await _firestore
          .collection(_chamadosCollection)
          .add(chamado.toMap());

      _log('✅ Chamado de manutenção criado: ${docRef.id}');

      // Notificar admin de manutenção sobre novo chamado
      try {
        _log('🔔 INICIANDO envio de notificação para admin_manutencao...');
        _log('   - Chamado ID: ${docRef.id}');
        _log('   - Título: $titulo');
        _log('   - Criador: $criadorNome');

        await _notificationService.sendNotificationToRoles(
          roles: ['admin_manutencao'],
          titulo: '🔧 Novo Chamado de Manutenção',
          corpo: '$criadorNome criou: "$titulo"',
          data: {
            'chamadoId': docRef.id,
            'tipo': 'MANUTENCAO',
            'acao': 'novo_chamado',
          },
        );
        _log('✅ Notificação enviada para admins de manutenção');
      } catch (e, stackTrace) {
        _log('⚠️ Erro ao enviar notificação: $e');
        _log('Stack trace: $stackTrace');
        // Não bloquear a criação do chamado por erro de notificação
      }

      return docRef.id;
    } catch (e) {
      _log('❌ Erro ao criar chamado de manutenção: $e');
      rethrow;
    }
  }

  // ========== VALIDAÇÃO ADMIN ==========

  /// Admin valida chamado
  Future<void> validarChamado({
    required String chamadoId,
    required String adminId,
    required String adminNome,
    required bool aprovado,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'validado': aprovado,
        'adminValidadorId': adminId,
        'adminValidadorNome': adminNome,
        'dataValidacao': FieldValue.serverTimestamp(),
      };

      if (aprovado) {
        // Se aprovado, verificar se tem orçamento
        final chamado = await getChamadoById(chamadoId);

        if (chamado.orcamento != null) {
          // TEM orçamento → Enviar para gerente aprovar
          updates['status'] =
              StatusChamadoManutencao.aguardandoAprovacaoGerente.value;
        } else {
          // NÃO TEM orçamento → Liberar para execução
          updates['status'] =
              StatusChamadoManutencao.liberadoParaExecucao.value;
        }
      } else {
        // Reprovado → Voltar para usuário
        updates['status'] = StatusChamadoManutencao.cancelado.value;
      }

      await _firestore
          .collection(_chamadosCollection)
          .doc(chamadoId)
          .update(updates);

      // Notificar criador sobre validação
      try {
        final chamado = await getChamadoById(chamadoId);
        await _notificationService.sendNotificationToUser(
          userId: chamado.criadorId,
          titulo: aprovado ? '✅ Chamado Validado' : '❌ Chamado Não Aprovado',
          corpo: aprovado
              ? 'Seu chamado "${chamado.titulo}" foi validado e está em andamento.'
              : 'Seu chamado "${chamado.titulo}" não foi aprovado.',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );
      } catch (e) {
        _log('⚠️ Erro ao enviar notificação de validação: $e');
      }

      _log('✅ Chamado validado: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao validar chamado: $e');
      rethrow;
    }
  }

  // ========== APROVAÇÃO GERENTE ==========

  /// Gerente aprova/rejeita orçamento
  Future<void> aprovarOrcamento({
    required String chamadoId,
    required String gerenteId,
    required String gerenteNome,
    required bool aprovado,
    String? motivoRejeicao,
  }) async {
    try {
      final aprovacao = AprovacaoGerente(
        gerenteId: gerenteId,
        gerenteNome: gerenteNome,
        aprovado: aprovado,
        dataAprovacao: DateTime.now(),
        motivoRejeicao: motivoRejeicao,
      );

      final Map<String, dynamic> updates = {
        'aprovacaoGerente': aprovacao.toMap(),
      };

      if (aprovado) {
        // Aprovado → Iniciar processo de compra
        updates['status'] = StatusChamadoManutencao.orcamentoAprovado.value;
        updates['compra'] = Compra(
          statusCompra: StatusCompra.naoIniciado,
        ).toMap();
      } else {
        // Rejeitado
        updates['status'] = StatusChamadoManutencao.orcamentoRejeitado.value;
      }

      await _firestore
          .collection(_chamadosCollection)
          .doc(chamadoId)
          .update(updates);

      // Notificar criador sobre decisão do gerente
      try {
        final chamado = await getChamadoById(chamadoId);
        await _notificationService.sendNotificationToUser(
          userId: chamado.criadorId,
          titulo: aprovado ? '✅ Orçamento Aprovado' : '❌ Orçamento Rejeitado',
          corpo: aprovado
              ? 'O orçamento do chamado "${chamado.titulo}" foi aprovado pelo gerente.'
              : 'O orçamento do chamado "${chamado.titulo}" foi rejeitado. Motivo: ${motivoRejeicao ?? "Não informado"}',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );
      } catch (e) {
        _log('⚠️ Erro ao enviar notificação de aprovação: $e');
      }

      _log('✅ Orçamento ${aprovado ? 'aprovado' : 'rejeitado'}: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao aprovar orçamento: $e');
      rethrow;
    }
  }

  // ========== ATUALIZAÇÃO DE ORÇAMENTO ==========

  /// Atualiza orçamento de um chamado (usado após upload de arquivo)
  Future<void> atualizarOrcamento(String chamadoId, Orcamento orcamento) async {
    try {
      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'orcamento': orcamento.toMap(),
      });
      _log('✅ Orçamento atualizado: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao atualizar orçamento: $e');
      rethrow;
    }
  }

  // ========== COMPRA DE MATERIAIS ==========

  /// Atualiza status da compra
  Future<void> atualizarStatusCompra({
    required String chamadoId,
    required StatusCompra novoStatus,
    DateTime? dataChegadaMateriais,
  }) async {
    try {
      final chamado = await getChamadoById(chamadoId);

      final compraAtualizada = Compra(
        statusCompra: novoStatus,
        dataChegadaMateriais:
            dataChegadaMateriais ?? chamado.compra?.dataChegadaMateriais,
        notasFiscaisUrls: chamado.compra?.notasFiscaisUrls ?? [],
      );

      final Map<String, dynamic> updates = {'compra': compraAtualizada.toMap()};

      // Se materiais chegaram, atualizar status principal
      if (novoStatus == StatusCompra.concluido &&
          dataChegadaMateriais != null) {
        updates['status'] = StatusChamadoManutencao.liberadoParaExecucao.value;
      } else if (novoStatus == StatusCompra.emAndamento) {
        updates['status'] = StatusChamadoManutencao.emCompra.value;
      }

      await _firestore
          .collection(_chamadosCollection)
          .doc(chamadoId)
          .update(updates);
      _log('✅ Status de compra atualizado: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao atualizar compra: $e');
      rethrow;
    }
  }

  // ========== ATRIBUIÇÃO DE EXECUTOR ==========

  /// Atribui chamado para executor
  Future<void> atribuirExecutor({
    required String chamadoId,
    required String executorId,
    required String executorNome,
  }) async {
    try {
      final execucao = Execucao(
        executorId: executorId,
        executorNome: executorNome,
        dataAtribuicao: DateTime.now(),
      );

      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'execucao': execucao.toMap(),
        'status': StatusChamadoManutencao.atribuidoExecutor.value,
      });

      // Notificar executor sobre atribuição
      try {
        final chamado = await getChamadoById(chamadoId);
        await _notificationService.sendNotificationToUser(
          userId: executorId,
          titulo: '🔧 Novo Trabalho Atribuído',
          corpo:
              'Você foi atribuído ao trabalho: "${chamado.titulo}". Acesse para iniciar.',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );
      } catch (e) {
        _log('⚠️ Erro ao enviar notificação de atribuição: $e');
      }

      _log('✅ Executor atribuído: $chamadoId → $executorNome');
    } catch (e) {
      _log('❌ Erro ao atribuir executor: $e');
      rethrow;
    }
  }

  // ========== EXECUÇÃO ==========

  /// Executor inicia execução
  Future<void> iniciarExecucao(String chamadoId) async {
    try {
      final chamado = await getChamadoById(chamadoId);

      final execucaoAtualizada = Execucao(
        executorId: chamado.execucao!.executorId,
        executorNome: chamado.execucao!.executorNome,
        dataAtribuicao: chamado.execucao!.dataAtribuicao,
        dataInicio: DateTime.now(),
      );

      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'execucao': execucaoAtualizada.toMap(),
        'status': StatusChamadoManutencao.emExecucao.value,
      });

      // Notificar criador e admins sobre início da execução
      try {
        // Notificar criador
        await _notificationService.sendNotificationToUser(
          userId: chamado.criadorId,
          titulo: '🔧 Trabalho Iniciado',
          corpo:
              '${chamado.execucao!.executorNome} iniciou o trabalho "${chamado.titulo}"',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );

        // Notificar admins de manutenção
        await _notificationService.sendNotificationToRoles(
          roles: ['admin_manutencao'],
          titulo: '🔧 Execução Iniciada',
          corpo:
              '${chamado.execucao!.executorNome} iniciou: "${chamado.titulo}"',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );
      } catch (e) {
        _log('⚠️ Erro ao enviar notificação de início: $e');
      }

      _log('✅ Execução iniciada: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao iniciar execução: $e');
      rethrow;
    }
  }

  /// Pausar execução do trabalho
  Future<void> pausarExecucao(String chamadoId) async {
    try {
      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'status': StatusChamadoManutencao.atribuidoExecutor.value,
      });

      _log('✅ Execução pausada: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao pausar execução: $e');
      rethrow;
    }
  }

  /// Executor finaliza chamado (COM foto obrigatória)
  Future<void> finalizarChamado({
    required String chamadoId,
    required File fotoComprovante,
  }) async {
    try {
      // 1. Upload da foto
      final fotoUrl = await _uploadFotoComprovante(chamadoId, fotoComprovante);

      // 2. Atualizar chamado
      final chamado = await getChamadoById(chamadoId);

      final execucaoAtualizada = Execucao(
        executorId: chamado.execucao!.executorId,
        executorNome: chamado.execucao!.executorNome,
        dataAtribuicao: chamado.execucao!.dataAtribuicao,
        dataInicio: chamado.execucao!.dataInicio,
        dataFim: DateTime.now(),
        fotoComprovanteUrl: fotoUrl,
      );

      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'execucao': execucaoAtualizada.toMap(),
        'status': StatusChamadoManutencao.finalizado.value,
        'dataFinalizacao': FieldValue.serverTimestamp(),
      });

      // Notificar criador e admins sobre finalização
      try {
        // Notificar criador
        await _notificationService.sendNotificationToUser(
          userId: chamado.criadorId,
          titulo: '✅ Trabalho Concluído',
          corpo:
              '${chamado.execucao!.executorNome} finalizou: "${chamado.titulo}"',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );

        // Notificar admins de manutenção
        await _notificationService.sendNotificationToRoles(
          roles: ['admin_manutencao'],
          titulo: '✅ Chamado Finalizado',
          corpo:
              '${chamado.execucao!.executorNome} finalizou: "${chamado.titulo}"',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );
      } catch (e) {
        _log('⚠️ Erro ao enviar notificação de finalização: $e');
      }

      _log('✅ Chamado finalizado: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao finalizar chamado: $e');
      rethrow;
    }
  }

  /// Executor recusa chamado (COM motivo obrigatório)
  Future<void> recusarChamado({
    required String chamadoId,
    required String executorId,
    required String executorNome,
    required String motivo,
  }) async {
    try {
      if (motivo.trim().isEmpty) {
        throw 'Motivo da recusa é obrigatório';
      }

      final recusa = Recusa(
        executorId: executorId,
        executorNome: executorNome,
        dataRecusa: DateTime.now(),
        motivo: motivo,
      );

      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'recusa': recusa.toMap(),
        'status': StatusChamadoManutencao.recusadoExecutor.value,
        'execucao': null, // Limpar atribuição
      });

      // Notificar admins de manutenção sobre recusa
      try {
        final chamado = await getChamadoById(chamadoId);
        await _notificationService.sendNotificationToRoles(
          roles: ['admin_manutencao'],
          titulo: '⚠️ Trabalho Recusado',
          corpo:
              '$executorNome recusou o trabalho "${chamado.titulo}". Motivo: $motivo',
          data: {'chamadoId': chamadoId, 'tipo': 'MANUTENCAO'},
        );
      } catch (e) {
        _log('⚠️ Erro ao enviar notificação de recusa: $e');
      }

      _log('✅ Chamado recusado: $chamadoId');
    } catch (e) {
      _log('❌ Erro ao recusar chamado: $e');
      rethrow;
    }
  }

  // ========== UPLOAD DE ARQUIVOS ==========

  /// Upload de orçamento (PDF/DOCX)
  Future<String> uploadOrcamento(String chamadoId, File arquivo) async {
    try {
      final String fileName =
          'orcamento_${DateTime.now().millisecondsSinceEpoch}${_getFileExtension(arquivo.path)}';
      final ref = _storage.ref().child(
        'manutencao/$chamadoId/orcamentos/$fileName',
      );

      await ref.putFile(arquivo);
      final url = await ref.getDownloadURL();

      _log('✅ Orçamento enviado: $url');
      return url;
    } catch (e) {
      _log('❌ Erro ao enviar orçamento: $e');
      rethrow;
    }
  }

  /// Upload de foto comprovante
  Future<String> _uploadFotoComprovante(String chamadoId, File foto) async {
    try {
      final String fileName =
          'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('manutencao/$chamadoId/fotos/$fileName');

      await ref.putFile(foto);
      final url = await ref.getDownloadURL();

      _log('✅ Foto enviada: $url');
      return url;
    } catch (e) {
      _log('❌ Erro ao enviar foto: $e');
      rethrow;
    }
  }

  /// Upload de múltiplas fotos
  Future<List<String>> uploadFotos(String chamadoId, List<File> fotos) async {
    try {
      final List<String> urls = [];

      for (int i = 0; i < fotos.length; i++) {
        final String fileName =
            'foto_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child(
          'manutencao/$chamadoId/fotos/$fileName',
        );

        await ref.putFile(fotos[i]);
        final url = await ref.getDownloadURL();
        urls.add(url);

        _log('✅ Foto ${i + 1}/${fotos.length} enviada: $url');
      }

      _log('✅ Total de ${urls.length} fotos enviadas');
      return urls;
    } catch (e) {
      _log('❌ Erro ao enviar fotos: $e');
      rethrow;
    }
  }

  /// Atualizar fotos do chamado
  Future<void> atualizarFotos(String chamadoId, List<String> fotosUrls) async {
    try {
      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'fotosUrls': fotosUrls,
      });
      _log('✅ Fotos atualizadas no chamado $chamadoId');
    } catch (e) {
      _log('❌ Erro ao atualizar fotos: $e');
      rethrow;
    }
  }

  String _getFileExtension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }

  // ========== QUERIES ==========

  /// Buscar chamado por ID
  Future<ChamadoManutencao> getChamadoById(String chamadoId) async {
    try {
      final doc = await _firestore
          .collection(_chamadosCollection)
          .doc(chamadoId)
          .get();

      if (!doc.exists) {
        throw 'Chamado não encontrado';
      }

      return ChamadoManutencao.fromMap(doc.data()!, doc.id);
    } catch (e) {
      _log('❌ Erro ao buscar chamado: $e');
      rethrow;
    }
  }

  /// Stream de chamados para Admin Manutenção
  Stream<List<ChamadoManutencao>> getChamadosParaAdminManutencao() {
    return _firestore
        .collection(_chamadosCollection)
        .where('tipo', isEqualTo: 'MANUTENCAO')
        .orderBy('dataAbertura', descending: true)
        .snapshots()
        .map((snapshot) {
          _log('🔍 DEBUG: Total de docs retornados: ${snapshot.docs.length}');
          final chamados = snapshot.docs.map((doc) {
            _log('📄 DEBUG: Doc ${doc.id} - tipo: ${doc.data()['tipo']}');
            return ChamadoManutencao.fromMap(doc.data(), doc.id);
          }).toList();
          _log('✅ DEBUG: Total de chamados processados: ${chamados.length}');
          return chamados;
        });
  }

  /// Stream de chamados para Gerente (apenas com orçamento pendente)
  Stream<List<ChamadoManutencao>> getChamadosParaGerente() {
    return _firestore
        .collection(_chamadosCollection)
        .where('tipo', isEqualTo: 'MANUTENCAO')
        .where(
          'status',
          isEqualTo: StatusChamadoManutencao.aguardandoAprovacaoGerente.value,
        )
        .orderBy('dataAbertura', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChamadoManutencao.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Stream de chamados para Executor (atribuídos a ele OU criados por ele)
  /// Isso permite que o executor veja os chamados que criou e ainda estão
  /// em processo de validação/aprovação
  Stream<List<ChamadoManutencao>> getChamadosParaExecutor(String executorId) {
    // Stream de chamados atribuídos ao executor
    final atribuidosStream = _firestore
        .collection(_chamadosCollection)
        .where('tipo', isEqualTo: 'MANUTENCAO')
        .where('execucao.executorId', isEqualTo: executorId)
        .snapshots();

    // Combinar com chamados criados pelo executor
    return atribuidosStream.asyncMap((atribuidosSnapshot) async {
      final criadosSnapshot = await _firestore
          .collection(_chamadosCollection)
          .where('tipo', isEqualTo: 'MANUTENCAO')
          .where('criadorId', isEqualTo: executorId)
          .where('criadorTipo', isEqualTo: 'executor')
          .get();

      final Map<String, ChamadoManutencao> chamadosMap = {};

      // Adicionar chamados atribuídos
      for (final doc in atribuidosSnapshot.docs) {
        chamadosMap[doc.id] = ChamadoManutencao.fromMap(doc.data(), doc.id);
      }

      // Adicionar chamados criados (sem duplicar)
      for (final doc in criadosSnapshot.docs) {
        if (!chamadosMap.containsKey(doc.id)) {
          chamadosMap[doc.id] = ChamadoManutencao.fromMap(doc.data(), doc.id);
        }
      }

      // Ordenar por data de abertura (mais recentes primeiro)
      final chamados = chamadosMap.values.toList();
      chamados.sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));

      return chamados;
    });
  }

  /// Stream de chamados criados por um usuário
  Stream<List<ChamadoManutencao>> getChamadosPorCriador(String criadorId) {
    return _firestore
        .collection(_chamadosCollection)
        .where('tipo', isEqualTo: 'MANUTENCAO')
        .where('criadorId', isEqualTo: criadorId)
        .orderBy('dataAbertura', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChamadoManutencao.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Estatísticas para Admin Manutenção
  Future<Map<String, dynamic>> getStatsAdmin() async {
    try {
      final snapshot = await _firestore
          .collection(_chamadosCollection)
          .where('tipo', isEqualTo: 'MANUTENCAO')
          .get();

      final chamados = snapshot.docs
          .map((doc) => ChamadoManutencao.fromMap(doc.data(), doc.id))
          .toList();

      final total = chamados.length;
      final abertos = chamados
          .where(
            (c) =>
                c.status == StatusChamadoManutencao.aberto ||
                c.status == StatusChamadoManutencao.emValidacaoAdmin,
          )
          .length;
      final emAndamento = chamados
          .where(
            (c) =>
                c.status == StatusChamadoManutencao.emExecucao ||
                c.status == StatusChamadoManutencao.atribuidoExecutor ||
                c.status ==
                    StatusChamadoManutencao.aguardandoAprovacaoGerente ||
                c.status == StatusChamadoManutencao.emCompra ||
                c.status == StatusChamadoManutencao.aguardandoMateriais,
          )
          .length;
      final fechados = chamados
          .where((c) => c.status == StatusChamadoManutencao.finalizado)
          .length;

      // Mapa de status
      final Map<String, int> statusMap = {};
      for (final chamado in chamados) {
        final label = chamado.status.label;
        statusMap[label] = (statusMap[label] ?? 0) + 1;
      }

      return {
        'total': total,
        'abertos': abertos,
        'emAndamento': emAndamento,
        'fechados': fechados,
        'statusMap': statusMap,
      };
    } catch (e) {
      _log('❌ Erro ao buscar estatísticas: $e');
      return {
        'total': 0,
        'abertos': 0,
        'emAndamento': 0,
        'fechados': 0,
        'statusMap': <String, int>{},
      };
    }
  }

  // ========== EXCLUSÃO COMPLETA ==========

  /// Deleta completamente um chamado de manutenção e todos os dados relacionados
  ///
  /// Remove:
  /// - Documento do chamado no Firestore
  /// - Subcoleção de comentários
  /// - Todos os arquivos anexados no Firebase Storage
  ///
  /// [chamadoId] - ID do chamado a ser deletado
  ///
  /// Throws: Exception se houver erro na exclusão
  Future<void> deletarChamado(String chamadoId) async {
    try {
      _log('🗑️ Iniciando exclusão do chamado: $chamadoId');

      // 1. Buscar chamado para verificar se existe
      final chamadoDoc = await _firestore
          .collection(_chamadosCollection)
          .doc(chamadoId)
          .get();

      if (!chamadoDoc.exists) {
        throw 'Chamado não encontrado';
      }

      // 2. Deletar subcoleção de comentários
      try {
        _log('🗑️ Deletando comentários...');
        final comentariosSnapshot = await _firestore
            .collection(_chamadosCollection)
            .doc(chamadoId)
            .collection('comentarios')
            .get();

        // Deletar em batch
        final batch = _firestore.batch();
        for (final doc in comentariosSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        _log('✅ ${comentariosSnapshot.docs.length} comentários deletados');
      } catch (e) {
        _log('⚠️ Erro ao deletar comentários: $e');
      }

      // 3. Deletar arquivos do Storage
      try {
        _log('🗑️ Deletando arquivos do Storage...');

        // Deletar pasta de orçamento
        await _deletarPastaStorage('manutencao/$chamadoId/orcamento');

        // Deletar pasta de compra
        await _deletarPastaStorage('manutencao/$chamadoId/compra');

        // Deletar pasta de execução
        await _deletarPastaStorage('manutencao/$chamadoId/execucao');

        _log('✅ Arquivos do Storage deletados');
      } catch (e) {
        _log('⚠️ Erro ao deletar arquivos do Storage: $e');
      }

      // 4. Deletar documento do chamado
      await _firestore.collection(_chamadosCollection).doc(chamadoId).delete();

      _log('✅ Chamado $chamadoId deletado completamente');
    } catch (e) {
      _log('❌ Erro ao deletar chamado: $e');
      throw 'Erro ao deletar chamado: $e';
    }
  }

  /// Helper para deletar uma pasta inteira do Storage
  Future<void> _deletarPastaStorage(String caminho) async {
    try {
      final listResult = await _storage.ref(caminho).listAll();

      // Deletar todos os arquivos
      for (final item in listResult.items) {
        await item.delete();
        _log('   🗑️ Arquivo deletado: ${item.name}');
      }

      // Recursivamente deletar subpastas
      for (final prefix in listResult.prefixes) {
        await _deletarPastaStorage(prefix.fullPath);
      }
    } catch (e) {
      // Ignora erro se pasta não existir
      if (!e.toString().contains('object-not-found')) {
        _log('   ⚠️ Erro ao deletar pasta $caminho: $e');
      }
    }
  }

  // ========== AVALIAÇÕES ==========

  /// Cria uma nova avaliação para um chamado de manutenção
  Future<void> criarAvaliacaoManutencao({
    required String avaliacaoId,
    required String chamadoId,
    required String usuarioId,
    required String usuarioNome,
    required int nota,
    String? comentario,
    String? executorId,
    String? executorNome,
  }) async {
    try {
      _log('⭐ Criando avaliação para chamado $chamadoId...');

      // Salvar avaliação na coleção dedicada
      await _firestore
          .collection('avaliacoes_manutencao')
          .doc(avaliacaoId)
          .set({
            'chamadoId': chamadoId,
            'usuarioId': usuarioId,
            'usuarioNome': usuarioNome,
            'nota': nota,
            'comentario': comentario,
            'dataAvaliacao': FieldValue.serverTimestamp(),
            'executorId': executorId,
            'executorNome': executorNome,
            'tipo': 'manutencao',
          });

      // Atualizar chamado para marcar que foi avaliado
      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'avaliadoEm': FieldValue.serverTimestamp(),
        'avaliacaoId': avaliacaoId,
      });

      _log('✅ Avaliação $avaliacaoId criada com sucesso');
    } catch (e) {
      _log('❌ Erro ao criar avaliação: $e');
      throw 'Erro ao criar avaliação: $e';
    }
  }

  /// Busca a avaliação de um chamado de manutenção
  Future<Map<String, dynamic>?> getAvaliacaoManutencao(String chamadoId) async {
    try {
      final snapshot = await _firestore
          .collection('avaliacoes_manutencao')
          .where('chamadoId', isEqualTo: chamadoId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    } catch (e) {
      _log('❌ Erro ao buscar avaliação: $e');
      return null;
    }
  }
}
