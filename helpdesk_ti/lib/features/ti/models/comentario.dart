import 'package:cloud_firestore/cloud_firestore.dart';

class Comentario {
  final String id;
  final String chamadoId;
  final String autorId;
  final String autorNome;
  final String autorRole; // 'admin' ou 'user'
  final String mensagem;
  final DateTime dataHora;
  final String? tipo; // 'atualizacao', 'comentario', 'mudanca_status'

  // ✅ NOVOS CAMPOS PARA FUNCIONALIDADEs AVANÇADAS
  final bool isSystemMessage; // Se foi gerado automaticamente
  final List<String> mentions; // IDs de usuários mencionados
  final List<String> attachments; // URLs de anexos no comentário
  final bool edited; // Se foi editado
  final DateTime? editedAt; // Timestamp da edição

  Comentario({
    required this.id,
    required this.chamadoId,
    required this.autorId,
    required this.autorNome,
    required this.autorRole,
    required this.mensagem,
    required this.dataHora,
    this.tipo,
    this.isSystemMessage = false,
    this.mentions = const [],
    this.attachments = const [],
    this.edited = false,
    this.editedAt,
  });

  // Converter de Firestore
  factory Comentario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comentario(
      id: doc.id,
      chamadoId: data['chamadoId'] ?? '',
      autorId: data['autorId'] ?? '',
      autorNome: data['autorNome'] ?? '',
      autorRole: data['autorRole'] ?? 'user',
      mensagem: data['mensagem'] ?? '',
      dataHora: (data['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipo: data['tipo'],
      isSystemMessage: data['isSystemMessage'] ?? false,
      mentions: List<String>.from(data['mentions'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
      edited: data['edited'] ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Converter para Firestore
  Map<String, dynamic> toMap() {
    return {
      'chamadoId': chamadoId,
      'autorId': autorId,
      'autorNome': autorNome,
      'autorRole': autorRole,
      'mensagem': mensagem,
      'dataHora': Timestamp.fromDate(dataHora),
      'tipo': tipo,
      'isSystemMessage': isSystemMessage,
      'mentions': mentions,
      'attachments': attachments,
      'edited': edited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }
}
