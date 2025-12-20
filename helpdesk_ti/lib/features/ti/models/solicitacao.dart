import 'package:cloud_firestore/cloud_firestore.dart';

class Solicitacao {
  final String id;
  final int? numero; // Número sequencial da solicitação (#0001, #0002, etc)
  final String titulo;
  final String descricao;
  final String itemSolicitado;
  final String justificativa;
  final double? custoEstimado;
  final String setor;
  final String usuarioId;
  final String usuarioNome;
  final String? managerId;
  final String? managerNome;
  final String status; // Pendente, Aprovado, Reprovado
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;
  final String? motivoRejeicao;
  final int prioridade;

  Solicitacao({
    required this.id,
    this.numero,
    required this.titulo,
    required this.descricao,
    required this.itemSolicitado,
    required this.justificativa,
    this.custoEstimado,
    required this.setor,
    required this.usuarioId,
    required this.usuarioNome,
    this.managerId,
    this.managerNome,
    required this.status,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.motivoRejeicao,
    required this.prioridade,
  });

  // Retorna o número formatado da solicitação (#S0001, #S0002, etc)
  String get numeroFormatado {
    if (numero != null) {
      return '#S${numero.toString().padLeft(4, '0')}';
    }
    return '#${id.substring(0, 8)}';
  }

  // Criar a partir de um documento do Firestore
  factory Solicitacao.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Solicitacao(
      id: doc.id,
      numero: data['numero'],
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      itemSolicitado: data['itemSolicitado'] ?? '',
      justificativa: data['justificativa'] ?? '',
      custoEstimado: data['custoEstimado']?.toDouble(),
      setor: data['setor'] ?? '',
      usuarioId: data['usuarioId'] ?? '',
      usuarioNome: data['usuarioNome'] ?? '',
      managerId: data['managerId'],
      managerNome: data['managerNome'],
      status: data['status'] ?? 'Pendente',
      dataCriacao: (data['dataCriacao'] as Timestamp).toDate(),
      dataAtualizacao: data['dataAtualizacao'] != null
          ? (data['dataAtualizacao'] as Timestamp).toDate()
          : null,
      motivoRejeicao: data['motivoRejeicao'],
      prioridade: data['prioridade'] ?? 2,
    );
  }

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'titulo': titulo,
      'descricao': descricao,
      'itemSolicitado': itemSolicitado,
      'justificativa': justificativa,
      'custoEstimado': custoEstimado,
      'setor': setor,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'managerId': managerId,
      'managerNome': managerNome,
      'status': status,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
      'dataAtualizacao': dataAtualizacao != null
          ? Timestamp.fromDate(dataAtualizacao!)
          : null,
      'motivoRejeicao': motivoRejeicao,
      'prioridade': prioridade,
    };
  }

  // Copiar com modificações
  Solicitacao copyWith({
    String? id,
    int? numero,
    String? titulo,
    String? descricao,
    String? itemSolicitado,
    String? justificativa,
    double? custoEstimado,
    String? setor,
    String? usuarioId,
    String? usuarioNome,
    String? managerId,
    String? managerNome,
    String? status,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    String? motivoRejeicao,
    int? prioridade,
  }) {
    return Solicitacao(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      itemSolicitado: itemSolicitado ?? this.itemSolicitado,
      justificativa: justificativa ?? this.justificativa,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      setor: setor ?? this.setor,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      managerId: managerId ?? this.managerId,
      managerNome: managerNome ?? this.managerNome,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      motivoRejeicao: motivoRejeicao ?? this.motivoRejeicao,
      prioridade: prioridade ?? this.prioridade,
    );
  }
}
