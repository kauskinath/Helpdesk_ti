class Chamado {
  final String id;
  final int? numero; // Número sequencial do chamado (#0001, #0002, etc)
  final String titulo;
  final String descricao;
  final String setor; // Setor solicitante (almoxarifado, atendimento, etc.)
  final String tipo; // 'Solicitação' ou 'Serviço'
  final String
  status; // 'Aberto', 'Em Andamento', 'Pendente Aprovação', 'Fechado', 'Rejeitado'
  final String usuarioId;
  final String usuarioNome;
  final String? adminId; // ID do TI responsável
  final String? adminNome;
  final String? linkOuEspecificacao; // Para Hardware/Compra
  final List<String> anexos; // URLs das imagens/arquivos
  final double? custoEstimado;
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;
  final DateTime? dataFechamento;
  final String? motivoRejeicao;
  final int prioridade; // 1=Baixa, 2=Média, 3=Alta, 4=Crítica

  // ✅ NOVOS CAMPOS PARA OTIMIZAÇÃO E AUDITORIA
  final DateTime? lastUpdated; // Timestamp da última atualização
  final int numeroComentarios; // Contador de comentários
  final bool temAnexos; // Flag para saber se tem anexos
  final String? ultimoComentarioPor; // Nome do último comentarista
  final DateTime? ultimoComentarioEm; // Data do último comentário
  final bool foiArquivado; // Flag se está arquivado
  final List<String> tags; // Tags para busca e filtros

  Chamado({
    required this.id,
    this.numero,
    required this.titulo,
    required this.descricao,
    required this.setor,
    required this.tipo,
    required this.status,
    required this.usuarioId,
    required this.usuarioNome,
    this.adminId,
    this.adminNome,
    this.linkOuEspecificacao,
    this.anexos = const [],
    this.custoEstimado,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.dataFechamento,
    this.motivoRejeicao,
    this.prioridade = 2,
    this.lastUpdated,
    this.numeroComentarios = 0,
    this.temAnexos = false,
    this.ultimoComentarioPor,
    this.ultimoComentarioEm,
    this.foiArquivado = false,
    this.tags = const [],
  });

  // Retorna o número formatado do chamado (#0001, #0002, etc)
  String get numeroFormatado {
    if (numero != null) {
      return '#${numero.toString().padLeft(4, '0')}';
    }
    // Fallback: usar primeiros 8 chars do ID
    return '#${id.substring(0, 8)}';
  }

  // Converter de JSON (Firestore)
  factory Chamado.fromMap(Map<String, dynamic> map, String documentId) {
    return Chamado(
      id: documentId,
      numero: map['numero'],
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      setor: map['setor'] ?? 'Não especificado',
      tipo: map['tipo'] ?? 'Solicitação',
      status: map['status'] ?? 'Aberto',
      usuarioId: map['usuarioId'] ?? '',
      usuarioNome: map['usuarioNome'] ?? '',
      adminId: map['adminId'],
      adminNome: map['adminNome'],
      linkOuEspecificacao: map['linkOuEspecificacao'],
      anexos: List<String>.from(map['anexos'] ?? []),
      custoEstimado: (map['custoEstimado'] as num?)?.toDouble(),
      dataCriacao: (map['dataCriacao'] as dynamic)?.toDate() ?? DateTime.now(),
      dataAtualizacao: (map['dataAtualizacao'] as dynamic)?.toDate(),
      dataFechamento: (map['dataFechamento'] as dynamic)?.toDate(),
      motivoRejeicao: map['motivoRejeicao'],
      prioridade: map['prioridade'] ?? 2,
      lastUpdated: (map['lastUpdated'] as dynamic)?.toDate(),
      numeroComentarios: map['numeroComentarios'] ?? 0,
      temAnexos: map['temAnexos'] ?? false,
      ultimoComentarioPor: map['ultimoComentarioPor'],
      ultimoComentarioEm: (map['ultimoComentarioEm'] as dynamic)?.toDate(),
      foiArquivado: map['foiArquivado'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Converter para JSON (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'titulo': titulo,
      'descricao': descricao,
      'setor': setor,
      'tipo': tipo,
      'status': status,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'adminId': adminId,
      'adminNome': adminNome,
      'linkOuEspecificacao': linkOuEspecificacao,
      'anexos': anexos,
      'custoEstimado': custoEstimado,
      'dataCriacao': dataCriacao,
      'dataAtualizacao': dataAtualizacao,
      'dataFechamento': dataFechamento,
      'motivoRejeicao': motivoRejeicao,
      'prioridade': prioridade,
      'lastUpdated': lastUpdated,
      'numeroComentarios': numeroComentarios,
      'temAnexos': temAnexos,
      'ultimoComentarioPor': ultimoComentarioPor,
      'ultimoComentarioEm': ultimoComentarioEm,
      'foiArquivado': foiArquivado,
      'tags': tags,
    };
  }
}
