import 'package:cloud_firestore/cloud_firestore.dart';
import 'manutencao_enums.dart';

/// Modelo do Chamado de Manutenção
class ChamadoManutencao {
  final String id;
  final int? numero; // Número sequencial do chamado (#0001, #0002, etc)
  final String titulo;
  final String descricao;
  final String tipo = 'MANUTENCAO'; // Fixo para segregação

  // Criador do chamado
  final String criadorId;
  final String criadorNome;
  final TipoCriadorChamado criadorTipo;

  // Status
  final StatusChamadoManutencao status;
  final DateTime dataAbertura;
  final DateTime? dataFinalizacao;

  // Orçamento (OPCIONAL - pode ser null)
  final Orcamento? orcamento;

  // Fotos anexadas ao chamado
  final List<String> fotosUrls;

  // Validação Admin (obrigatória para todos, exceto admin criando sem orçamento)
  final bool precisaValidacao;
  final String? adminValidadorId;
  final String? adminValidadorNome;
  final DateTime? dataValidacao;
  final bool validado;

  // Aprovação Gerente (só se tem orçamento)
  final AprovacaoGerente? aprovacaoGerente;

  // Compra (só se tem orçamento aprovado)
  final Compra? compra;

  // Execução
  final Execucao? execucao;

  // Recusa (se executor recusou)
  final Recusa? recusa;

  // Auto-atribuição (se criador for executor)
  final bool autoAtribuicao;

  ChamadoManutencao({
    required this.id,
    this.numero,
    required this.titulo,
    required this.descricao,
    required this.criadorId,
    required this.criadorNome,
    required this.criadorTipo,
    required this.status,
    required this.dataAbertura,
    this.dataFinalizacao,
    this.orcamento,
    this.fotosUrls = const [],
    this.precisaValidacao = true,
    this.adminValidadorId,
    this.adminValidadorNome,
    this.dataValidacao,
    this.validado = false,
    this.aprovacaoGerente,
    this.compra,
    this.execucao,
    this.recusa,
    this.autoAtribuicao = false,
  });

