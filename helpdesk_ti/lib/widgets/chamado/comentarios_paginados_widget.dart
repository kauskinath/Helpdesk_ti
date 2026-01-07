import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/firestore_service.dart';
import 'chat_mensagens_widget.dart';

/// Widget que exibe comentários em tempo real (estilo chat)
///
/// Usa StreamBuilder para atualização automática quando novas mensagens chegam.
class ComentariosPaginadosWidget extends StatefulWidget {
  final String chamadoId;
  final FirestoreService firestoreService;

  const ComentariosPaginadosWidget({
    super.key,
    required this.chamadoId,
    required this.firestoreService,
  });

  @override
  State<ComentariosPaginadosWidget> createState() =>
      _ComentariosPaginadosWidgetState();
}

class _ComentariosPaginadosWidgetState
    extends State<ComentariosPaginadosWidget> {
  // ============ VARIÁVEIS DE ESTADO ============

  /// Stream subscription para cancelar quando widget for descartado
  StreamSubscription? _streamSubscription;

  /// Lista de comentários carregados
  List<Map<String, dynamic>> _comentarios = [];

  /// Se está carregando comentários no momento
  bool _carregando = false;

  /// Total de comentários no banco (para exibir contador)
  int _totalComentarios = 0;

  /// Se houve erro ao carregar
  String? _erroMensagem;

  // ============ LIFECYCLE ============

  @override
  void initState() {
    super.initState();
    // Usar stream para atualizações em tempo real
    _iniciarStreamComentarios();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// Inicia o stream de comentários em tempo real
  void _iniciarStreamComentarios() {
    setState(() {
      _carregando = true;
      _erroMensagem = null;
    });

    _streamSubscription = widget.firestoreService
        .getComentariosStream(widget.chamadoId)
        .listen(
          (comentarios) {
            if (mounted) {
              setState(() {
                _comentarios = comentarios;
                _totalComentarios = comentarios.length;
                _carregando = false;
              });
            }
          },
          onError: (e) {
            print('❌ Erro no stream de comentários: $e');
            if (mounted) {
              setState(() {
                _carregando = false;
                _erroMensagem = 'Erro ao carregar mensagens: $e';
              });
            }
          },
        );
  }

  /// Método público para recarregar comentários (mantido para compatibilidade)
  Future<void> recarregar() async {
    // Com stream, não precisa recarregar manualmente
    // Mas podemos forçar refresh se necessário
    _streamSubscription?.cancel();
    _iniciarStreamComentarios();
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    // Se está carregando a primeira página
    if (_carregando && _comentarios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Se houve erro, mostra mensagem neutra
    if (_erroMensagem != null && _comentarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Nenhum comentário disponível no momento',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Exibir comentários com atualização em tempo real
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ CONTADOR: "X mensagens"
        if (_totalComentarios > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              '$_totalComentarios mensagen${_totalComentarios == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),

        // ✅ LISTA DE COMENTÁRIOS (ChatMensagensWidget - estilo WhatsApp)
        ChatMensagensWidget(comentarios: _comentarios),

        // ✅ MENSAGEM: "Todas as mensagens carregadas" (com stream sempre mostra todas)
        if (_comentarios.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              '✓ Mensagens em tempo real',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
