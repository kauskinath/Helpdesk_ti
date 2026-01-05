import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/firestore_service.dart';
import 'chat_mensagens_widget.dart';

/// Widget que exibe comentários com paginação
///
/// Carrega comentários em páginas de 20 para melhorar performance.
/// Exibe botão "Carregar Mais" quando há mais comentários disponíveis.
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

  /// Lista de comentários carregados até agora
  List<Map<String, dynamic>> _comentarios = [];

  /// Último documento carregado (cursor para próxima página)
  DocumentSnapshot? _ultimoDocumento;

  /// Se há mais comentários para carregar
  bool _temMais = false;

  /// Se está carregando comentários no momento
  bool _carregando = false;

  /// Total de comentários no banco (para exibir contador)
  int _totalComentarios = 0;

  /// Se houve erro ao carregar
  String? _erroMensagem;

  /// Número de tentativas de retry automático
  int _tentativasRetry = 0;
  final int _maxTentativas = 3;

  // ============ LIFECYCLE ============

  @override
  void initState() {
    super.initState();
    // Carregar primeira página assim que o widget aparece
    _carregarPrimeirasPagina();
    _carregarTotal();
  }

  /// Método público para recarregar comentários (chamado após adicionar novo)
  Future<void> recarregar() async {
    await _carregarPrimeirasPagina();
    await _carregarTotal();
  }

  // ============ MÉTODOS DE CARREGAMENTO ============

  /// Carrega a primeira página de comentários (primeiros 20)
  Future<void> _carregarPrimeirasPagina() async {
    setState(() {
      _carregando = true;
      _erroMensagem = null;
    });

    try {
      // Chamar o serviço de paginação
      final resultado = await widget.firestoreService.getComentariosPaginados(
        widget.chamadoId,
        limite: 20, // Carregar 20 por vez
      );

      setState(() {
        // Extrair dados do resultado
        _comentarios = List<Map<String, dynamic>>.from(
          resultado['comentarios'] ?? [],
        );
        _ultimoDocumento = resultado['ultimoDocumento'];
        _temMais = resultado['temMais'] ?? false;
        _carregando = false;
        _tentativasRetry = 0; // Reset contador de tentativas
      });

      print('✅ Primeira página carregada: ${_comentarios.length} comentários');
    } catch (e) {
      print('❌ Erro ao carregar primeira página: $e');

      // Retry automático se não atingiu o máximo
      if (_tentativasRetry < _maxTentativas) {
        _tentativasRetry++;
        print('🔄 Tentativa $_tentativasRetry de $_maxTentativas...');

        // Aguardar um pouco antes de tentar novamente (2 segundos)
        await Future.delayed(const Duration(seconds: 2));

        // Tentar novamente
        if (mounted) {
          await _carregarPrimeirasPagina();
        }
      } else {
        // Após todas as tentativas, apenas para de carregar silenciosamente
        setState(() {
          _carregando = false;
          _erroMensagem = 'Erro ao carregar comentários: $e';
        });
        print('⚠️ Máximo de tentativas atingido');
      }
    }
  }

  /// Carrega a próxima página de comentários (mais 20)
  Future<void> _carregarProximaPagina() async {
    // Se já está carregando ou não tem mais, não faz nada
    if (_carregando || !_temMais) return;

    setState(() {
      _carregando = true;
      _erroMensagem = null;
    });

    try {
      // Chamar o serviço passando o último documento
      final resultado = await widget.firestoreService.getComentariosPaginados(
        widget.chamadoId,
        limite: 20,
        ultimoDocumento: _ultimoDocumento, // ← Continuar de onde parou
      );

      // ADICIONAR os novos comentários aos existentes
      final novosComentarios = List<Map<String, dynamic>>.from(
        resultado['comentarios'] ?? [],
      );

      setState(() {
        _comentarios.addAll(novosComentarios);

        // Atualizar cursor e flag
        _ultimoDocumento = resultado['ultimoDocumento'];
        _temMais = resultado['temMais'] ?? false;
        _carregando = false;
      });

      print(
        '✅ Próxima página carregada: +${novosComentarios.length} comentários',
      );
      print('📊 Total acumulado: ${_comentarios.length} comentários');
    } catch (e) {
      setState(() {
        _erroMensagem = 'Erro ao carregar mais comentários: $e';
        _carregando = false;
      });
      print('❌ Erro ao carregar próxima página: $e');
    }
  }

  /// Carrega o total de comentários (para exibir contador)
  Future<void> _carregarTotal() async {
    try {
      final total = await widget.firestoreService.getTotalComentarios(
        widget.chamadoId,
      );

      setState(() {
        _totalComentarios = total;
      });

      print('💬 Total de comentários no banco: $total');
    } catch (e) {
      print('⚠️ Erro ao carregar total de comentários: $e');
      // Não bloqueia a interface, apenas não mostra o contador
    }
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

    // Se houve erro após todas as tentativas, mostra mensagem neutra
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

    // Exibir comentários + botão "Carregar Mais"
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ CONTADOR: "Mostrando X de Y comentários"
        if (_totalComentarios > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Mostrando ${_comentarios.length} de $_totalComentarios comentários',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),

        // ✅ LISTA DE COMENTÁRIOS (ChatMensagensWidget - estilo WhatsApp)
        ChatMensagensWidget(comentarios: _comentarios),

        // ✅ BOTÃO "CARREGAR MAIS"
        if (_temMais) ...[
          const SizedBox(height: 16),

          // Se está carregando mais, mostra indicador
          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            // Senão, mostra o botão
            Center(
              child: OutlinedButton.icon(
                onPressed: _carregarProximaPagina,
                icon: const Icon(Icons.expand_more),
                label: const Text('Carregar Mais Comentários'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],

        // ✅ MENSAGEM: "Todos os comentários carregados"
        if (!_temMais && _comentarios.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              '✓ Todos os comentários carregados',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
