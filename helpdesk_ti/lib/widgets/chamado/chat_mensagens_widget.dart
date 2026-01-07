import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';

/// Widget que exibe mensagens no estilo chat (WhatsApp)
/// Mensagens do admin à esquerda (bolha azul)
/// Mensagens do usuário à direita (bolha verde)
class ChatMensagensWidget extends StatelessWidget {
  final List<Map<String, dynamic>> comentarios;
  final String? currentUserId;

  const ChatMensagensWidget({
    super.key,
    required this.comentarios,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (comentarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: DS.textTertiary),
            SizedBox(height: 16),
            Text(
              'Nenhuma mensagem ainda',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: DS.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Inicie a conversa enviando uma mensagem',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: DS.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comentarios.length,
      itemBuilder: (context, index) {
        final comentario = comentarios[index];
        final isAdmin = comentario['autorRole'] == 'admin';
        final isMine = comentario['autorId'] == currentUserId;
        final dataHora = comentario['dataHora'] != null
            ? (comentario['dataHora'] as dynamic).toDate()
            : DateTime.now();

        // Verificar se é mensagem de sistema (mudança de status)
        final isSystemMessage =
            comentario['tipo'] == 'status_change' ||
            comentario['tipo'] == 'sistema';

        // Mostrar data se for primeiro item ou dia diferente do anterior
        bool showDate = false;
        if (index == 0) {
          showDate = true;
        } else {
          final prevComentario = comentarios[index - 1];
          final prevDataHora = prevComentario['dataHora'] != null
              ? (prevComentario['dataHora'] as dynamic).toDate()
              : DateTime.now();
          showDate = !_isSameDay(dataHora, prevDataHora);
        }

        return Column(
          children: [
            // Separador de data
            if (showDate) _buildDateSeparator(context, dataHora),

            // Mensagem de sistema (centralizada)
            if (isSystemMessage)
              _buildSystemMessage(context, comentario, dataHora)
            else
              // Mensagem normal (chat bubble)
              _buildChatBubble(context, comentario, dataHora, isAdmin, isMine),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    String dateText;
    if (_isSameDay(date, now)) {
      dateText = 'Hoje';
    } else if (_isSameDay(dateOnly, yesterday)) {
      dateText = 'Ontem';
    } else {
      dateText = DateFormat('dd/MM/yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: DS.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DS.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: DS.textSecondary,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: DS.border)),
        ],
      ),
    );
  }

  /// Mensagem de sistema - logs como mudança de status
  Widget _buildSystemMessage(
    BuildContext context,
    Map<String, dynamic> comentario,
    DateTime dataHora,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DS.warning.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DS.warning.withAlpha(77)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 14, color: DS.warning),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    comentario['mensagem'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: DS.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(dataHora),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: DS.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    BuildContext context,
    Map<String, dynamic> comentario,
    DateTime dataHora,
    bool isAdmin,
    bool isMine,
  ) {
    // Cores das bolhas - Design System
    final Color bubbleColor;

    if (isAdmin) {
      // Admin: bolha azul DS.action
      bubbleColor = DS.action;
    } else {
      // Usuário: bolha verde DS.success
      bubbleColor = DS.success;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        top: 4,
        left: isAdmin ? 12 : 48,
        right: isAdmin ? 48 : 12,
      ),
      child: Row(
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar do admin (à esquerda)
          if (isAdmin) ...[
            _buildAvatar(isAdmin, comentario['autorNome'] ?? 'A'),
            const SizedBox(width: 8),
          ],

          // Bolha da mensagem
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isAdmin ? 4 : 18),
                  bottomRight: Radius.circular(isAdmin ? 18 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: isAdmin
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  // Nome do autor (apenas para admin)
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            comentario['autorNome'] ?? 'Admin TI',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TI',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Mensagem
                  Text(
                    comentario['mensagem'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Horário
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isAdmin
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(dataHora),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                      // Ícone de "enviado" para mensagens do usuário
                      if (!isAdmin) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white.withAlpha(179),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Avatar do usuário (à direita)
          if (!isAdmin) ...[
            const SizedBox(width: 8),
            _buildAvatar(isAdmin, comentario['autorNome'] ?? 'U'),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isAdmin, String nome) {
    final initial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isAdmin) {
      bgColor = DS.action.withAlpha(38);
      borderColor = DS.action;
      textColor = DS.action;
    } else {
      bgColor = DS.success.withAlpha(38);
      borderColor = DS.success;
      textColor = DS.success;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Inter',
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
