import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../common/shimmer_loading.dart';

/// Timeline de comentários estilo WhatsApp para USUÁRIOS
///
/// Características:
/// - Mensagens do usuário: Alinhadas à DIREITA, fundo azul
/// - Mensagens do admin/TI: Alinhadas à ESQUERDA, fundo cinza
/// - Mensagens do sistema: Centralizadas, cinza claro
/// - Design limpo e moderno
class UserTimelineWidget extends StatefulWidget {
  final String chamadoId;
  final FirestoreService firestoreService;
  final AuthService authService;
  final Chamado chamado;

  const UserTimelineWidget({
    super.key,
    required this.chamadoId,
    required this.firestoreService,
    required this.authService,
    required this.chamado,
  });

  @override
  State<UserTimelineWidget> createState() => _UserTimelineWidgetState();
}

class _UserTimelineWidgetState extends State<UserTimelineWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.firestoreService.getComentariosStream(widget.chamadoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading.commentList();
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar comentários',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final comentarios = snapshot.data ?? [];

        if (comentarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma mensagem ainda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Envie uma mensagem para começar',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          reverse: false,
          itemCount: comentarios.length,
          itemBuilder: (context, index) {
            final comentario = comentarios[index];
            final isSystemMessage = comentario['isSystemMessage'] == true;
            final isCurrentUser =
                comentario['autorId'] == widget.authService.firebaseUser?.uid;
            final autorRole = comentario['autorRole'] ?? 'user';

            if (isSystemMessage) {
              return _buildSystemMessage(comentario);
            }

            return _buildChatBubble(
              context: context,
              comentario: comentario,
              isCurrentUser: isCurrentUser,
              autorRole: autorRole,
            );
          },
        );
      },
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> comentario) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  comentario['mensagem'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble({
    required BuildContext context,
    required Map<String, dynamic> comentario,
    required bool isCurrentUser,
    required String autorRole,
  }) {
    final mensagem = comentario['mensagem'] ?? '';
    final autorNome = comentario['autorNome'] ?? 'Desconhecido';
    final dataHora = comentario['dataHora'];
    final edited = comentario['edited'] == true;

    String dataFormatada = '';
    if (dataHora != null) {
      try {
        final DateTime date = dataHora is DateTime
            ? dataHora
            : (dataHora as dynamic).toDate();
        dataFormatada = DateFormat('HH:mm').format(date);
      } catch (e) {
        dataFormatada = '--:--';
      }
    }

    // Cores baseadas no papel
    Color bubbleColor;
    Color textColor;
    Alignment alignment;

    if (isCurrentUser) {
      // Mensagens do usuário: azul à direita
      bubbleColor = AppColors.primary;
      textColor = Colors.white;
      alignment = Alignment.centerRight;
    } else {
      // Mensagens de admin/TI: cinza à esquerda
      bubbleColor = Colors.grey[200]!;
      textColor = Colors.black87;
      alignment = Alignment.centerLeft;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do autor (apenas para mensagens de admin/TI)
                if (!isCurrentUser) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.support_agent,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        autorNome,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Mensagem
                Text(
                  mensagem,
                  style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                ),

                const SizedBox(height: 4),

                // Hora e indicador de edição
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (edited) ...[
                      Icon(
                        Icons.edit,
                        size: 10,
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      dataFormatada,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



