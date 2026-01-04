import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import '../models/chamado_manutencao_model.dart';
import '../models/manutencao_enums.dart';
import '../services/manutencao_service.dart';

/// Widget de avaliação de chamado de manutenção para o app mobile
/// Exibe um card com estrelas (1-5) e campo de comentário opcional
class AvaliacaoManutencaoWidget extends StatefulWidget {
  final ChamadoManutencao chamado;
  final VoidCallback? onAvaliacaoEnviada;

  const AvaliacaoManutencaoWidget({
    super.key,
    required this.chamado,
    this.onAvaliacaoEnviada,
  });

  @override
  State<AvaliacaoManutencaoWidget> createState() =>
      _AvaliacaoManutencaoWidgetState();
}

class _AvaliacaoManutencaoWidgetState extends State<AvaliacaoManutencaoWidget>
    with SingleTickerProviderStateMixin {
  int _notaSelecionada = 0;
  final TextEditingController _comentarioController = TextEditingController();
  bool _isSubmitting = false;
  bool _isExpanded = false;
  Map<String, dynamic>? _avaliacaoExistente;
  bool _carregando = true;

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _carregarAvaliacaoExistente();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarAvaliacaoExistente() async {
    try {
      final manutencaoService = ManutencaoService();
      final avaliacao = await manutencaoService.getAvaliacaoManutencao(
        widget.chamado.id,
      );
      if (mounted) {
        setState(() {
          _avaliacaoExistente = avaliacao;
          if (avaliacao != null) {
            _notaSelecionada = avaliacao['nota'] ?? 0;
            _comentarioController.text = avaliacao['comentario'] ?? '';
          }
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
        return 'Toque nas estrelas para avaliar';
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

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _enviarAvaliacao() async {
    if (_notaSelecionada == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Por favor, selecione uma nota'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = context.read<AuthService>();
      final manutencaoService = ManutencaoService();

      await manutencaoService.criarAvaliacaoManutencao(
        avaliacaoId: _avaliacaoExistente?['id'] ?? const Uuid().v4(),
        chamadoId: widget.chamado.id,
        usuarioId: authService.firebaseUser?.uid ?? '',
        usuarioNome: authService.userName ?? 'Usuário',
        nota: _notaSelecionada,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
        executorId: widget.chamado.execucao?.executorId,
        executorNome: widget.chamado.execucao?.executorNome,
      );

      if (mounted) {
        // Atualizar avaliação existente no estado
        setState(() {
          _avaliacaoExistente = {
            'nota': _notaSelecionada,
            'comentario': _comentarioController.text.trim(),
          };
          _isExpanded = false;
        });
        _animationController.reverse();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _avaliacaoExistente != null
                      ? 'Avaliação atualizada! 🎉'
                      : 'Obrigado pela avaliação! 🎉',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        widget.onAvaliacaoEnviada?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao enviar avaliação: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Só mostrar se o chamado estiver finalizado
    if (widget.chamado.status != StatusChamadoManutencao.finalizado) {
      return const SizedBox.shrink();
    }

    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    if (_carregando) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _avaliacaoExistente != null
              ? _getCorParaNota(
                  _avaliacaoExistente!['nota'] ?? 0,
                ).withValues(alpha: 0.5)
              : Colors.amber.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header do card (sempre visível)
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, Colors.orange.shade400],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _avaliacaoExistente != null
                              ? 'Sua Avaliação'
                              : 'Avaliar Serviço',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_avaliacaoExistente != null)
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < (_avaliacaoExistente!['nota'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                _getEmojiParaNota(
                                  _avaliacaoExistente!['nota'] ?? 0,
                                ),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Como foi o serviço de manutenção?',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Ícone de expandir
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),

                  // Info do executor (se houver)
                  if (widget.chamado.execucao?.executorNome != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade400,
                            radius: 20,
                            child: const Icon(
                              Icons.engineering,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Executor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  widget.chamado.execucao!.executorNome,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Estrelas interativas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      final isSelected = starNumber <= _notaSelecionada;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _notaSelecionada = starNumber);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedScale(
                            scale: isSelected ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? Icons.star : Icons.star_border,
                              color: isSelected
                                  ? Colors.amber
                                  : (isDarkMode
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400),
                              size: 44,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Emoji e descrição
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(_notaSelecionada),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getEmojiParaNota(_notaSelecionada),
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getDescricaoParaNota(_notaSelecionada),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _notaSelecionada > 0
                                ? _getCorParaNota(_notaSelecionada)
                                : (isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de comentário
                  TextField(
                    controller: _comentarioController,
                    maxLines: 3,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Deixe um comentário (opcional)',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.white54
                            : Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botão de enviar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _enviarAvaliacao,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              _avaliacaoExistente != null
                                  ? Icons.update
                                  : Icons.send,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Enviando...'
                            : (_avaliacaoExistente != null
                                  ? 'Atualizar Avaliação'
                                  : 'Enviar Avaliação'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.amber.shade600
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
