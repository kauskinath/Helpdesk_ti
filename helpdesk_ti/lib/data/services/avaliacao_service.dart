import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helpdesk_ti/features/ti/models/avaliacao.dart';

/// Serviço responsável por todas as operações relacionadas a Avaliações de Chamados
///
/// Este serviço gerencia o sistema de feedback dos usuários sobre chamados fechados:
/// - Criação de avaliações (nota de 1-5 + comentário opcional)
/// - Consulta de avaliações por chamado ou admin
/// - Estatísticas individuais e gerais
/// - Ranking de técnicos por avaliação
///
/// As avaliações são criadas quando um usuário avalia um chamado fechado,
/// permitindo monitorar a qualidade do atendimento da equipe de TI.
class AvaliacaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ CRIAÇÃO ============

  /// Cria uma nova avaliação para um chamado fechado
  ///
  /// Além de salvar a avaliação na coleção 'avaliacoes', também atualiza
  /// o documento do chamado para marcar que foi avaliado e registrar o ID
  /// da avaliação.
  ///
  /// [avaliacao] - Objeto Avaliacao com nota, comentário e dados do usuário/admin
  ///
  /// Throws: Exception se houver erro ao salvar no Firestore
  Future<void> criarAvaliacao(Avaliacao avaliacao) async {
    try {
      // Salvar avaliação na coleção dedicada
      await _firestore
          .collection('avaliacoes')
          .doc(avaliacao.id)
          .set(avaliacao.toMap());

      // Atualizar chamado para marcar que foi avaliado
      // Usar FieldValue.serverTimestamp() para evitar problemas de validação
      await _firestore.collection('tickets').doc(avaliacao.chamadoId).update({
        'avaliadoEm': FieldValue.serverTimestamp(),
        'avaliacaoId': avaliacao.id,
      });

      print(
        '✅ Avaliação ${avaliacao.id} criada para chamado ${avaliacao.chamadoId}',
      );
    } catch (e) {
      print('❌ Erro ao criar avaliação: $e');
      throw 'Erro ao criar avaliação: $e';
    }
  }

  // ============ CONSULTAS ============

  /// Busca a avaliação de um chamado específico
  ///
  /// Cada chamado pode ter apenas uma avaliação. Este método verifica
  /// se o chamado já foi avaliado pelo usuário.
  ///
  /// [chamadoId] - ID do chamado
  ///
  /// Retorna objeto Avaliacao se encontrado, null caso contrário
  Future<Avaliacao?> getAvaliacaoPorChamado(String chamadoId) async {
    try {
      final snapshot = await _firestore
          .collection('avaliacoes')
          .where('chamadoId', isEqualTo: chamadoId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return Avaliacao.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Erro ao buscar avaliação: $e');
      return null;
    }
  }

  /// Stream de avaliações recebidas por um técnico/admin específico
  ///
  /// Útil para que cada técnico possa ver suas próprias avaliações
  /// em tempo real e monitorar seu desempenho.
  ///
  /// [adminId] - ID do admin/técnico (Firebase Auth UID)
  ///
  /// Returns: Stream de lista de avaliações ordenadas por data (mais recentes primeiro)
  Stream<List<Avaliacao>> getAvaliacoesDoAdmin(String adminId) {
    return _firestore
        .collection('avaliacoes')
        .where('adminId', isEqualTo: adminId)
        .orderBy('dataAvaliacao', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Avaliacao.fromFirestore(doc)).toList(),
        );
  }

  /// Stream de todas as avaliações do sistema
  ///
  /// Usado por administradores para visualizar todas as avaliações
  /// e monitorar a qualidade geral do atendimento.
  ///
  /// Returns: Stream de lista completa de avaliações ordenadas por data
  Stream<List<Avaliacao>> getTodasAvaliacoes() {
    return _firestore
        .collection('avaliacoes')
        .orderBy('dataAvaliacao', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Avaliacao.fromFirestore(doc)).toList(),
        );
  }

  // ============ ESTATÍSTICAS ============

  /// Obtém estatísticas de avaliação de um técnico específico
  ///
  /// Calcula métricas detalhadas incluindo:
  /// - Total de avaliações recebidas
  /// - Nota média
  /// - Distribuição de notas (quantas de cada nota 1-5)
  /// - Últimas 5 avaliações com detalhes
  ///
  /// [adminId] - ID do admin/técnico
  ///
  /// Returns: Mapa com estatísticas completas do técnico
  Future<Map<String, dynamic>> getEstatisticasAvaliacoes(String adminId) async {
    try {
      final snapshot = await _firestore
          .collection('avaliacoes')
          .where('adminId', isEqualTo: adminId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'total': 0,
          'media': 0.0,
          'distribuicao': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final avaliacoes = snapshot.docs
          .map((doc) => Avaliacao.fromFirestore(doc))
          .toList();

      // Calcular média
      final somaNotas = avaliacoes.fold<int>(
        0,
        (accumulator, avaliacao) => accumulator + avaliacao.nota,
      );
      final media = somaNotas / avaliacoes.length;

      // Distribuição de notas (quantas pessoas deram cada nota)
      final distribuicao = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var avaliacao in avaliacoes) {
        distribuicao[avaliacao.nota] = (distribuicao[avaliacao.nota] ?? 0) + 1;
      }

      return {
        'total': avaliacoes.length,
        'media': double.parse(media.toStringAsFixed(2)),
        'distribuicao': distribuicao,
        'ultimasAvaliacoes': avaliacoes
            .take(5)
            .map(
              (a) => {
                'nota': a.nota,
                'emoji': a.emoji,
                'comentario': a.comentario ?? '',
                'data': a.dataAvaliacao.toString(),
              },
            )
            .toList(),
      };
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return {
        'total': 0,
        'media': 0.0,
        'distribuicao': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  /// Obtém estatísticas gerais de todas as avaliações do sistema
  ///
  /// Fornece visão completa incluindo:
  /// - Total de avaliações no sistema
  /// - Média geral de todas as avaliações
  /// - Distribuição global de notas
  /// - Ranking dos 10 melhores técnicos (por média)
  ///
  /// Usado no dashboard administrativo para monitorar qualidade geral
  /// e identificar os técnicos de melhor desempenho.
  ///
  /// Returns: Mapa com estatísticas gerais e ranking de técnicos
  Future<Map<String, dynamic>> getEstatisticasGeraisAvaliacoes() async {
    try {
      final snapshot = await _firestore.collection('avaliacoes').get();

      if (snapshot.docs.isEmpty) {
        return {
          'total': 0,
          'mediaGeral': 0.0,
          'distribuicao': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final avaliacoes = snapshot.docs
          .map((doc) => Avaliacao.fromFirestore(doc))
          .toList();

      // Calcular média geral
      final somaNotas = avaliacoes.fold<int>(
        0,
        (accumulator, avaliacao) => accumulator + avaliacao.nota,
      );
      final mediaGeral = somaNotas / avaliacoes.length;

      // Distribuição de notas
      final distribuicao = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var avaliacao in avaliacoes) {
        distribuicao[avaliacao.nota] = (distribuicao[avaliacao.nota] ?? 0) + 1;
      }

      // Ranking de técnicos por média
      final porAdmin = <String, List<Avaliacao>>{};
      for (var avaliacao in avaliacoes) {
        if (avaliacao.adminId != null) {
          porAdmin.putIfAbsent(avaliacao.adminId!, () => []).add(avaliacao);
        }
      }

      final ranking = porAdmin.entries.map((entry) {
        final adminAvaliacoes = entry.value;
        final somaAdmin = adminAvaliacoes.fold<int>(
          0,
          (accumulator, av) => accumulator + av.nota,
        );
        final mediaAdmin = somaAdmin / adminAvaliacoes.length;

        return {
          'adminId': entry.key,
          'adminNome': adminAvaliacoes.first.adminNome ?? 'Sem nome',
          'total': adminAvaliacoes.length,
          'media': double.parse(mediaAdmin.toStringAsFixed(2)),
        };
      }).toList();

      // Ordenar ranking por média (maior primeiro)
      ranking.sort(
        (a, b) => (b['media'] as double).compareTo(a['media'] as double),
      );

      return {
        'total': avaliacoes.length,
        'mediaGeral': double.parse(mediaGeral.toStringAsFixed(2)),
        'distribuicao': distribuicao,
        'rankingTecnicos': ranking.take(10).toList(),
      };
    } catch (e) {
      print('❌ Erro ao buscar estatísticas gerais: $e');
      return {
        'total': 0,
        'mediaGeral': 0.0,
        'distribuicao': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  // ============ UTILIDADES ============

  /// Deleta uma avaliação específica (usar com cuidado!)
  ///
  /// Remove a avaliação da coleção e limpa as referências no chamado.
  ///
  /// [avaliacaoId] - ID da avaliação a ser deletada
  Future<void> deletarAvaliacao(String avaliacaoId) async {
    try {
      // Buscar avaliação para pegar o chamadoId
      final doc = await _firestore
          .collection('avaliacoes')
          .doc(avaliacaoId)
          .get();

      if (doc.exists) {
        final avaliacao = Avaliacao.fromFirestore(doc);

        // Deletar avaliação
        await _firestore.collection('avaliacoes').doc(avaliacaoId).delete();

        // Limpar referência no chamado
        await _firestore.collection('tickets').doc(avaliacao.chamadoId).update({
          'avaliadoEm': FieldValue.delete(),
          'avaliacaoId': FieldValue.delete(),
        });

        print('✅ Avaliação $avaliacaoId deletada');
      }
    } catch (e) {
      throw 'Erro ao deletar avaliação: $e';
    }
  }
}
