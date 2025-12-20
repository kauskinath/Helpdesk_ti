import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> comentarios;

  const TimelineWidget({super.key, required this.comentarios});

  @override
  Widget build(BuildContext context) {
    if (comentarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Nenhuma atualização ainda',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    // Comentários já vêm ordenados do mais antigo para o mais recente
    // (descending: true no Firestore = mais recente primeiro, mas exibimos invertido)
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comentarios.length,
      itemBuilder: (context, index) {
        final comentario = comentarios[index];
        final isAdmin = comentario['autorRole'] == 'admin';
        final dataHora = comentario['dataHora'] != null
            ? (comentario['dataHora'] as dynamic).toDate()
            : DateTime.now();

        return Padding(
          padding: EdgeInsets.only(
            bottom: 12,
            left: isAdmin ? 0 : 40, // Usuário: mais espaço à esquerda
            right: isAdmin ? 40 : 0, // Admin: mais espaço à direita
          ),
          child: Row(
            mainAxisAlignment: isAdmin
                ? MainAxisAlignment
                      .start // Admin: esquerda
                : MainAxisAlignment.end, // Usuário: direita
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Se for admin, avatar à esquerda
              if (isAdmin) ...[_buildAvatar(isAdmin), const SizedBox(width: 8)],

              // Balão da mensagem (máximo 80% da largura)
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isAdmin
                            ? [
                                const Color(0xFF2196F3).withValues(alpha: 0.15),
                                const Color(0xFF2196F3).withValues(alpha: 0.08),
                              ]
                            : [
                                const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                const Color(0xFF4CAF50).withValues(alpha: 0.08),
                              ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isAdmin ? 4 : 16),
                        bottomRight: Radius.circular(isAdmin ? 16 : 4),
                      ),
                      border: Border.all(
                        color: isAdmin
                            ? const Color(0xFF2196F3).withValues(alpha: 0.3)
                            : const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isAdmin
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        // Nome e badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAdmin) ...[
                              Text(
                                comentario['autorNome'] ?? 'Admin',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'TI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Você',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                comentario['autorNome'] ?? 'Usuário',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Mensagem
                        Text(
                          comentario['mensagem'] ?? '',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 6),

                        // Data/hora
                        Text(
                          DateFormat('dd/MM HH:mm').format(dataHora),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Se for usuário, avatar à direita
              if (!isAdmin) ...[
                const SizedBox(width: 8),
                _buildAvatar(isAdmin),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(bool isAdmin) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isAdmin
            ? const Color(0xFF2196F3).withValues(alpha: 0.2)
            : const Color(0xFF4CAF50).withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isAdmin ? const Color(0xFF2196F3) : const Color(0xFF4CAF50),
          width: 2,
        ),
      ),
      child: Icon(
        isAdmin ? Icons.engineering : Icons.person,
        size: 16,
        color: isAdmin ? const Color(0xFF2196F3) : const Color(0xFF4CAF50),
      ),
    );
  }
}
