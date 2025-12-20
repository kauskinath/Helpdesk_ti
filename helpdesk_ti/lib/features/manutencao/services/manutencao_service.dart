import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/chamado_manutencao_model.dart';
import '../models/manutencao_enums.dart';
import 'package:helpdesk_ti/core/services/notification_service.dart';

/// Serviço para gerenciar chamados de manutenção
class ManutencaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection principal
  static const String _chamadosCollection = 'chamados';

  // ========== NUMERAÇÃO AUTOMÁTICA ==========

  /// Gera o próximo número sequencial para chamados de manutenção
  Future<int> gerarProximoNumero() async {
    try {
      print('🔢 Iniciando geração de número...');
      final contadorDoc = _firestore.collection('counters').doc('manutencao');

      // Usar transação para garantir unicidade
      final novoNumero = await _firestore.runTransaction<int>((
        transaction,
      ) async {
        final snapshot = await transaction.get(contadorDoc);
        print('📊 Contador existe? ${snapshot.exists}');

        int numero;
        if (!snapshot.exists) {
          // Criar contador se não existir
          numero = 1;
          print('✨ Criando contador inicial com número: $numero');
          transaction.set(contadorDoc, {'ultimoNumero': numero});
        } else {
          // Incrementar contador existente
          final ultimoNumero = snapshot.data()?['ultimoNumero'] ?? 0;
          numero = ultimoNumero + 1;
          print('➕ Incrementando de $ultimoNumero para $numero');
          transaction.update(contadorDoc, {'ultimoNumero': numero});
        }

        return numero;
      });

      print('✅ Número gerado com sucesso: $novoNumero');
      return novoNumero;
    } catch (e) {
      print('❌ Erro ao gerar número: $e');
      // Fallback: usar timestamp
      final fallback = DateTime.now().millisecondsSinceEpoch % 10000;
      print('⚠️ Usando fallback: $fallback');
      return fallback;
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
      print('🎫 Chamado será criado com número: $numero');

      // Determinar se precisa validação
      // Admin Manutenção criando sem orçamento pode pular validação
      final bool precisaValidacao =
          !(criadorTipo == TipoCriadorChamado.adminManutencao &&
              orcamento == null);

      final chamado = ChamadoManutencao(
        id: '', // Será gerado pelo Firestore
        numero: numero,
        titulo: titulo,
        descricao: descricao,
        criadorId: criadorId,
        criadorNome: criadorNome,
        criadorTipo: criadorTipo,
        status: StatusChamadoManutencao.aberto,
        dataAbertura: DateTime.now(),
        orcamento: orcamento,
        precisaValidacao: precisaValidacao,
        autoAtribuicao: autoAtribuicao,
      );

      final docRef = await _firestore
          .collection(_chamadosCollection)
          .add(chamado.toMap());

      print('✅ Chamado de manutenção criado: ${docRef.id}');

      // Notificar admin de manutenção sobre novo chamado
      try {
        print('🔔 INICIANDO envio de notificação para admin_manutencao...');
        print('   - Chamado ID: ${docRef.id}');
        print('   - Título: $titulo');
        print('   - Criador: $criadorNome');

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
        print('✅ Notificação enviada para admins de manutenção');
      } catch (e, stackTrace) {
        print('⚠️ Erro ao enviar notificação: $e');
        print('Stack trace: $stackTrace');
        // Não bloquear a criação do chamado por erro de notificação
      }

      return docRef.id;
    } catch (e) {
      print('❌ Erro ao criar chamado de manutenção: $e');
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
        print('⚠️ Erro ao enviar notificação de validação: $e');
      }

      print('✅ Chamado validado: $chamadoId');
    } catch (e) {
      print('❌ Erro ao validar chamado: $e');
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
        print('⚠️ Erro ao enviar notificação de aprovação: $e');
      }

      print('✅ Orçamento ${aprovado ? 'aprovado' : 'rejeitado'}: $chamadoId');
    } catch (e) {
      print('❌ Erro ao aprovar orçamento: $e');
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
      print('✅ Orçamento atualizado: $chamadoId');
    } catch (e) {
      print('❌ Erro ao atualizar orçamento: $e');
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
      print('✅ Status de compra atualizado: $chamadoId');
    } catch (e) {
      print('❌ Erro ao atualizar compra: $e');
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
        print('⚠️ Erro ao enviar notificação de atribuição: $e');
      }

      print('✅ Executor atribuído: $chamadoId → $executorNome');
    } catch (e) {
      print('❌ Erro ao atribuir executor: $e');
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
        print('⚠️ Erro ao enviar notificação de início: $e');
      }

      print('✅ Execução iniciada: $chamadoId');
    } catch (e) {
      print('❌ Erro ao iniciar execução: $e');
      rethrow;
    }
  }

  /// Pausar execução do trabalho
  Future<void> pausarExecucao(String chamadoId) async {
    try {
      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'status': StatusChamadoManutencao.atribuidoExecutor.value,
      });

      print('✅ Execução pausada: $chamadoId');
    } catch (e) {
      print('❌ Erro ao pausar execução: $e');
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
        print('⚠️ Erro ao enviar notificação de finalização: $e');
      }

      print('✅ Chamado finalizado: $chamadoId');
    } catch (e) {
      print('❌ Erro ao finalizar chamado: $e');
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
        print('⚠️ Erro ao enviar notificação de recusa: $e');
      }

      print('✅ Chamado recusado: $chamadoId');
    } catch (e) {
      print('❌ Erro ao recusar chamado: $e');
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

      print('✅ Orçamento enviado: $url');
      return url;
    } catch (e) {
      print('❌ Erro ao enviar orçamento: $e');
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

      print('✅ Foto enviada: $url');
      return url;
    } catch (e) {
      print('❌ Erro ao enviar foto: $e');
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

        print('✅ Foto ${i + 1}/${fotos.length} enviada: $url');
      }

      print('✅ Total de ${urls.length} fotos enviadas');
      return urls;
    } catch (e) {
      print('❌ Erro ao enviar fotos: $e');
      rethrow;
    }
  }

  /// Atualizar fotos do chamado
  Future<void> atualizarFotos(String chamadoId, List<String> fotosUrls) async {
    try {
      await _firestore.collection(_chamadosCollection).doc(chamadoId).update({
        'fotosUrls': fotosUrls,
      });
      print('✅ Fotos atualizadas no chamado $chamadoId');
    } catch (e) {
      print('❌ Erro ao atualizar fotos: $e');
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
      print('❌ Erro ao buscar chamado: $e');
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
          print('🔍 DEBUG: Total de docs retornados: ${snapshot.docs.length}');
          final chamados = snapshot.docs.map((doc) {
            print('📄 DEBUG: Doc ${doc.id} - tipo: ${doc.data()['tipo']}');
            return ChamadoManutencao.fromMap(doc.data(), doc.id);
          }).toList();
          print('✅ DEBUG: Total de chamados processados: ${chamados.length}');
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

  /// Stream de chamados para Executor (apenas atribuídos a ele)
  Stream<List<ChamadoManutencao>> getChamadosParaExecutor(String executorId) {
    return _firestore
        .collection(_chamadosCollection)
        .where('tipo', isEqualTo: 'MANUTENCAO')
        .where('execucao.executorId', isEqualTo: executorId)
        .orderBy('dataAbertura', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChamadoManutencao.fromMap(doc.data(), doc.id))
              .toList();
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
      print('❌ Erro ao buscar estatísticas: $e');
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
      print('🗑️ Iniciando exclusão do chamado: $chamadoId');

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
        print('🗑️ Deletando comentários...');
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
        print('✅ ${comentariosSnapshot.docs.length} comentários deletados');
      } catch (e) {
        print('⚠️ Erro ao deletar comentários: $e');
      }

      // 3. Deletar arquivos do Storage
      try {
        print('🗑️ Deletando arquivos do Storage...');

        // Deletar pasta de orçamento
        await _deletarPastaStorage('manutencao/$chamadoId/orcamento');

        // Deletar pasta de compra
        await _deletarPastaStorage('manutencao/$chamadoId/compra');

        // Deletar pasta de execução
        await _deletarPastaStorage('manutencao/$chamadoId/execucao');

        print('✅ Arquivos do Storage deletados');
      } catch (e) {
        print('⚠️ Erro ao deletar arquivos do Storage: $e');
      }

      // 4. Deletar documento do chamado
      await _firestore.collection(_chamadosCollection).doc(chamadoId).delete();

      print('✅ Chamado $chamadoId deletado completamente');
    } catch (e) {
      print('❌ Erro ao deletar chamado: $e');
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
        print('   🗑️ Arquivo deletado: ${item.name}');
      }

      // Recursivamente deletar subpastas
      for (final prefix in listResult.prefixes) {
        await _deletarPastaStorage(prefix.fullPath);
      }
    } catch (e) {
      // Ignora erro se pasta não existir
      if (!e.toString().contains('object-not-found')) {
        print('   ⚠️ Erro ao deletar pasta $caminho: $e');
      }
    }
  }
}
