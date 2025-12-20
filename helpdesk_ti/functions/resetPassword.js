/**
 * Cloud Function para Resetar Senha de Usuário
 * 
 * Esta função permite que um admin resete a senha de um usuário
 * diretamente no Firebase Authentication.
 * 
 * Deploy:
 * firebase deploy --only functions:resetUserPassword
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Inicializar Admin SDK (apenas uma vez)
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Reseta a senha de um usuário
 * 
 * @param {Object} data - Dados da requisição
 * @param {string} data.userId - UID do usuário
 * @param {string} data.newPassword - Nova senha (mínimo 6 caracteres)
 * @param {Object} context - Contexto da chamada (autenticação)
 * @returns {Object} Resultado da operação
 */
exports.resetUserPassword = functions.https.onCall(async (data, context) => {
  // 1. Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário não autenticado'
    );
  }

  // 2. Verificar se é admin
  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore()
    .collection('users')
    .doc(callerUid)
    .get();

  const callerRole = callerDoc.data()?.role;
  
  if (callerRole !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Apenas administradores podem resetar senhas'
    );
  }

  // 3. Validar parâmetros
  const { userId, newPassword } = data;

  if (!userId || typeof userId !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userId é obrigatório'
    );
  }

  if (!newPassword || typeof newPassword !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'newPassword é obrigatória'
    );
  }

  if (newPassword.length < 6) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Senha deve ter no mínimo 6 caracteres'
    );
  }

  try {
    // 4. Atualizar senha no Firebase Auth
    await admin.auth().updateUser(userId, {
      password: newPassword
    });

    // 5. Remover senha temporária do Firestore
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .update({
        senhaTemporaria: admin.firestore.FieldValue.delete(),
        deveAlterarSenha: admin.firestore.FieldValue.delete(),
        senhaResetadaEm: admin.firestore.FieldValue.serverTimestamp(),
        senhaResetadaPor: callerUid
      });

    // 6. Log da operação
    console.log(`✅ Senha resetada para usuário ${userId} por admin ${callerUid}`);

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
 * Trigger: Quando senha temporária é criada, atualizar Firebase Auth
 * 
 * Executa automaticamente quando campo senhaTemporaria é adicionado
 */
exports.onSenhaTemporariaCreated = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const before = change.before.data();
    const after = change.after.data();

    // Se senha temporária foi adicionada
    if (!before.senhaTemporaria && after.senhaTemporaria) {
      console.log(`🔑 Senha temporária detectada para ${userId}`);

      try {
        // Atualizar senha no Firebase Auth
        await admin.auth().updateUser(userId, {
          password: after.senhaTemporaria
        });

        console.log(`✅ Senha atualizada no Firebase Auth para ${userId}`);

        // Remover campo senhaTemporaria (já foi aplicada)
        await change.after.ref.update({
          senhaTemporaria: admin.firestore.FieldValue.delete()
        });

      } catch (error) {
        console.error(`❌ Erro ao atualizar senha para ${userId}:`, error);
      }
    }
  });