  /// Getter para número formatado (#0001, #0002, etc)
  String get numeroFormatado {
    if (numero != null) {
      return '#${numero.toString().padLeft(4, '0')}';
    }
    return '#${id.substring(0, 8)}';
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'titulo': titulo,
      'descricao': descricao,
      'tipo': tipo,
      'criadorId': criadorId,
      'criadorNome': criadorNome,
      'criadorTipo': criadorTipo.value,
      'status': status.value,
      'dataAbertura': Timestamp.fromDate(dataAbertura),
      'dataFinalizacao': dataFinalizacao != null
          ? Timestamp.fromDate(dataFinalizacao!)
          : null,
      'orcamento': orcamento?.toMap(),
      'fotosUrls': fotosUrls,
      'precisaValidacao': precisaValidacao,
      'adminValidadorId': adminValidadorId,
      'adminValidadorNome': adminValidadorNome,
      'dataValidacao': dataValidacao != null
          ? Timestamp.fromDate(dataValidacao!)
          : null,
      'validado': validado,
      'aprovacaoGerente': aprovacaoGerente?.toMap(),
      'compra': compra?.toMap(),
      'execucao': execucao?.toMap(),
      'recusa': recusa?.toMap(),
      'autoAtribuicao': autoAtribuicao,
    };
  }

  /// Cria instância a partir de Map do Firestore
  factory ChamadoManutencao.fromMap(Map<String, dynamic> map, String id) {
    final numero = map['numero'] as int?;
    print('📖 DEBUG fromMap - ID: $id, numero lido: $numero');
    return ChamadoManutencao(
      id: id,
      numero: numero,
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      criadorId: map['criadorId'] ?? '',
      criadorNome: map['criadorNome'] ?? '',
      criadorTipo: TipoCriadorChamado.fromString(map['criadorTipo'] ?? 'user'),
      status: StatusChamadoManutencao.fromString(map['status'] ?? 'ABERTO'),
      dataAbertura: (map['dataAbertura'] as Timestamp).toDate(),
      dataFinalizacao: map['dataFinalizacao'] != null
          ? (map['dataFinalizacao'] as Timestamp).toDate()
          : null,
      orcamento: map['orcamento'] != null
          ? Orcamento.fromMap(map['orcamento'])
          : null,
      fotosUrls: List<String>.from(map['fotosUrls'] ?? []),
      precisaValidacao: map['precisaValidacao'] ?? true,
      adminValidadorId: map['adminValidadorId'],
      adminValidadorNome: map['adminValidadorNome'],
      dataValidacao: map['dataValidacao'] != null
          ? (map['dataValidacao'] as Timestamp).toDate()
          : null,
      validado: map['validado'] ?? false,
      aprovacaoGerente: map['aprovacaoGerente'] != null
          ? AprovacaoGerente.fromMap(map['aprovacaoGerente'])
          : null,
      compra: map['compra'] != null ? Compra.fromMap(map['compra']) : null,
      execucao: map['execucao'] != null
          ? Execucao.fromMap(map['execucao'])
          : null,
      recusa: map['recusa'] != null ? Recusa.fromMap(map['recusa']) : null,
      autoAtribuicao: map['autoAtribuicao'] ?? false,
    );
  }

  /// Cria cópia com modificações
  ChamadoManutencao copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? criadorId,
    String? criadorNome,
    TipoCriadorChamado? criadorTipo,
    StatusChamadoManutencao? status,
    DateTime? dataAbertura,
    DateTime? dataFinalizacao,
    Orcamento? orcamento,
    List<String>? fotosUrls,
    bool? precisaValidacao,
    String? adminValidadorId,
    String? adminValidadorNome,
    DateTime? dataValidacao,
    bool? validado,
    AprovacaoGerente? aprovacaoGerente,
    Compra? compra,
    Execucao? execucao,
    Recusa? recusa,
    bool? autoAtribuicao,
  }) {
    return ChamadoManutencao(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      criadorId: criadorId ?? this.criadorId,
      criadorNome: criadorNome ?? this.criadorNome,
      criadorTipo: criadorTipo ?? this.criadorTipo,
      status: status ?? this.status,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      dataFinalizacao: dataFinalizacao ?? this.dataFinalizacao,
      orcamento: orcamento ?? this.orcamento,
      fotosUrls: fotosUrls ?? this.fotosUrls,
      precisaValidacao: precisaValidacao ?? this.precisaValidacao,
      adminValidadorId: adminValidadorId ?? this.adminValidadorId,
      adminValidadorNome: adminValidadorNome ?? this.adminValidadorNome,
      dataValidacao: dataValidacao ?? this.dataValidacao,
      validado: validado ?? this.validado,
      aprovacaoGerente: aprovacaoGerente ?? this.aprovacaoGerente,
      compra: compra ?? this.compra,
      execucao: execucao ?? this.execucao,
      recusa: recusa ?? this.recusa,
      autoAtribuicao: autoAtribuicao ?? this.autoAtribuicao,
    );
  }
}

/// Modelo de Orçamento
class Orcamento {
  final String? arquivoUrl; // PDF ou DOCX no Firebase Storage
  final String? link; // Link externo opcional
  final double? valorEstimado;
  final List<String> itens; // Lista de materiais/ferramentas

  Orcamento({
    this.arquivoUrl,
    this.link,
    this.valorEstimado,
    required this.itens,
  });

  Map<String, dynamic> toMap() {
    return {
      'arquivoUrl': arquivoUrl,
      'link': link,
      'valorEstimado': valorEstimado,
      'itens': itens,
    };
  }

  factory Orcamento.fromMap(Map<String, dynamic> map) {
    return Orcamento(
      arquivoUrl: map['arquivoUrl'],
      link: map['link'],
      valorEstimado: map['valorEstimado']?.toDouble(),
      itens: List<String>.from(map['itens'] ?? []),
    );
  }
}

/// Modelo de Aprovação do Gerente
class AprovacaoGerente {
  final String gerenteId;
  final String gerenteNome;
  final bool aprovado;
  final DateTime dataAprovacao;
  final String? motivoRejeicao;

