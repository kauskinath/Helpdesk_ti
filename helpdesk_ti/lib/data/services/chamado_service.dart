import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/features/ti/models/solicitacao.dart';
import 'package:helpdesk_ti/core/services/notification_service.dart';
import 'package:helpdesk_ti/core/utils/retry_helper.dart';

/// Serviço responsável por todas as operações relacionadas a Chamados (Tickets)
///
/// Este serviço encapsula toda a lógica de negócio para:
/// - Criação de chamados com numeração sequencial automática
/// - Consulta de chamados (por ID, usuário, status)
/// - Atualização de status e dados do chamado
/// - Upload de anexos para Firebase Storage
/// - Adição de comentários
/// - Estatísticas e métricas de chamados
/// - Envio automático de notificações push
class ChamadoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // ========== LOGGING CONDICIONAL ==========
  void _log(String message) {
    if (kDebugMode) print(message);
  }

  // ============ CRIAÇÃO E NUMERAÇÃO ============

  /// Gera próximo número sequencial para chamados usando transação atômica
  ///
  /// Utiliza um documento contador no Firestore para garantir que cada
  /// chamado tenha um número único e sequencial. Em caso de erro,
  /// busca o maior número existente na coleção.
  ///
  /// Returns: Próximo número disponível para o chamado
  Future<int> gerarProximoNumero() async {
    try {
      final contadorDoc = _firestore.collection('counters').doc('chamados');

      // Usar transação com retry para garantir unicidade
      return await RetryHelper.withTransactionRetry<int>(
        transaction: () => _firestore.runTransaction<int>((transaction) async {
          final snapshot = await transaction.get(contadorDoc);

          int novoNumero;
          if (!snapshot.exists) {
            // Criar contador se não existir
            novoNumero = 1;
            transaction.set(contadorDoc, {'ultimoNumero': novoNumero});
          } else {
            // Incrementar contador existente
            novoNumero = (snapshot.data()?['ultimoNumero'] ?? 0) + 1;
            transaction.update(contadorDoc, {'ultimoNumero': novoNumero});
          }

          return novoNumero;
        }),
        maxAttempts: 3,
      );
    } catch (e) {
      _log('❌ Erro ao gerar número via transação: $e');
      // Fallback: buscar o maior número existente na coleção e incrementar
      return await _gerarNumeroFallback();
    }
  }

  /// Fallback para gerar número quando a transação falha
  /// Busca o maior número existente na coleção tickets e incrementa
  Future<int> _gerarNumeroFallback() async {
    try {
      _log('⚠️ Usando fallback para gerar número...');

      // Buscar chamado com maior número
      final querySnapshot = await _firestore
          .collection('tickets')
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
      return DateTime.now().millisecondsSinceEpoch ~/
          1000; // Segundos desde epoch
    }
  }

  /// Cria um novo chamado no Firestore com numeração automática
  ///
  /// O chamado é criado na coleção 'tickets' com:
  /// - Número sequencial único
  /// - Todos os dados fornecidos
  /// - Timestamps automáticos
  ///
  /// [chamado] - Objeto Chamado com os dados a serem salvos
  ///
  /// Returns: ID do documento criado no Firestore
  Future<String> criarChamado(Chamado chamado) async {
    try {
      // Gerar número sequencial
      final numero = await gerarProximoNumero();

      // Criar chamado com número
      final chamadoComNumero = Chamado(
        id: chamado.id,
        numero: numero,
        titulo: chamado.titulo,
        descricao: chamado.descricao,
        setor: chamado.setor,
        tipo: chamado.tipo,
        status: chamado.status,
        usuarioId: chamado.usuarioId,
        usuarioNome: chamado.usuarioNome,
        adminId: chamado.adminId,
        adminNome: chamado.adminNome,
        linkOuEspecificacao: chamado.linkOuEspecificacao,
        anexos: chamado.anexos,
        custoEstimado: chamado.custoEstimado,
        dataCriacao: chamado.dataCriacao,
        dataAtualizacao: chamado.dataAtualizacao,
        dataFechamento: chamado.dataFechamento,
        motivoRejeicao: chamado.motivoRejeicao,
        prioridade: chamado.prioridade,
      );

      final docRef = await _firestore
          .collection('tickets')
          .add(chamadoComNumero.toMap());

      // Enviar notificação para admins/TI e AGUARDAR conclusão
      try {
        await _notificationService.sendNotificationToRoles(
          titulo: '🆕 Novo Chamado #${numero.toString().padLeft(4, '0')}',
          corpo: '${chamado.usuarioNome}: ${chamado.titulo}',
          roles: ['admin', 'ti'],
          data: {
            'tipo': 'novo_chamado',
            'chamadoId': docRef.id,
            'numero': numero.toString(),
          },
          excludeUserId: chamado.usuarioId,
        );
      } catch (e, stackTrace) {
        _log('❌ ERRO CRÍTICO ao enviar notificação de novo chamado: $e');
        _log('Stack trace: $stackTrace');
        // Não falhar a criação do chamado por causa da notificação
      }

      // Pequeno delay para garantir que Firestore propagou as mudanças
      await Future.delayed(const Duration(milliseconds: 300));

      return docRef.id;
    } catch (e) {
      throw 'Erro ao criar chamado: $e';
    }
  }

  // ============ CONSULTAS ============

  /// Busca um chamado específico por ID
  ///
  /// [chamadoId]: ID do documento no Firestore
  /// Returns: Objeto Chamado ou null se não encontrado
  Future<Chamado?> getChamado(String chamadoId) async {
    try {
      final doc = await _firestore.collection('tickets').doc(chamadoId).get();
      if (doc.exists) {
        return Chamado.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Erro ao buscar chamado: $e';
    }
  }

  /// Busca todos os chamados de um usuário específico
  ///
  /// Retorna um Stream que atualiza em tempo real quando há mudanças
  /// nos chamados do usuário.
  ///
  /// [userId]: ID do usuário (Firebase Auth UID)
  /// Returns: Stream de lista de chamados ordenados por data (mais recentes primeiro)
  Stream<List<Chamado>> getChamadosDoUsuario(String userId) {
    // Stream iniciado - log removido para performance
    return _firestore
        .collection('tickets')
        .where('usuarioId', isEqualTo: userId)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            final chamados = <Chamado>[];
            for (var doc in snapshot.docs) {
              try {
                final chamado = Chamado.fromMap(doc.data(), doc.id);
                chamados.add(chamado);
              } catch (e) {
                _log('❌ Erro ao parsear chamado ${doc.id}: $e');
              }
            }
            return chamados;
          } catch (e) {
            _log('❌ ERRO no map do Stream: $e');
            return <Chamado>[];
          }
        });
  }

  /// Lista todos os chamados do sistema (para admin/TI)
  ///
  /// Retorna um Stream com todos os chamados ordenados por data de criação.
  /// Útil para a Fila Técnica onde admins veem todos os tickets.
  ///
  /// Returns: Stream de lista completa de chamados
  Stream<List<Chamado>> getTodosChamadosStream() {
    return _firestore.collection('tickets').snapshots().map((snapshot) {
      final chamados = snapshot.docs.map((doc) {
        return Chamado.fromMap(doc.data(), doc.id);
      }).toList();

      chamados.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      return chamados;
    });
  }

  /// Lista chamados por status específico
  ///
  /// Útil para filtrar chamados em aberto, em andamento, fechados, etc.
  ///
  /// [status]: Status desejado ('Aberto', 'Em Andamento', 'Fechado', etc)
  /// Returns: Stream de chamados com o status especificado
  Stream<List<Chamado>> getChamadosPorStatus(String status) {
    return _firestore
        .collection('tickets')
        .where('status', isEqualTo: status)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Chamado.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // ============ ATUALIZAÇÕES ============

  /// Atualiza o status de um chamado
  ///
  /// Além de atualizar o status, também:
  /// - Atualiza dataAtualizacao para now()
  /// - Define dataFechamento se status for 'Fechado'
  /// - Envia notificação para o usuário criador
  ///
  /// [chamadoId]: ID do chamado a ser atualizado
  /// [novoStatus]: Novo status a ser aplicado
  Future<void> atualizarStatus(String chamadoId, String novoStatus) async {
    try {
      // Buscar dados do chamado antes de atualizar
      final chamadoDoc = await _firestore
          .collection('tickets')
          .doc(chamadoId)
          .get();
      final chamadoData = chamadoDoc.data();

      final updateData = {
        'status': novoStatus,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      };

      // Se fechando, adicionar timestamp
      if (novoStatus == 'Fechado') {
        updateData['dataFechamento'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('tickets').doc(chamadoId).update(updateData);

      // 🔔 Enviar notificação para o usuário criador
      if (chamadoData != null) {
        final usuarioId = chamadoData['usuarioId'] as String?;
        final numero = chamadoData['numero'] as int?;
        final adminNome = chamadoData['adminNome'] as String?;

        if (usuarioId != null && numero != null) {
          String titulo = '';
          String corpo = '';

          switch (novoStatus) {
            case 'Em Andamento':
              titulo = '✅ Chamado #${numero.toString().padLeft(4, '0')} Aceito';
              corpo = '${adminNome ?? 'TI'} aceitou seu chamado';
              break;
            case 'Fechado':
              titulo =
                  '✔️ Chamado #${numero.toString().padLeft(4, '0')} Finalizado';
              corpo =
                  'Seu chamado foi concluído. Por favor, avalie o atendimento.';
              break;
            case 'Rejeitado':
              titulo =
                  '❌ Chamado #${numero.toString().padLeft(4, '0')} Rejeitado';
              corpo =
                  chamadoData['motivoRejeicao'] as String? ??
                  'Seu chamado foi rejeitado';
              break;
            default:
              titulo =
                  '🔔 Chamado #${numero.toString().padLeft(4, '0')} Atualizado';
              corpo = 'Status: $novoStatus';
          }

          _notificationService.sendNotificationToUser(
            userId: usuarioId,
            titulo: titulo,
            corpo: corpo,
            data: {
              'tipo': 'chamado_atualizado',
              'chamadoId': chamadoId,
              'numero': numero.toString(),
              'status': novoStatus,
            },
          );
        }
      }
    } catch (e) {
      throw 'Erro ao atualizar status: $e';
    }
  }

  /// Atribui um admin/técnico a um chamado
  ///
  /// [chamadoId]: ID do chamado
  /// [adminId]: ID do admin (Firebase Auth UID)
  /// [adminNome]: Nome do admin para exibição
  Future<void> atribuirAdmin(
    String chamadoId,
    String adminId,
    String adminNome,
  ) async {
    try {
      await _firestore.collection('tickets').doc(chamadoId).update({
        'adminId': adminId,
        'adminNome': adminNome,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });
      _log('✅ Admin $adminNome atribuído ao chamado $chamadoId');
    } catch (e) {
      throw 'Erro ao atribuir admin: $e';
    }
  }

  /// Atualiza a prioridade de um chamado
  ///
  /// [chamadoId]: ID do chamado
  /// [prioridade]: Nova prioridade (1=Baixa, 2=Média, 3=Alta, 4=Crítica)
  Future<void> atualizarPrioridade(String chamadoId, int prioridade) async {
    try {
      await _firestore.collection('tickets').doc(chamadoId).update({
        'prioridade': prioridade,
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });
      _log('✅ Prioridade do chamado $chamadoId atualizada para $prioridade');
    } catch (e) {
      throw 'Erro ao atualizar prioridade: $e';
    }
  }

  // ============ ANEXOS ============

  /// Comprime uma imagem antes do upload
  ///
  /// Reduz o tamanho do arquivo mantendo qualidade aceitável.
  /// Aplica compressão e redimensionamento se necessário.
  ///
  /// [imageFile]: Arquivo de imagem original
  /// Returns: Bytes da imagem comprimida
  Future<Uint8List> _comprimirImagem(XFile imageFile) async {
    try {
      // Ler bytes originais
      final bytesOriginais = await imageFile.readAsBytes();
      final tamanhoOriginal = bytesOriginais.length;

      _log(
        '📸 Imagem original: ${(tamanhoOriginal / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Comprimir imagem
      final resultado = await FlutterImageCompress.compressWithList(
        bytesOriginais,
        minWidth: 1920, // Largura máxima: 1920px (Full HD)
        minHeight: 1920, // Altura máxima: 1920px
        quality: 85, // Qualidade 85% (boa qualidade, menor tamanho)
        format: CompressFormat.jpeg, // Converter para JPEG (menor que PNG)
      );

      final tamanhoComprimido = resultado.length;
      final reducao = ((1 - tamanhoComprimido / tamanhoOriginal) * 100);

      _log(
        '✅ Imagem comprimida: ${(tamanhoComprimido / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      _log('📉 Redução: ${reducao.toStringAsFixed(1)}%');

      return resultado;
    } catch (e) {
      _log('⚠️ Erro ao comprimir, usando imagem original: $e');
      // Se falhar, retorna a imagem original
      return await imageFile.readAsBytes();
    }
  }

  /// Faz upload de uma imagem para o Firebase Storage
  ///
  /// A imagem é comprimida automaticamente antes do upload para economizar
  /// espaço e melhorar velocidade de envio.
  ///
  /// A imagem é salva em: storage/chamados/{chamadoId}/{timestamp}_{filename}
  ///
  /// [chamadoId]: ID do chamado (para organizar no Storage)
  /// [imageFile]: Arquivo de imagem selecionado
  /// Returns: URL pública da imagem no Storage
  Future<String> uploadImage(String chamadoId, XFile imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${imageFile.name}';
      final storageRef = _storage.ref().child('chamados/$chamadoId/$fileName');

      // ✅ NOVO: Comprimir imagem antes de enviar
      _log('🔄 Comprimindo imagem antes do upload...');
      final bytesComprimidos = await _comprimirImagem(imageFile);

      // Enviar bytes comprimidos
      await storageRef.putData(bytesComprimidos);

      final downloadUrl = await storageRef.getDownloadURL();
      _log('✅ Imagem enviada: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      throw 'Erro ao fazer upload da imagem: $e';
    }
  }

  /// Faz upload de arquivo genérico (PDF, DOC, XLS, etc) para Firebase Storage
  ///
  /// Aceita qualquer tipo de arquivo e salva no Storage sem compressão.
  /// Útil para documentos, planilhas, PDFs e outros arquivos não-imagem.
  ///
  /// O arquivo é salvo em: storage/chamados/{chamadoId}/files/{timestamp}_{filename}
  ///
  /// [chamadoId]: ID do chamado (para organizar no Storage)
  /// [fileBytes]: Bytes do arquivo
  /// [fileName]: Nome do arquivo original
  /// Returns: URL pública do arquivo no Storage
  Future<String> uploadFile({
    required String chamadoId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = '${timestamp}_$fileName';
      final storageRef = _storage.ref().child(
        'chamados/$chamadoId/files/$safeFileName',
      );

      // Detectar tipo de arquivo pela extensão
      final extension = fileName.split('.').last.toLowerCase();
      String? contentType;

      switch (extension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          contentType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      _log('📄 Enviando arquivo: $fileName');
      _log(
        '📊 Tamanho: ${(fileBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      _log('🏷️ Tipo: $contentType');

      // Fazer upload com metadata
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'originalFileName': fileName,
          'uploadTimestamp': timestamp.toString(),
        },
      );

      await storageRef.putData(fileBytes, metadata);

      final downloadUrl = await storageRef.getDownloadURL();
      _log('✅ Arquivo enviado: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      _log('❌ Erro ao fazer upload do arquivo: $e');
      throw 'Erro ao fazer upload do arquivo: $e';
    }
  }

  // ============ COMENTÁRIOS ============

  /// Adiciona comentário em coleção separada com named parameters
  ///
  /// Os comentários são salvos na coleção 'comentarios' do Firestore.
  /// Usado para comentários de mudança de status e interações detalhadas.
  /// Envia notificação para as partes envolvidas.
  ///
  /// [chamadoId] - ID do chamado
  /// [autorId] - ID do autor do comentário
  /// [autorNome] - Nome do autor
  /// [autorRole] - Papel/role do autor (user, admin, manager)
  /// [mensagem] - Texto do comentário
  /// [tipo] - Tipo do comentário (opcional, padrão: 'comentario')
  Future<void> adicionarComentarioNamed({
    required String chamadoId,
    required String autorId,
    required String autorNome,
    required String autorRole,
    required String mensagem,
    String? tipo,
  }) async {
    try {
      final comentarioData = {
        'chamadoId': chamadoId,
        'autorId': autorId,
        'autorNome': autorNome,
        'autorRole': autorRole,
        'mensagem': mensagem,
        'dataHora': FieldValue.serverTimestamp(),
        'tipo': tipo ?? 'comentario',
        'usuarioId': autorId, // Compatibilidade
        'usuarioNome': autorNome, // Compatibilidade
        'texto': mensagem, // Compatibilidade
      };

      await _firestore.collection('comentarios').add(comentarioData);
      _log('✅ Comentário adicionado ao chamado $chamadoId');
      _log('📝 Dados salvos: $comentarioData');

      // 🔔 Enviar notificação para partes envolvidas
      final chamadoDoc = await _firestore
          .collection('tickets')
          .doc(chamadoId)
          .get();
      if (chamadoDoc.exists) {
        final chamadoData = chamadoDoc.data();
        final usuarioId = chamadoData?['usuarioId'] as String?;
        final adminId = chamadoData?['adminId'] as String?;
        final numero = chamadoData?['numero'] as int?;

        // Lista de usuários a notificar (SET para evitar duplicatas)
        final usuariosParaNotificar = <String>{};
        if (usuarioId != null && usuarioId != autorId) {
          usuariosParaNotificar.add(usuarioId);
        }
        if (adminId != null && adminId != autorId && adminId != usuarioId) {
          usuariosParaNotificar.add(adminId);
        }

        if (usuariosParaNotificar.isNotEmpty && numero != null) {
          _notificationService.sendNotificationToUsers(
            userIds: usuariosParaNotificar.toList(),
            titulo:
                '💬 Novo Comentário - #${numero.toString().padLeft(4, '0')}',
            corpo:
                '$autorNome: ${mensagem.length > 50 ? '${mensagem.substring(0, 50)}...' : mensagem}',
            data: {
              'tipo': 'novo_comentario',
              'chamadoId': chamadoId,
              'numero': numero.toString(),
            },
            excludeUserId: autorId, // Não notificar o autor do comentário
          );
        }
      }
    } catch (e) {
      _log('❌ Erro ao adicionar comentário: $e');
      throw 'Erro ao adicionar comentário: $e';
    }
  }

  /// Adiciona comentário no array do documento do chamado
  ///
  /// Os comentários são salvos no array 'comentarios' dentro do documento.
  /// Versão mais simples para comentários básicos.
  ///
  /// [chamadoId] - ID do chamado
  /// [comentario] - Mapa com dados do comentário (texto, autor, data, etc)
  Future<void> adicionarComentarioMap(
    String chamadoId,
    Map<String, dynamic> comentario,
  ) async {
    try {
      await _firestore.collection('tickets').doc(chamadoId).update({
        'comentarios': FieldValue.arrayUnion([comentario]),
        'dataAtualizacao': FieldValue.serverTimestamp(),
      });
      _log('✅ Comentário adicionado ao chamado $chamadoId');
    } catch (e) {
      throw 'Erro ao adicionar comentário: $e';
    }
  }

  /// Atualiza chamado com dados parciais (mapa de campos)
  ///
  /// Permite atualizar campos específicos sem precisar do objeto completo.
  ///
  /// [chamadoId] - ID do chamado
  /// [dados] - Mapa com campos a serem atualizados
  Future<void> atualizarChamado(
    String chamadoId,
    Map<String, dynamic> dados,
  ) async {
    try {
      await _firestore.collection('tickets').doc(chamadoId).update(dados);
      _log('✅ Chamado $chamadoId atualizado');
    } catch (e) {
      throw 'Erro ao atualizar chamado: $e';
    }
  }

  /// Atualiza chamado completo usando objeto Chamado
  ///
  /// Substitui todos os dados do chamado pelos dados do objeto fornecido.
  ///
  /// [chamado] - Objeto Chamado com dados atualizados
  Future<void> atualizarChamadoCompleto(Chamado chamado) async {
    try {
      await _firestore
          .collection('tickets')
          .doc(chamado.id)
          .update(chamado.toMap());
      _log('✅ Chamado completo ${chamado.id} atualizado');
    } catch (e) {
      throw 'Erro ao atualizar chamado completo: $e';
    }
  }

  // ============ ESTATÍSTICAS ============

  /// Obtém estatísticas de chamados para um usuário específico
  ///
  /// Calcula métricas como:
  /// - Total de chamados criados
  /// - Chamados abertos
  /// - Chamados em andamento
  /// - Chamados fechados
  /// - Tempo médio de resolução
  ///
  /// [userId]: ID do usuário
  /// Returns: Mapa com as estatísticas
  Future<Map<String, dynamic>> getStatsUsuario(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('usuarioId', isEqualTo: userId)
          .get();

      final chamados = snapshot.docs.map((doc) {
        return Chamado.fromMap(doc.data(), doc.id);
      }).toList();

      final total = chamados.length;
      final abertos = chamados.where((c) => c.status == 'Aberto').length;
      final emAndamento = chamados
          .where((c) => c.status == 'Em Andamento')
          .length;
      final fechados = chamados.where((c) => c.status == 'Fechado').length;

      return {
        'total': total,
        'abertos': abertos,
        'emAndamento': emAndamento,
        'fechados': fechados,
      };
    } catch (e) {
      _log('❌ Erro ao buscar stats do usuário: $e');
      return {'total': 0, 'abertos': 0, 'emAndamento': 0, 'fechados': 0};
    }
  }

  /// Obtém estatísticas gerais para dashboard de admin
  ///
  /// Fornece visão completa do sistema incluindo:
  /// - Total de chamados
  /// - Distribuição por status
  /// - Distribuição por prioridade
  /// - Distribuição por setor
  ///
  /// Returns: Mapa com estatísticas detalhadas
  Future<Map<String, dynamic>> getStatsAdmin() async {
    try {
      final snapshot = await _firestore.collection('tickets').get();

      final chamados = snapshot.docs.map((doc) {
        return Chamado.fromMap(doc.data(), doc.id);
      }).toList();

      final total = chamados.length;
      final abertos = chamados.where((c) => c.status == 'Aberto').length;
      final emAndamento = chamados
          .where((c) => c.status == 'Em Andamento')
          .length;
      final fechados = chamados.where((c) => c.status == 'Fechado').length;

      // Prioridades
      final p1 = chamados.where((c) => c.prioridade == 1).length;
      final p2 = chamados.where((c) => c.prioridade == 2).length;
      final p3 = chamados.where((c) => c.prioridade == 3).length;
      final p4 = chamados.where((c) => c.prioridade == 4).length;

      // Setores
      final porSetor = <String, int>{};
      for (var chamado in chamados) {
        porSetor[chamado.setor] = (porSetor[chamado.setor] ?? 0) + 1;
      }

      return {
        'total': total,
        'abertos': abertos,
        'emAndamento': emAndamento,
        'fechados': fechados,
        'prioridadeBaixa': p1,
        'prioridadeMedia': p2,
        'prioridadeAlta': p3,
        'prioridadeCritica': p4,
        'chamadosPorSetor': porSetor,
      };
    } catch (e) {
      _log('❌ Erro ao buscar stats admin: $e');
      return {};
    }
  }

  // ============ UTILIDADES ============

  /// Deleta completamente um chamado de TI e todos os dados relacionados
  ///
  /// Remove:
  /// - Documento do chamado no Firestore
  /// - Subcoleção de comentários
  /// - Subcoleção de avaliacoes
  /// - Todos os arquivos anexados no Firebase Storage
  ///
  /// ⚠️ ATENÇÃO: Remove permanentemente. Usar com cuidado!
  ///
  /// [chamadoId]: ID do chamado a ser deletado
  ///
  /// Throws: Exception se houver erro na exclusão
  Future<void> deletarChamado(String chamadoId) async {
    try {
      _log('🗑️ Iniciando exclusão do chamado TI: $chamadoId');

      // 1. Buscar chamado para verificar se existe
      final chamadoDoc = await _firestore
          .collection('tickets')
          .doc(chamadoId)
          .get();

      if (!chamadoDoc.exists) {
        throw 'Chamado não encontrado';
      }

      // 2. Deletar subcoleção de comentários
      try {
        _log('🗑️ Deletando comentários...');
        final comentariosSnapshot = await _firestore
            .collection('comentarios')
            .where('chamadoId', isEqualTo: chamadoId)
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

      // 3. Deletar subcoleção de avaliações
      try {
        _log('🗑️ Deletando avaliações...');
        final avaliacoesSnapshot = await _firestore
            .collection('avaliacoes')
            .where('chamadoId', isEqualTo: chamadoId)
            .get();

        final batch = _firestore.batch();
        for (final doc in avaliacoesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        _log('✅ ${avaliacoesSnapshot.docs.length} avaliações deletadas');
      } catch (e) {
        _log('⚠️ Erro ao deletar avaliações: $e');
      }

      // 4. Deletar arquivos do Storage
      try {
        _log('🗑️ Deletando arquivos do Storage...');

        // Deletar pasta completa do chamado
        await _deletarPastaStorage('tickets/$chamadoId');

        _log('✅ Arquivos do Storage deletados');
      } catch (e) {
        _log('⚠️ Erro ao deletar arquivos do Storage: $e');
      }

      // 5. Deletar documento do chamado
      await _firestore.collection('tickets').doc(chamadoId).delete();

      _log('✅ Chamado TI $chamadoId deletado completamente');
    } catch (e) {
      _log('❌ Erro ao deletar chamado TI: $e');
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

  /// Deleta todos os chamados (USE COM EXTREMO CUIDADO!)
  ///
  /// Remove todos os documentos da coleção 'tickets'.
  /// Apenas para uso em desenvolvimento/teste.
  ///
  /// Returns: Número de documentos deletados
  Future<int> deletarTodosChamados() async {
    try {
      final snapshot = await _firestore.collection('tickets').get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _log('✅ Todos os ${snapshot.docs.length} chamados foram deletados');
      return snapshot.docs.length;
    } catch (e) {
      throw 'Erro ao deletar todos os chamados: $e';
    }
  }

  /// Stream de comentários de um chamado (coleção separada)
  ///
  /// Retorna todos os comentários de um chamado em tempo real,
  /// ordenados por data/hora decrescente (mais recentes primeiro).
  ///
  /// [chamadoId]: ID do chamado
  /// Returns: Stream de lista de mapas com dados dos comentários
  Stream<List<Map<String, dynamic>>> getComentariosStream(
    String chamadoId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('comentarios')
        .where('chamadoId', isEqualTo: chamadoId)
        .orderBy('dataHora', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Busca comentários com paginação (versão otimizada)
  ///
  /// Carrega comentários em lotes para melhorar performance.
  /// Útil para chamados com muitos comentários (100+).
  ///
  /// **Como funciona:**
  /// - Primeira chamada: passa `ultimoDocumento = null` → carrega primeiros 20
  /// - Próximas chamadas: passa o último documento recebido → carrega próximos 20
  ///
  /// **Exemplo de uso:**
  /// ```dart
  /// // Carregar primeiros 20
  /// final resultado1 = await service.getComentariosPaginados(chamadoId);
  ///
  /// // Carregar próximos 20 (se houver)
  /// if (resultado1['temMais'] == true) {
  ///   final resultado2 = await service.getComentariosPaginados(
  ///     chamadoId,
  ///     ultimoDocumento: resultado1['ultimoDocumento'],
  ///   );
  /// }
  /// ```
  ///
  /// [chamadoId] - ID do chamado
  /// [limite] - Quantidade de comentários por página (padrão: 20)
  /// [ultimoDocumento] - Último documento da página anterior (para paginação)
  ///
  /// Returns: Mapa contendo:
  /// - 'comentarios': Lista de comentários
  /// - 'ultimoDocumento': Último documento (para próxima página)
  /// - 'temMais': Se há mais comentários para carregar
  Future<Map<String, dynamic>> getComentariosPaginados(
    String chamadoId, {
    int limite = 20,
    DocumentSnapshot? ultimoDocumento,
  }) async {
    try {
      // Construir query base
      Query query = _firestore
          .collection('comentarios')
          .where('chamadoId', isEqualTo: chamadoId)
          .orderBy(
            'dataHora',
            descending: true,
          ) // Do mais novo para o mais antigo (inverter ordem)
          .limit(limite + 1); // +1 para saber se tem mais páginas

      // Se tem documento anterior, começar depois dele
      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      // Executar query
      final snapshot = await query.get();

      // Processar resultados
      final docs = snapshot.docs;
      final temMais = docs.length > limite; // Se trouxe +1, tem mais páginas

      // Pegar apenas os documentos do limite (remover o +1)
      final comentariosDocs = temMais ? docs.sublist(0, limite) : docs;

      // Converter para mapas e INVERTER ordem (mais antigos primeiro)
      final comentarios = comentariosDocs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .toList()
          .reversed
          .toList();

      _log('📄 Página carregada: ${comentarios.length} comentários');
      if (temMais) {
        _log('➡️ Há mais comentários para carregar');
      } else {
        _log('✅ Todos os comentários carregados');
      }

      return {
        'comentarios': comentarios,
        'ultimoDocumento': comentariosDocs.isNotEmpty
            ? comentariosDocs.last
            : null,
        'temMais': temMais,
      };
    } catch (e) {
      _log('❌ Erro ao buscar comentários paginados: $e');
      throw 'Erro ao buscar comentários paginados: $e';
    }
  }

  /// Conta o total de comentários de um chamado
  ///
  /// Usado para exibir "Mostrando X de Y comentários" na interface.
  /// Executa um count() no Firestore, que é mais eficiente que buscar todos.
  ///
  /// [chamadoId] - ID do chamado
  /// Returns: Número total de comentários
  Future<int> getTotalComentarios(String chamadoId) async {
    try {
      final snapshot = await _firestore
          .collection('comentarios')
          .where('chamadoId', isEqualTo: chamadoId)
          .count()
          .get();

      final total = snapshot.count ?? 0;
      _log('💬 Total de comentários: $total');
      return total;
    } catch (e) {
      _log('❌ Erro ao contar comentários: $e');
      return 0;
    }
  }

  /// Estatísticas para manager (por setor)
  ///
  /// Fornece estatísticas dos chamados e solicitações de um setor específico.
  ///
  /// [setor]: Nome do setor para filtrar
  /// Returns: Mapa com estatísticas do setor
  Future<Map<String, dynamic>> getStatsManager(String setor) async {
    try {
      final chamadosSnapshot = await _firestore
          .collection('tickets')
          .where('setor', isEqualTo: setor)
          .get();

      final solicitacoesSnapshot = await _firestore
          .collection('solicitacoes')
          .where('setor', isEqualTo: setor)
          .get();

      int aguardandoAprovacao = 0, aprovadas = 0, rejeitadas = 0;

      for (var doc in solicitacoesSnapshot.docs) {
        final status = doc.data()['status'] ?? '';
        if (status == 'Pendente') aguardandoAprovacao++;
        if (status == 'Aprovada') aprovadas++;
        if (status == 'Rejeitada') rejeitadas++;
      }

      return {
        'totalChamadosSetor': chamadosSnapshot.docs.length,
        'totalSolicitacoesSetor': solicitacoesSnapshot.docs.length,
        'solicitacoesAguardando': aguardandoAprovacao,
        'solicitacoesAprovadas': aprovadas,
        'solicitacoesRejeitadas': rejeitadas,
      };
    } catch (e) {
      _log('❌ Erro ao buscar stats manager: $e');
      return {};
    }
  }

  /// Stream de chamados do usuário
  ///
  /// Alternativa do método getChamadosDoUsuario com nome Stream explícito.
  /// Delegado para o método getChamadosDoUsuario.
  ///
  /// [usuarioId]: ID do usuário
  /// Returns: Stream de lista de chamados
  Stream<List<Chamado>> getChamadosDoUsuarioStream(String usuarioId) {
    return getChamadosDoUsuario(usuarioId);
  }

  /// Cria chamado técnico a partir de solicitação aprovada
  ///
  /// Converte uma solicitação aprovada em um chamado técnico,
  /// mantendo todas as informações relevantes no histórico.
  ///
  /// [solicitacao]: Objeto Solicitacao já aprovado
  /// Returns: ID do chamado criado
  /// Throws: Exception se solicitação não estiver aprovada
  Future<String> criarChamadoDeSolicitacao({
    required Solicitacao solicitacao,
  }) async {
    try {
      // Verificar se a solicitação está aprovada
      if (solicitacao.status != 'Aprovado') {
        throw 'Apenas solicitações aprovadas podem gerar chamados técnicos';
      }

      // Criar objeto Chamado
      final chamado = Chamado(
        id: '', // Será gerado pelo Firestore
        numero: null, // Será gerado automaticamente
        titulo: 'COMPRA: ${solicitacao.itemSolicitado}',
        descricao:
            'SOLICITAÇÃO ${solicitacao.numeroFormatado} - ${solicitacao.titulo}\n\n'
            '📝 DESCRIÇÃO:\n${solicitacao.descricao}\n\n'
            '🛒 ITEM SOLICITADO:\n${solicitacao.itemSolicitado}\n\n'
            '💡 JUSTIFICATIVA:\n${solicitacao.justificativa}\n\n'
            '💰 CUSTO ESTIMADO: R\$ ${solicitacao.custoEstimado?.toStringAsFixed(2) ?? "Não informado"}\n\n'
            '✅ Aprovado por: ${solicitacao.managerNome ?? "Gerente"}',
        setor: solicitacao.setor,
        tipo: 'Chamado',
        status: 'Aberto',
        usuarioId: solicitacao.usuarioId,
        usuarioNome: solicitacao.usuarioNome,
        adminId: null,
        adminNome: null,
        linkOuEspecificacao: null,
        anexos: [],
        custoEstimado: solicitacao.custoEstimado,
        dataCriacao: DateTime.now(),
        dataAtualizacao: null,
        dataFechamento: null,
        motivoRejeicao: null,
        prioridade: 2, // Média
      );

      // Criar chamado
      final chamadoId = await criarChamado(chamado);

      _log(
        '✅ Chamado $chamadoId criado a partir da solicitação ${solicitacao.id}',
      );
      return chamadoId;
    } catch (e) {
      _log('❌ Erro ao criar chamado de solicitação: $e');
      throw 'Erro ao criar chamado de solicitação: $e';
    }
  }

  // ============ NOVOS MÉTODOS PARA OTIMIZAÇÃO ============

  /// Busca apenas chamados ativos (não arquivados)
  ///
  /// Query otimizada que:
  /// - Filtra chamados não arquivados (foiArquivado = false)
  /// - Filtra apenas status ativos (Aberto, Em Andamento, Aguardando)
  /// - Ordena por última atualização (mais recentes primeiro)
  /// - Limita a 50 resultados (paginação)
  ///
  /// Returns: Stream de lista de chamados ativos
  Stream<List<Chamado>> getChamadosAtivosStream() {
    // Query simplificada para evitar erro de índice composto
    // Ordenação feita no cliente
    return _firestore
        .collection('tickets')
        .where('status', whereIn: ['Aberto', 'Em Andamento', 'Aguardando'])
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final chamados = snapshot.docs
              .map((doc) => Chamado.fromMap(doc.data(), doc.id))
              .where((c) => !c.foiArquivado) // Filtro no cliente
              .toList();
          // Ordenar no cliente por lastUpdated
          chamados.sort((a, b) {
            final aDate = a.lastUpdated ?? a.dataCriacao;
            final bDate = b.lastUpdated ?? b.dataCriacao;
            return bDate.compareTo(aDate);
          });
          return chamados.take(50).toList();
        });
  }

  /// Busca contadores de chamados por prioridade
  ///
  /// Agrupa chamados ativos por nível de prioridade para
  /// exibição em dashboard e estatísticas.
  ///
  /// Returns: Map com contadores por prioridade:
  /// - 'critica': Prioridade 4
  /// - 'alta': Prioridade 3
  /// - 'media': Prioridade 2
  /// - 'baixa': Prioridade 1
  Future<Map<String, int>> getChamadosPorPrioridade() async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('foiArquivado', isEqualTo: false)
          .get();

      final contadores = {'critica': 0, 'alta': 0, 'media': 0, 'baixa': 0};

      for (var doc in snapshot.docs) {
        final prioridade = doc.data()['prioridade'] ?? 2;
        switch (prioridade) {
          case 4:
            contadores['critica'] = contadores['critica']! + 1;
            break;
          case 3:
            contadores['alta'] = contadores['alta']! + 1;
            break;
          case 2:
            contadores['media'] = contadores['media']! + 1;
            break;
          case 1:
            contadores['baixa'] = contadores['baixa']! + 1;
            break;
        }
      }

      return contadores;
    } catch (e) {
      _log('❌ Erro ao buscar chamados por prioridade: $e');
      return {'critica': 0, 'alta': 0, 'media': 0, 'baixa': 0};
    }
  }

  /// Arquiva um chamado movendo para coleção archived_tickets
  ///
  /// Processo:
  /// 1. Busca chamado original
  /// 2. Copia para archived_tickets com metadados adicionais
  /// 3. Deleta da coleção tickets
  ///

  // ========== EXCLUSÃO COMPLETA ==========

  /// Deleta completamente um chamado de TI e todos os dados relacionados
  ///
  /// Remove:
  /// - Documento do chamado no Firestore
}
