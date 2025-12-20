import 'package:cloud_firestore/cloud_firestore.dart';

/// Model de Avaliação de Chamado
class Avaliacao {
  final String id;
  final String chamadoId;
  final String usuarioId;
  final String usuarioNome;
  final int nota; // 1 a 5 estrelas
  final String? comentario;
  final DateTime dataAvaliacao;
  final String? adminId; // ID do técnico avaliado
  final String? adminNome;

  Avaliacao({
    required this.id,
    required this.chamadoId,
    required this.usuarioId,
    required this.usuarioNome,
    required this.nota,
    this.comentario,
    required this.dataAvaliacao,
    this.adminId,
    this.adminNome,
  });

  factory Avaliacao.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Avaliacao(
      id: doc.id,
      chamadoId: data['chamadoId'] ?? '',
      usuarioId: data['usuarioId'] ?? '',
      usuarioNome: data['usuarioNome'] ?? '',
      nota: data['nota'] ?? 0,
      comentario: data['comentario'],
      dataAvaliacao: (data['dataAvaliacao'] as Timestamp).toDate(),
      adminId: data['adminId'],
      adminNome: data['adminNome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chamadoId': chamadoId,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'nota': nota,
      'comentario': comentario,
      'dataAvaliacao': Timestamp.fromDate(dataAvaliacao),
      'adminId': adminId,
      'adminNome': adminNome,
    };
  }

  Avaliacao copyWith({
    String? id,
    String? chamadoId,
    String? usuarioId,
    String? usuarioNome,
    int? nota,
    String? comentario,
    DateTime? dataAvaliacao,
    String? adminId,
    String? adminNome,
  }) {
    return Avaliacao(
      id: id ?? this.id,
      chamadoId: chamadoId ?? this.chamadoId,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      nota: nota ?? this.nota,
      comentario: comentario ?? this.comentario,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
      adminId: adminId ?? this.adminId,
      adminNome: adminNome ?? this.adminNome,
    );
  }

  /// Retorna emoji baseado na nota
  String get emoji {
    switch (nota) {
      case 5:
        return '😍';
      case 4:
        return '😊';
      case 3:
        return '😐';
      case 2:
        return '😕';
      case 1:
        return '😞';
      default:
        return '❓';
    }
  }

  /// Retorna texto descritivo da nota
  String get descricao {
    switch (nota) {
      case 5:
        return 'Excelente';
      case 4:
        return 'Muito Bom';
      case 3:
        return 'Bom';
      case 2:
        return 'Regular';
      case 1:
        return 'Ruim';
      default:
        return 'Sem avaliação';
    }
  }
}
