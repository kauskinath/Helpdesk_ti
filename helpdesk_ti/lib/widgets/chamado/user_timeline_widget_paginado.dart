import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import '../../data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../common/shimmer_loading.dart';

/// Timeline de comentários estilo WhatsApp com paginação
///
/// Carrega comentários em páginas de 20 para melhorar performance.
/// Mantém o design estilo WhatsApp do widget original.
class UserTimelineWidgetPaginado extends StatefulWidget {
  final String chamadoId;
  final FirestoreService firestoreService;
  final AuthService authService;
  final String usuarioId;

  const UserTimelineWidgetPaginado({
    super.key,
    required this.chamadoId,
    required this.firestoreService,
    required this.authService,
    required this.usuarioId,
  });

  @override
  State<UserTimelineWidgetPaginado> createState() =>
      _UserTimelineWidgetPaginadoState();
}

class _UserTimelineWidgetPaginadoState
    extends State<UserTimelineWidgetPaginado> {
  // ============ VARIÁVEIS DE ESTADO ============

  List<Map<String, dynamic>> _comentarios = [];
  DocumentSnapshot? _ultimoDocumento;
  bool _temMais = false;
  bool _carregando = false;
  int _totalComentarios = 0;
  String? _erroMensagem;

  // ============ LIFECYCLE ============

  @override
  void initState() {
    super.initState();
    _carregarPrimeirasPagina();
    _carregarTotal();
  }

  // ============ MÉTODOS DE CARREGAMENTO ============

  Future<void> _carregarPrimeirasPagina() async {
    setState(() {
      _carregando = true;
      _erroMensagem = null;
    });

    try {
      final resultado = await widget.firestoreService.getComentariosPaginados(
        widget.chamadoId,
        limite: 20,
      );

      setState(() {
        _comentarios = List<Map<String, dynamic>>.from(
          resultado['comentarios'] ?? [],
        );
        _ultimoDocumento = resultado['ultimoDocumento'];
        _temMais = resultado['temMais'] ?? false;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erroMensagem = 'Erro ao carregar comentários: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _carregarProximaPagina() async {
    if (_carregando || !_temMais) return;

    setState(() {
      _carregando = true;
    });

    try {
      final resultado = await widget.firestoreService.getComentariosPaginados(
        widget.chamadoId,
        limite: 20,
        ultimoDocumento: _ultimoDocumento,
      );

      setState(() {
        final novosComentarios = List<Map<String, dynamic>>.from(
          resultado['comentarios'] ?? [],
        );
        _comentarios.addAll(novosComentarios);
        _ultimoDocumento = resultado['ultimoDocumento'];
        _temMais = resultado['temMais'] ?? false;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _carregarTotal() async {
    try {
      final total = await widget.firestoreService.getTotalComentarios(
        widget.chamadoId,
      );
      setState(() {
        _totalComentarios = total;
      });
    } catch (e) {
      // Ignora erro no contador
    }
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    // Loading inicial
    if (_carregando && _comentarios.isEmpty) {
      return ShimmerLoading.commentList();
    }

    // Erro
    if (_erroMensagem != null && _comentarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _erroMensagem!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _carregarPrimeirasPagina,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    // Sem comentários
    if (_comentarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nenhum comentário ainda',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Lista de comentários
    return Column(
      children: [
        // Contador
        if (_totalComentarios > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Mostrando ${_comentarios.length} de $_totalComentarios mensagens',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Lista
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _comentarios.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final comentario = _comentarios[index];
            return _buildComentarioBubble(comentario);
          },
        ),

        // Botão "Carregar Mais"
        if (_temMais) ...[
          const SizedBox(height: 16),
          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Center(
              child: OutlinedButton.icon(
                onPressed: _carregarProximaPagina,
                icon: const Icon(Icons.expand_more),
                label: const Text('Carregar Mais Mensagens'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],

        // Mensagem final
        if (!_temMais && _comentarios.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              '✓ Todas as mensagens carregadas',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // ============ MÉTODOS DE BUILD ============

  Widget _buildComentarioBubble(Map<String, dynamic> comentario) {
    final autorId = comentario['autorId'] ?? comentario['usuarioId'] ?? '';
    final autorNome =
        comentario['autorNome'] ?? comentario['usuarioNome'] ?? 'Desconhecido';
    final mensagem = comentario['mensagem'] ?? comentario['texto'] ?? '';
    final tipo = comentario['tipo'] ?? 'comentario';
    final autorRole = comentario['autorRole'] ?? 'user';

    // Se for mensagem do sistema (mudança de status)
    if (tipo == 'status_change' || tipo == 'system') {
      return _buildSystemMessage(comentario);
    }

    // Verificar se é mensagem do usuário atual
    final isMinhaMensagem = autorId == widget.usuarioId;

    return Align(
      alignment: isMinhaMensagem ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isMinhaMensagem ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMinhaMensagem
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMinhaMensagem
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do autor (só se não for minha mensagem)
            if (!isMinhaMensagem) ...[
              Row(
                children: [
                  Text(
                    autorNome,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _getRoleColor(autorRole),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _getRoleBadge(autorRole),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Mensagem
            Text(
              mensagem,
              style: TextStyle(
                color: isMinhaMensagem ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Hora
            const SizedBox(height: 4),
            Text(
              _formatarDataHora(comentario['dataHora']),
              style: TextStyle(
                color: isMinhaMensagem ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> comentario) {
    final mensagem = comentario['mensagem'] ?? comentario['texto'] ?? '';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mensagem,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
      case 'ti':
        return Colors.red[700]!;
      case 'manager':
        return Colors.orange[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  Widget _getRoleBadge(String role) {
    String label;
    MaterialColor colorMaterial;

    switch (role) {
      case 'admin':
      case 'ti':
        label = 'TI';
        colorMaterial = Colors.red;
        break;
      case 'manager':
        label = 'Gestor';
        colorMaterial = Colors.orange;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorMaterial.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorMaterial, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorMaterial[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatarDataHora(dynamic timestamp) {
    if (timestamp == null) return 'Agora';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Data inválida';
      }

      final now = DateTime.now();
      final diff = now.difference(dateTime);

      // Menos de 1 minuto
      if (diff.inSeconds < 60) {
        return 'Agora';
      }

      // Menos de 1 hora
      if (diff.inMinutes < 60) {
        return 'Há ${diff.inMinutes}m';
      }

      // Menos de 24 horas
      if (diff.inHours < 24) {
        return 'Há ${diff.inHours}h';
      }

      // Hoje
      if (dateTime.day == now.day &&
          dateTime.month == now.month &&
          dateTime.year == now.year) {
        return 'Hoje às ${DateFormat('HH:mm').format(dateTime)}';
      }

      // Ontem
      final yesterday = now.subtract(const Duration(days: 1));
      if (dateTime.day == yesterday.day &&
          dateTime.month == yesterday.month &&
          dateTime.year == yesterday.year) {
        return 'Ontem às ${DateFormat('HH:mm').format(dateTime)}';
      }

      // Mais de 2 dias
      return DateFormat('dd/MM/yy HH:mm').format(dateTime);
    } catch (e) {
      return 'Data inválida';
    }
  }
}