  AprovacaoGerente({
    required this.gerenteId,
    required this.gerenteNome,
    required this.aprovado,
    required this.dataAprovacao,
    this.motivoRejeicao,
  });

  Map<String, dynamic> toMap() {
    return {
      'gerenteId': gerenteId,
      'gerenteNome': gerenteNome,
      'aprovado': aprovado,
      'dataAprovacao': Timestamp.fromDate(dataAprovacao),
      'motivoRejeicao': motivoRejeicao,
    };
  }

  factory AprovacaoGerente.fromMap(Map<String, dynamic> map) {
    return AprovacaoGerente(
      gerenteId: map['gerenteId'] ?? '',
      gerenteNome: map['gerenteNome'] ?? '',
      aprovado: map['aprovado'] ?? false,
      dataAprovacao: (map['dataAprovacao'] as Timestamp).toDate(),
      motivoRejeicao: map['motivoRejeicao'],
    );
  }
}

/// Modelo de Compra de Materiais
class Compra {
  final StatusCompra statusCompra;
  final DateTime? dataChegadaMateriais;
  final List<String> notasFiscaisUrls;

  Compra({
    required this.statusCompra,
    this.dataChegadaMateriais,
    this.notasFiscaisUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'statusCompra': statusCompra.value,
      'dataChegadaMateriais': dataChegadaMateriais != null
          ? Timestamp.fromDate(dataChegadaMateriais!)
          : null,
      'notasFiscaisUrls': notasFiscaisUrls,
    };
  }

  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      statusCompra: StatusCompra.fromString(
        map['statusCompra'] ?? 'NAO_INICIADO',
      ),
      dataChegadaMateriais: map['dataChegadaMateriais'] != null
          ? (map['dataChegadaMateriais'] as Timestamp).toDate()
          : null,
      notasFiscaisUrls: List<String>.from(map['notasFiscaisUrls'] ?? []),
    );
  }
}

/// Modelo de Execução
class Execucao {
  final String executorId;
  final String executorNome;
  final DateTime dataAtribuicao;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? fotoComprovanteUrl; // Obrigatório para finalizar

  Execucao({
    required this.executorId,
    required this.executorNome,
    required this.dataAtribuicao,
    this.dataInicio,
    this.dataFim,
    this.fotoComprovanteUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'executorId': executorId,
      'executorNome': executorNome,
      'dataAtribuicao': Timestamp.fromDate(dataAtribuicao),
      'dataInicio': dataInicio != null ? Timestamp.fromDate(dataInicio!) : null,
      'dataFim': dataFim != null ? Timestamp.fromDate(dataFim!) : null,
      'fotoComprovanteUrl': fotoComprovanteUrl,
    };
  }

  factory Execucao.fromMap(Map<String, dynamic> map) {
    return Execucao(
      executorId: map['executorId'] ?? '',
      executorNome: map['executorNome'] ?? '',
      dataAtribuicao: (map['dataAtribuicao'] as Timestamp).toDate(),
      dataInicio: map['dataInicio'] != null
          ? (map['dataInicio'] as Timestamp).toDate()
          : null,
      dataFim: map['dataFim'] != null
          ? (map['dataFim'] as Timestamp).toDate()
          : null,
      fotoComprovanteUrl: map['fotoComprovanteUrl'],
    );
  }
}

/// Modelo de Recusa
class Recusa {
  final String executorId;
  final String executorNome;
  final DateTime dataRecusa;
  final String motivo; // Obrigatório

  Recusa({
    required this.executorId,
    required this.executorNome,
    required this.dataRecusa,
    required this.motivo,
  });

  Map<String, dynamic> toMap() {
    return {
      'executorId': executorId,
      'executorNome': executorNome,
      'dataRecusa': Timestamp.fromDate(dataRecusa),
      'motivo': motivo,
    };
  }

  factory Recusa.fromMap(Map<String, dynamic> map) {
    return Recusa(
      executorId: map['executorId'] ?? '',
      executorNome: map['executorNome'] ?? '',
      dataRecusa: (map['dataRecusa'] as Timestamp).toDate(),
      motivo: map['motivo'] ?? '',
    );
  }
}
