import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../data/firestore_service.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/features/ti/models/solicitacao.dart';
import 'package:helpdesk_ti/features/ti/models/chamado_template.dart';
import '../widgets/new_ticket_form.dart';

class NewTicketScreen extends StatelessWidget {
  const NewTicketScreen({super.key});

  Future<void> _handleNewTicket(
    BuildContext context,
    String titulo,
    String setor,
    String tipo,
    String descricao,
    String? linkOuEspecificacao,
    int prioridade,
    List<XFile> imagens,
  ) async {
    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();

      final email = authService.userEmail;
      final uid = authService.firebaseUser?.uid;

      if (email == null || uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não autenticado')),
        );
        return;
      }

      // Se o tipo for "Solicitação", criar na coleção de solicitações para aprovação do gerente
      if (tipo == 'Solicitação') {
        final novaSolicitacao = Solicitacao(
          id: '', // Será gerado pelo Firestore
          titulo: titulo,
          descricao: descricao,
          itemSolicitado: titulo, // Usar título como item solicitado
          justificativa: descricao,
          custoEstimado: null, // Usuário pode não informar custo
          setor: setor,
          usuarioId: uid,
          usuarioNome: authService.userName ?? 'Usuário',
          managerId: null, // Será preenchido quando gerente aprovar
          managerNome: null,
          status: 'Pendente', // Status inicial para aprovação
          dataCriacao: DateTime.now(),
          dataAtualizacao: null,
          motivoRejeicao: null,
          prioridade: prioridade,
        );

        // Salvar na coleção 'solicitacoes'
        await firestoreService.criarSolicitacao(novaSolicitacao);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Solicitação enviada para aprovação do gerente!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );

          // Voltar para a home
          Navigator.pop(context);
        }
      } else {
        // Se for "Serviço", criar normalmente na coleção de tickets

        // Primeiro criar o chamado para ter o ID
        final novoChamado = Chamado(
          id: '', // Será gerado pelo Firestore
          titulo: titulo,
          setor: setor,
          tipo: tipo,
          descricao: descricao,
          status: 'Aberto',
          usuarioId: uid,
          usuarioNome: authService.userName ?? 'Usuário',
          dataCriacao: DateTime.now(),
          prioridade: prioridade,
          linkOuEspecificacao: linkOuEspecificacao,
          anexos: [], // Inicialmente vazio, será atualizado
        );

        // Salvar na coleção 'tickets'
        final chamadoId = await firestoreService.criarChamado(novoChamado);

        // Se houver imagens, fazer upload de todas no Firebase Storage
        List<String> anexosUrls = [];
        if (imagens.isNotEmpty) {
          for (var imagem in imagens) {
            try {
              final imageUrl = await firestoreService.uploadImage(
                chamadoId,
                imagem,
              );
              anexosUrls.add(imageUrl);
            } catch (e) {
              print('Erro ao fazer upload da imagem: $e');
            }
          }

          // Atualizar chamado com anexos
          if (anexosUrls.isNotEmpty) {
            await firestoreService.atualizarChamado(chamadoId, {
              'anexos': anexosUrls,
            });
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Chamado de serviço criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Voltar para a home
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao criar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Capturar template passado pela navegação (se houver)
    final template =
        ModalRoute.of(context)?.settings.arguments as ChamadoTemplate?;

    return NewTicketForm(
      template: template,
      onSubmit: (titulo, setor, tipo, descricao, link, prioridade, imagem) {
        _handleNewTicket(
          context,
          titulo,
          setor,
          tipo,
          descricao,
          link,
          prioridade,
          imagem,
        );
      },
    );
  }
}



