import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de campo do formulário dinâmico
enum FieldType {
  text, // Campo de texto simples
  multiline, // Textarea
  select, // Dropdown/Select
  radio, // Opções de rádio
  checkbox, // Checkbox
  number, // Campo numérico
}

/// Campo estruturado do template
class TemplateField {
  final String id;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options; // Para select, radio, checkbox
  final String? placeholder;
  final String? defaultValue;

  TemplateField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.placeholder,
    this.defaultValue,
  });

  // Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'required': required,
      'options': options,
      'placeholder': placeholder,
      'defaultValue': defaultValue,
    };
  }

  // Criar do Map
  factory TemplateField.fromMap(Map<String, dynamic> map) {
    return TemplateField(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      type: FieldType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FieldType.text,
      ),
      required: map['required'] ?? false,
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : null,
      placeholder: map['placeholder'],
      defaultValue: map['defaultValue'],
    );
  }
}

class ChamadoTemplate {
  final String id;
  final String titulo;
  final String descricaoModelo;
  final String? setor;
  final String tipo; // 'Solicitação' ou 'Chamado'
  final int prioridade; // 1=Baixa, 2=Média, 3=Alta, 4=Crítica
  final List<String> tags;
  final bool ativo;
  final DateTime dataCriacao;
  final String? criadoPorId;
  final String? criadoPorNome;
  final List<TemplateField>? campos; // Campos estruturados do formulário

  ChamadoTemplate({
    required this.id,
    required this.titulo,
    required this.descricaoModelo,
    this.setor,
    required this.tipo,
    this.prioridade = 2,
    this.tags = const [],
    this.ativo = true,
    required this.dataCriacao,
    this.criadoPorId,
    this.criadoPorNome,
    this.campos,
  });

  // Criar do Firestore
  factory ChamadoTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChamadoTemplate(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descricaoModelo: data['descricaoModelo'] ?? '',
      setor: data['setor'],
      tipo: data['tipo'] ?? 'Chamado',
      prioridade: data['prioridade'] ?? 2,
      tags: List<String>.from(data['tags'] ?? []),
      ativo: data['ativo'] ?? true,
      dataCriacao:
          (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      criadoPorId: data['criadoPorId'],
      criadoPorNome: data['criadoPorNome'],
      campos: data['campos'] != null
          ? (data['campos'] as List)
                .map((c) => TemplateField.fromMap(c as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  // Converter para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricaoModelo': descricaoModelo,
      'setor': setor,
      'tipo': tipo,
      'prioridade': prioridade,
      'tags': tags,
      'ativo': ativo,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
      'criadoPorId': criadoPorId,
      'criadoPorNome': criadoPorNome,
      if (campos != null) 'campos': campos!.map((c) => c.toMap()).toList(),
    };
  }

  // Criar cópia com modificações
  ChamadoTemplate copyWith({
    String? id,
    String? titulo,
    String? descricaoModelo,
    String? setor,
    String? tipo,
    int? prioridade,
    List<String>? tags,
    bool? ativo,
    DateTime? dataCriacao,
    String? criadoPorId,
    String? criadoPorNome,
    List<TemplateField>? campos,
  }) {
    return ChamadoTemplate(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricaoModelo: descricaoModelo ?? this.descricaoModelo,
      setor: setor ?? this.setor,
      tipo: tipo ?? this.tipo,
      prioridade: prioridade ?? this.prioridade,
      tags: tags ?? this.tags,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      criadoPorId: criadoPorId ?? this.criadoPorId,
      criadoPorNome: criadoPorNome ?? this.criadoPorNome,
      campos: campos ?? this.campos,
    );
  }

  // Helper: Ícone baseado em tags
  String get iconeSugerido {
    if (tags.contains('rede') || tags.contains('internet')) return '🌐';
    if (tags.contains('impressora')) return '🖨️';
    if (tags.contains('software') || tags.contains('instalacao')) return '💻';
    if (tags.contains('hardware') || tags.contains('computador')) return '🖥️';
    if (tags.contains('email') || tags.contains('outlook')) return '📧';
    if (tags.contains('telefone') || tags.contains('ramal')) return '📞';
    if (tags.contains('acesso') || tags.contains('senha')) return '🔐';
    if (tags.contains('compra') || tags.contains('solicitacao')) return '🛒';
    return '📋';
  }

  // Helper: Cor baseada em prioridade
  String get corPrioridade {
    switch (prioridade) {
      case 1:
        return '#4CAF50'; // Verde (Baixa)
      case 2:
        return '#2196F3'; // Azul (Média)
      case 3:
        return '#FF9800'; // Laranja (Alta)
      case 4:
        return '#F44336'; // Vermelho (Crítica)
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  // Helper: Label da prioridade
  String get prioridadeLabel {
    switch (prioridade) {
      case 1:
        return 'Baixa';
      case 2:
        return 'Média';
      case 3:
        return 'Alta';
      case 4:
        return 'Crítica';
      default:
        return 'Média';
    }
  }
}
