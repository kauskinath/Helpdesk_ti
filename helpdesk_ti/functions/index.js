const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Resetar senha de um usuário (chamada HTTPS)
 * Permite que admins alterem a senha de qualquer usuário
 */
exports.resetUserPassword = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário não autenticado'
    );
  }

  // Verificar se o usuário que está chamando é admin
  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  const callerData = callerDoc.data();
  
  if (!callerData || callerData.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Apenas admins podem resetar senhas'
    );
  }

  // Validar parâmetros
  const { uid, newPassword } = data;
  
  if (!uid || !newPassword) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'UID e nova senha são obrigatórios'
    );
  }

  if (newPassword.length < 6) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Senha deve ter no mínimo 6 caracteres'
    );
  }

  try {
    // Atualizar senha no Firebase Auth
    await admin.auth().updateUser(uid, {
      password: newPassword
    });

    console.log(`✅ Senha resetada para usuário: ${uid}`);

    return { 
      success: true, 
      message: 'Senha atualizada com sucesso' 
    };

  } catch (error) {
    console.error('❌ Erro ao resetar senha:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Erro ao resetar senha: ${error.message}`
    );
  }
});

/**
 * Notificar admins/TI quando um novo chamado é criado
 */
exports.notificarNovoChamado = functions.firestore
  .document('tickets/{ticketId}')
  .onCreate(async (snap, context) => {
    const chamado = snap.data();
    const ticketId = context.params.ticketId;

    console.log(`🎫 Novo chamado criado: #${chamado.numero}`);

    try {
      // Buscar todos os usuários admin e TI
      const usersSnapshot = await db.collection('users')
        .where('role', 'in', ['admin', 'ti'])
        .get();

      if (usersSnapshot.empty) {
        console.log('⚠️ Nenhum admin/TI encontrado');
        return null;
      }

      // Coletar tokens FCM
      const tokens = [];
      usersSnapshot.forEach(doc => {
        const user = doc.data();
        if (user.fcmToken) {
          tokens.push(user.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log('⚠️ Nenhum token FCM disponível');
        return null;
      }

      // Preparar mensagem
      const message = {
        notification: {
          title: `🆕 Novo Chamado #${String(chamado.numero).padStart(4, '0')}`,
          body: `${chamado.usuarioNome}: ${chamado.titulo}`,
        },
        data: {
          tipo: 'novo_chamado',
          chamadoId: ticketId,
          numero: String(chamado.numero),
          status: chamado.status,
          setor: chamado.setor || '',
        },
      };

      // Enviar para todos os tokens
      const sendPromises = tokens.map(token => {
        return messaging.send({ ...message, token })
          .then(() => {
            console.log(`✅ Notificação enviada para token: ${token.substring(0, 10)}...`);
          })
          .catch(error => {
            console.error(`❌ Erro ao enviar para token ${token.substring(0, 10)}...:`, error);
          });
      });

      await Promise.all(sendPromises);
      console.log(`📤 Notificações enviadas para ${tokens.length} dispositivos`);

      return null;
    } catch (error) {
      console.error('❌ Erro ao enviar notificações:', error);
      return null;
    }
  });

/**
 * Notificar usuário quando o status do chamado muda
 */
exports.notificarAtualizacaoChamado = functions.firestore
  .document('tickets/{ticketId}')
  .onUpdate(async (change, context) => {
    const antes = change.before.data();
    const depois = change.after.data();
    const ticketId = context.params.ticketId;

    // Verificar se o status mudou
    if (antes.status === depois.status) {
      console.log('ℹ️ Status não mudou, ignorando...');
      return null;
    }

    console.log(`🔄 Status mudou de "${antes.status}" para "${depois.status}"`);

    try {
      // Buscar token do usuário que criou o chamado
      const userDoc = await db.collection('users').doc(depois.usuarioId).get();
      
      if (!userDoc.exists) {
        console.log('⚠️ Usuário não encontrado');
        return null;
      }

      const user = userDoc.data();
      if (!user.fcmToken) {
        console.log('⚠️ Usuário não tem token FCM');
        return null;
      }

      // Definir mensagem baseada no novo status
      let titulo = '';
      let corpo = '';

      switch (depois.status) {
        case 'Em Andamento':
          titulo = `✅ Chamado #${String(depois.numero).padStart(4, '0')} Aceito`;
          corpo = `${depois.adminNome || 'TI'} aceitou seu chamado`;
          break;
        case 'Fechado':
          titulo = `✔️ Chamado #${String(depois.numero).padStart(4, '0')} Finalizado`;
          corpo = 'Seu chamado foi concluído. Por favor, avalie o atendimento.';
          break;
        case 'Rejeitado':
          titulo = `❌ Chamado #${String(depois.numero).padStart(4, '0')} Rejeitado`;
          corpo = depois.motivoRejeicao || 'Seu chamado foi rejeitado';
          break;
        default:
          titulo = `🔔 Atualização no Chamado #${String(depois.numero).padStart(4, '0')}`;
          corpo = `Status: ${depois.status}`;
      }

      // Enviar notificação
      const message = {
        notification: {
          title: titulo,
          body: corpo,
        },
        data: {
          tipo: 'chamado_atualizado',
          chamadoId: ticketId,
          numero: String(depois.numero),
          status: depois.status,
          statusAnterior: antes.status,
        },
        token: user.fcmToken,
      };

      await messaging.send(message);
      console.log(`✅ Notificação enviada para ${user.nome || depois.usuarioNome}`);

      return null;
    } catch (error) {
      console.error('❌ Erro ao enviar notificação:', error);
      return null;
    }
  });

/**
 * Notificar quando um novo comentário é adicionado
 */
exports.notificarNovoComentario = functions.firestore
  .document('comentarios/{comentarioId}')
  .onCreate(async (snap, context) => {
    const comentario = snap.data();
    
    console.log(`💬 Novo comentário no chamado ${comentario.chamadoId}`);

    try {
      // Buscar dados do chamado
      const chamadoDoc = await db.collection('tickets').doc(comentario.chamadoId).get();
      
      if (!chamadoDoc.exists) {
        console.log('⚠️ Chamado não encontrado');
        return null;
      }

      const chamado = chamadoDoc.data();
      
      // Buscar usuários a notificar (criador do chamado + admin responsável)
      const usuariosParaNotificar = [chamado.usuarioId];
      if (chamado.adminId && chamado.adminId !== comentario.usuarioId) {
        usuariosParaNotificar.push(chamado.adminId);
      }

      // Remover o autor do comentário da lista
      const usuariosFinais = usuariosParaNotificar.filter(
        uid => uid !== comentario.usuarioId
      );

      if (usuariosFinais.length === 0) {
        console.log('ℹ️ Nenhum usuário para notificar (autor do comentário)');
        return null;
      }

      // Buscar tokens
      const usersSnapshot = await db.collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', usuariosFinais)
        .get();

      const tokens = [];
      usersSnapshot.forEach(doc => {
        const user = doc.data();
        if (user.fcmToken) {
          tokens.push(user.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log('⚠️ Nenhum token FCM disponível');
        return null;
      }

      // Preparar mensagem
      const message = {
        notification: {
          title: `💬 Novo Comentário - #${String(chamado.numero).padStart(4, '0')}`,
          body: `${comentario.usuarioNome}: ${comentario.texto.substring(0, 50)}${comentario.texto.length > 50 ? '...' : ''}`,
        },
        data: {
          tipo: 'novo_comentario',
          chamadoId: comentario.chamadoId,
          numero: String(chamado.numero),
        },
      };

      // Enviar para todos os tokens
      const sendPromises = tokens.map(token => {
        return messaging.send({ ...message, token })
          .catch(error => {
            console.error(`❌ Erro ao enviar:`, error);
          });
      });

      await Promise.all(sendPromises);
      console.log(`📤 Notificações de comentário enviadas`);

      return null;
    } catch (error) {
      console.error('❌ Erro ao enviar notificações:', error);
      return null;
    }
  });

/**
 * Limpar tokens FCM inválidos
 */
exports.limparTokensInvalidos = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    console.log('🧹 Iniciando limpeza de tokens FCM inválidos...');
    
    try {
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '!=', null)
        .get();

      let tokensRemovidos = 0;

      const updatePromises = usersSnapshot.docs.map(async (doc) => {
        const token = doc.data().fcmToken;
        
        try {
          // Tentar enviar mensagem silenciosa para validar token
          await messaging.send({
            token: token,
            data: { tipo: 'ping' },
          });
        } catch (error) {
          // Se falhar, remover token
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            await doc.ref.update({
              fcmToken: admin.firestore.FieldValue.delete(),
              fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
            });
            tokensRemovidos++;
          }
        }
      });

      await Promise.all(updatePromises);
      console.log(`✅ Limpeza concluída: ${tokensRemovidos} tokens removidos`);
      
      return null;
    } catch (error) {
      console.error('❌ Erro na limpeza:', error);
      return null;
    }
  });
