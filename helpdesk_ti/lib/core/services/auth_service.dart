import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:helpdesk_ti/core/services/notification_service.dart';

class AuthService extends ChangeNotifier {
  late final FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firestore;
  NotificationService? _notificationService;

  User? _currentUser;
  String? _userRole; // 'user', 'manager', 'admin'
  String? _userName;
  bool _isLoadingRole = false; // Flag para evitar loading duplicado

  // ========== LOGGING CONDICIONAL ==========
  void _log(String message) {
    if (kDebugMode) print(message);
  }

  AuthService() {
    _firebaseAuth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _initCurrentUser();
  }

  // Inicializar usuário atual se já estiver logado
  void _initCurrentUser() {
    _currentUser = _firebaseAuth.currentUser;
    if (_currentUser != null) {
      _loadUserRole().then((_) {
        notifyListeners();
      });
    }
  }

  // Getters
  User? get firebaseUser => _currentUser;
  String? get userEmail => _currentUser?.email;
  String? get userRole => _userRole;
  String? get userName => _userName;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _userRole == 'admin';
  bool get isManager => _userRole == 'manager';
  bool get isUser => _userRole == 'user';
  bool get isAdminManutencao => _userRole == 'admin_manutencao';
  bool get isExecutor => _userRole == 'executor';

