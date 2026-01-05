import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (comentarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma mensagem ainda',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicie a conversa enviando uma mensagem',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
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
            if (showDate) _buildDateSeparator(context, dataHora, isDarkMode),

            // Mensagem de sistema (centralizada)
            if (isSystemMessage)
              _buildSystemMessage(context, comentario, dataHora, isDarkMode)
            else
              // Mensagem normal (chat bubble)
              _buildChatBubble(
                context,
                comentario,
                dataHora,
                isAdmin,
                isMine,
                isDarkMode,
              ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(
    BuildContext context,
    DateTime date,
    bool isDarkMode,
  ) {
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
          Expanded(
            child: Divider(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withAlpha(15)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(
    BuildContext context,
    Map<String, dynamic> comentario,
    DateTime dataHora,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.amber.withAlpha(25) : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withAlpha(50)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    comentario['mensagem'] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(dataHora),
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
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
    bool isDarkMode,
  ) {
    // Cores das bolhas
    final Color bubbleColor;
    final Color textColor;
    final Color timeColor;

    if (isAdmin) {
      // Admin: bolha azul
      bubbleColor = isDarkMode
          ? const Color(0xFF1565C0)
          : const Color(0xFF2196F3);
      textColor = Colors.white;
      timeColor = Colors.white70;
    } else {
      // Usuário: bolha verde
      bubbleColor = isDarkMode
          ? const Color(0xFF2E7D32)
          : const Color(0xFF4CAF50);
      textColor = Colors.white;
      timeColor = Colors.white70;
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
            _buildAvatar(isAdmin, comentario['autorNome'] ?? 'A', isDarkMode),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor.withAlpha(220),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TI',
                              style: TextStyle(
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
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
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
                        style: TextStyle(fontSize: 11, color: timeColor),
                      ),
                      // Ícone de "enviado" para mensagens do usuário
                      if (!isAdmin) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 14, color: timeColor),
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
            _buildAvatar(isAdmin, comentario['autorNome'] ?? 'U', isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isAdmin, String nome, bool isDarkMode) {
    final initial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    final Color bgColor;
    final Color borderColor;

    if (isAdmin) {
      bgColor = isDarkMode
          ? const Color(0xFF1565C0).withAlpha(100)
          : const Color(0xFF2196F3).withAlpha(50);
      borderColor = const Color(0xFF2196F3);
    } else {
      bgColor = isDarkMode
          ? const Color(0xFF2E7D32).withAlpha(100)
          : const Color(0xFF4CAF50).withAlpha(50);
      borderColor = const Color(0xFF4CAF50);
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
            color: isAdmin ? const Color(0xFF2196F3) : const Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
