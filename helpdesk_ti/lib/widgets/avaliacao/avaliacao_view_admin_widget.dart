import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/features/ti/models/avaliacao.dart';

/// Widget para visualização da avaliação pelo Admin TI
/// Mostra a avaliação do usuário após o chamado ser fechado
class AvaliacaoViewAdminWidget extends StatefulWidget {
  final Chamado chamado;

  const AvaliacaoViewAdminWidget({super.key, required this.chamado});

  @override
  State<AvaliacaoViewAdminWidget> createState() =>
      _AvaliacaoViewAdminWidgetState();
}

class _AvaliacaoViewAdminWidgetState extends State<AvaliacaoViewAdminWidget> {
  Avaliacao? _avaliacao;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarAvaliacao();
  }

  Future<void> _carregarAvaliacao() async {
    try {
      final firestoreService = context.read<FirestoreService>();
      final avaliacao = await firestoreService.getAvaliacaoPorChamado(
        widget.chamado.id,
      );
      if (mounted) {
        setState(() {
          _avaliacao = avaliacao;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  String _getEmojiParaNota(int nota) {
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
        return '⭐';
    }
  }

  String _getDescricaoParaNota(int nota) {
    switch (nota) {
      case 5:
        return 'Excelente!';
      case 4:
        return 'Muito Bom';
      case 3:
        return 'Bom';
      case 2:
        return 'Regular';
      case 1:
        return 'Ruim';
      default:
        return '';
    }
  }

  Color _getCorParaNota(int nota) {
    switch (nota) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Só mostrar se o chamado estiver fechado
    if (widget.chamado.status != 'Fechado') {
      return const SizedBox.shrink();
    }

    if (_carregando) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DS.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withAlpha(128), width: 2),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    // Se não há avaliação
    if (_avaliacao == null) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DS.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DS.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DS.textTertiary.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_border,
                color: DS.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avaliação do Usuário',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DS.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'O usuário ainda não avaliou este atendimento',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: DS.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mostra a avaliação existente
    final nota = _avaliacao!.nota;
    final cor = _getCorParaNota(nota);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: DS.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withAlpha(128), width: 2),
        boxShadow: [
          BoxShadow(
            color: cor.withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade400],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avaliação do Usuário',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DS.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por: ${_avaliacao!.usuarioNome}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: DS.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de nota
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getEmojiParaNota(nota),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDescricaoParaNota(nota),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: DS.border),
            const SizedBox(height: 16),

            // Estrelas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < nota ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                );
              }),
            ),

            // Comentário (se houver)
            if (_avaliacao!.comentario != null &&
                _avaliacao!.comentario!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DS.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DS.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.comment, size: 16, color: DS.textTertiary),
                        SizedBox(width: 6),
                        Text(
                          'Comentário do usuário:',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DS.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _avaliacao!.comentario!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: DS.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