  // Stream para monitorar autenticação
  // NOTA: Não chamamos notifyListeners() aqui para evitar race conditions
  // O login() e _initCurrentUser() já cuidam de notificar quando necessário
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      _currentUser = user;
      if (user != null) {
        // Só carregar role se ainda não foi carregada (evita duplicação)
        if (_userRole == null && !_isLoadingRole) {
          await _loadUserRole();
          notifyListeners();
        }
      } else {
        _userRole = null;
        _userName = null;
        notifyListeners();
      }
      return user;
    });
  }

  /// **Carregar role do usuário do Firestore**
  Future<void> _loadUserRole() async {
    if (_currentUser == null) {
      _log('⚠️ _loadUserRole: currentUser é null');
      return;
    }

    // Evitar loading duplicado
    if (_isLoadingRole) {
      _log('⏳ _loadUserRole: já está carregando...');
      return;
    }

    _isLoadingRole = true;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      _log('📄 Documento existe: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        _log('📊 Dados completos do Firestore: $data');

        _userRole = data?['role'] ?? 'user';
        _userName = data?['nome'] ?? data?['name'] ?? _currentUser!.email;

        _log('✅ ═══════════════════════════════════════');
        _log('✅ LOGIN AUTORIZADO');
        _log('✅ Email: ${_currentUser!.email}');
        _log('✅ UID: ${_currentUser!.uid}');
        _log('✅ Nome: $_userName');
        _log('✅ Role: $_userRole');
        _log('✅ Depto: ${data?['departamento'] ?? 'N/A'}');
        _log('✅ ═══════════════════════════════════════');
      } else {
        // EXCEÇÃO: Se for o email "administrador@helpdesk.com", criar documento admin automaticamente
        if (_currentUser!.email == 'administrador@helpdesk.com') {
          _log('🔧 CORREÇÃO DE EMERGÊNCIA: Criando documento admin...');

          await _firestore.collection('users').doc(_currentUser!.uid).set({
            'uid': _currentUser!.uid,
            'email': _currentUser!.email,
            'nome': 'Administrador',
            'role': 'admin',
            'departamento': 'TI',
            'dataCriacao': FieldValue.serverTimestamp(),
            'ativo': true,
          });

          _userRole = 'admin';
          _userName = 'Administrador';

          _log('✅ ═══════════════════════════════════════');
          _log('✅ ADMIN CRIADO AUTOMATICAMENTE');
          _log('✅ Email: ${_currentUser!.email}');
          _log('✅ UID: ${_currentUser!.uid}');
          _log('✅ Nome: $_userName');
          _log('✅ Role: $_userRole');
          _log('✅ ═══════════════════════════════════════');
        } else {
          // ❌ OUTROS USUÁRIOS SEM DOCUMENTO - NÃO AUTORIZADO
          _log(
            '❌ ERRO: Usuário ${_currentUser!.email} não tem documento no Firestore!',
          );
          _log('❌ Esse usuário não foi criado corretamente pelo admin.');

          final userEmail = _currentUser!.email;

          // Fazer logout imediatamente por segurança
          await _firebaseAuth.signOut();
          _currentUser = null;
          _userRole = null;
          _userName = null;

          throw Exception(
            '❌ USUÁRIO NÃO AUTORIZADO\n\n'
            'O usuário "$userEmail" existe no Firebase Authentication mas não tem perfil cadastrado.\n\n'
            '🔧 SOLUÇÃO:\n'
            '1. Entre no Firebase Console\n'
            '2. Delete este usuário em Authentication > Users\n'
            '3. Recrie-o usando o painel Admin do app\n\n'
            'OU entre em contato com o administrador.',
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _log('❌ Erro ao carregar role: $e');

      // Se é uma Exception que já lançamos, propagar
      if (e is Exception) {
        rethrow;
      }

      // Outros erros
      _userRole = null;
      _userName = null;
      notifyListeners();
      rethrow;
    } finally {
      _isLoadingRole = false;
    }
  }

  /// **LOGIN COM EMAIL E SENHA**
  Future<User?> login({required String email, required String password}) async {
    try {
      _log('🔐 Tentando login com: $email');

      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = result.user;
      _log('✅ Login bem-sucedido: ${result.user?.email}');

      // Carregar role do usuário - CRÍTICO: não pode falhar
      await _loadUserRole();

      // Inicializar notificações após login
      await initializeNotifications();

      notifyListeners();
      return _currentUser;
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro de autenticação';

      // Se senha errada, verifica se tem senha temporária
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _log('🔍 Verificando senha temporária...');

        try {
          // Buscar usuário pelo email no Firestore
          final querySnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userData = querySnapshot.docs.first.data();
            final senhaTemporaria = userData['senhaTemporaria'];

            // Se tem senha temporária E ela bate
            if (senhaTemporaria != null && senhaTemporaria == password) {
              _log(
                '✅ Senha temporária válida! Atualizando senha no Firebase...',
              );

              // Login com credencial admin para poder atualizar
              // Nota: Esta é uma solução temporária. Idealmente, isso seria feito por Cloud Function

              // Por enquanto, vamos apenas indicar que a senha temporária está correta
              // e mostrar mensagem para o usuário entrar em contato com admin
              throw 'SENHA_TEMPORARIA_DETECTADA||$email||$password';
            }
          }
        } catch (tempError) {
          // Se não for erro de senha temporária, re-throw
          if (tempError.toString().startsWith('SENHA_TEMPORARIA_DETECTADA')) {
            rethrow;
          }
          _log('⚠️ Erro ao verificar senha temporária: $tempError');
        }

        errorMsg = 'Senha incorreta.';
      } else if (e.code == 'user-not-found') {
        errorMsg = 'Usuário não encontrado.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Email inválido.';
      } else if (e.code == 'user-disabled') {
        errorMsg = 'Usuário desabilitado.';
      }

      _log('❌ Erro de login: $errorMsg (código: ${e.code})');
      throw errorMsg;
    } on TypeError catch (e) {
      // WORKAROUND: Ignorar erro de type cast do PigeonUserDetails (bug do Firebase Auth)
      _log('⚠️ Ignorando erro de type cast (PigeonUserDetails): $e');

      // Mesmo com erro de type cast, o login foi bem-sucedido
      _currentUser = _firebaseAuth.currentUser;

      if (_currentUser != null) {
        _log('✅ Login OK apesar do erro de type cast: ${_currentUser!.email}');

        // Carregar role - SE FALHAR, o login deve falhar também
        await _loadUserRole();

        // Inicializar notificações após login
        await initializeNotifications();

        notifyListeners();
        return _currentUser;
      }

      throw 'Erro ao fazer login. Tente novamente.';
    } catch (e) {
      _log('❌ Erro inesperado no login: $e');
      throw e.toString();
    }
  }

  /// **RESET DE SENHA**
  Future<void> resetPassword(String email) async {
    try {
      _log('📧 Enviando email de reset para: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _log('✅ Email de reset enviado com sucesso');
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro ao enviar email';

      if (e.code == 'user-not-found') {
        errorMsg = 'Email não encontrado.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Email inválido.';
      }

      _log('❌ Erro ao resetar senha: $errorMsg');
      throw errorMsg;
    } catch (e) {
      _log('❌ Erro inesperado ao resetar senha: $e');
      throw 'Erro ao resetar senha: $e';
    }
  }

  /// **LOGOUT**
  Future<void> logout() async {
    try {
      _log('🚪 Iniciando logout...');

      // Limpar dados locais PRIMEIRO para evitar problemas de stream
      final userId = _currentUser?.uid;
      _currentUser = null;
      _userRole = null;
      _userName = null;

      // Notificar listeners imediatamente sobre o logout
      notifyListeners();

      // Remover token FCM em background (não bloquear o logout)
      if (_notificationService != null && userId != null) {
        _notificationService!.removeUserToken(userId).catchError((e) {
          _log('⚠️ Erro ao remover token FCM (ignorando): $e');
        });
      }

      // Fazer signOut com timeout para evitar travamento
      await _firebaseAuth.signOut().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('⚠️ Timeout no signOut, continuando...');
        },
      );

      _log('✅ Logout realizado com sucesso');
    } catch (e) {
      _log('❌ Erro ao fazer logout: $e');
      // Mesmo com erro, limpar estado local
      _currentUser = null;
      _userRole = null;
      _userName = null;
      notifyListeners();
      // Não lançar exceção para evitar travamentos
    }
  }

  /// **Configurar serviço de notificações**
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// **Inicializar notificações após login bem-sucedido**
  Future<void> initializeNotifications() async {
    if (_notificationService == null || _currentUser == null) {
      _log('⚠️ NotificationService ou currentUser é null');
      return;
    }

    try {
      _log(
        '📱 Inicializando notificações para usuário: ${_currentUser!.email}',
      );

      // Inicializar serviço de notificações
      await _notificationService!.initialize();

      // Salvar token FCM no Firestore
      _log(
        '💾 Salvando token FCM para userId: ${_currentUser!.uid}, role: $_userRole',
      );
      await _notificationService!.saveUserToken(_currentUser!.uid);
      _log('✅ Token FCM salvo com sucesso!');

      // Inscrever em tópicos baseado no role
      if (isAdmin) {
        await _notificationService!.subscribeToTopic('ti_team');
        await _notificationService!.subscribeToTopic('admins');
        _log('✅ Inscrito em tópicos: ti_team, admins');
      } else if (isManager) {
        await _notificationService!.subscribeToTopic('managers');
        _log('✅ Inscrito em tópico: managers');
      }

      // CRÍTICO: Iniciar listener para receber notificações em tempo real
      _notificationService!.startNotificationListener(_currentUser!.uid);
      _log('✅ Listener de notificações iniciado');

      _log('✅ Notificações inicializadas com sucesso');
    } catch (e) {
      _log('❌ Erro ao inicializar notificações: $e');
      // Não falhar o login se notificações falharem
    }
  }

  /// **REGISTRAR NOVO USUÁRIO (apenas admin)**
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    required String departamento,
  }) async {
    if (!isAdmin) {
      throw 'Apenas admin pode criar usuários';
    }

    try {
      _log('👤 Criando novo usuário: $email com role=$role');

      // Criar usuário no Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Criar documento no Firestore com dados do usuário
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'departamento': departamento,
        'dataCriacao': FieldValue.serverTimestamp(),
        'ativo': true,
      });

      _log('✅ Usuário criado com sucesso: $email');
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro ao criar usuário';

      if (e.code == 'email-already-in-use') {
        errorMsg = 'Este email já está registrado.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'A senha é muito fraca.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Email inválido.';
      }

      _log('❌ Erro ao criar usuário: $errorMsg');
      throw errorMsg;
    } catch (e) {
      _log('❌ Erro inesperado: $e');
      throw 'Erro ao criar usuário: $e';
    }
  }

  /// **ATUALIZAR ROLE DO USUÁRIO (apenas admin)**
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    if (!isAdmin) {
      throw 'Apenas admin pode atualizar roles';
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      _log('✅ Role atualizado: $userId -> $newRole');
    } catch (e) {
      _log('❌ Erro ao atualizar role: $e');
      throw 'Erro ao atualizar role: $e';
    }
  }

  /// **ATUALIZAR DADOS DO USUÁRIO (apenas admin)**
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    if (!isAdmin) {
      throw 'Apenas admin pode atualizar usuários';
    }

    try {
      await _firestore.collection('users').doc(userId).update(data);
      _log('✅ Usuário atualizado: $userId');
    } catch (e) {
      _log('❌ Erro ao atualizar usuário: $e');
      throw 'Erro ao atualizar usuário: $e';
    }
  }

  /// **LISTAR TODOS OS USUÁRIOS (apenas admin)**
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    if (!isAdmin) {
      return Stream.error('Apenas admin pode listar usuários');
    }

    return _firestore
        .collection('users')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// **DELETAR USUÁRIO (apenas admin)**
  Future<void> deleteUser(String userId) async {
    if (!isAdmin) {
      throw 'Apenas admin pode deletar usuários';
    }

    try {
      // Soft delete - marca como inativo
      await _firestore.collection('users').doc(userId).update({'ativo': false});
      _log('✅ Usuário deletado: $userId');
    } catch (e) {
      _log('❌ Erro ao deletar usuário: $e');
      throw 'Erro ao deletar usuário: $e';
    }
  }
}
