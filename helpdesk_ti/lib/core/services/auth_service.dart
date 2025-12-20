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
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      _currentUser = user;
      if (user != null) {
        await _loadUserRole();
      } else {
        _userRole = null;
        _userName = null;
      }
      notifyListeners();
      return user;
    });
  }

  /// **Carregar role do usuário do Firestore**
  Future<void> _loadUserRole() async {
    if (_currentUser == null) {
      print('⚠️ _loadUserRole: currentUser é null');
      return;
    }

    // Role loading - log removido para performance

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      print('📄 Documento existe: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        print('📊 Dados completos do Firestore: $data');

        _userRole = data?['role'] ?? 'user';
        _userName = data?['nome'] ?? data?['name'] ?? _currentUser!.email;

        print('✅ ═══════════════════════════════════════');
        print('✅ LOGIN AUTORIZADO');
        print('✅ Email: ${_currentUser!.email}');
        print('✅ UID: ${_currentUser!.uid}');
        print('✅ Nome: $_userName');
        print('✅ Role: $_userRole');
        print('✅ Depto: ${data?['departamento'] ?? 'N/A'}');
        print('✅ ═══════════════════════════════════════');
      } else {
        // EXCEÇÃO: Se for o email "administrador@helpdesk.com", criar documento admin automaticamente
        if (_currentUser!.email == 'administrador@helpdesk.com') {
          print('🔧 CORREÇÃO DE EMERGÊNCIA: Criando documento admin...');

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

          print('✅ ═══════════════════════════════════════');
          print('✅ ADMIN CRIADO AUTOMATICAMENTE');
          print('✅ Email: ${_currentUser!.email}');
          print('✅ UID: ${_currentUser!.uid}');
          print('✅ Nome: $_userName');
          print('✅ Role: $_userRole');
          print('✅ ═══════════════════════════════════════');
        } else {
          // ❌ OUTROS USUÁRIOS SEM DOCUMENTO - NÃO AUTORIZADO
          print(
            '❌ ERRO: Usuário ${_currentUser!.email} não tem documento no Firestore!',
          );
          print('❌ Esse usuário não foi criado corretamente pelo admin.');

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
      print('❌ Erro ao carregar role: $e');

      // Se é uma Exception que já lançamos, propagar
      if (e is Exception) {
        rethrow;
      }

      // Outros erros
      _userRole = null;
      _userName = null;
      notifyListeners();
      rethrow;
    }
  }

  /// **LOGIN COM EMAIL E SENHA**
  Future<User?> login({required String email, required String password}) async {
    try {
      print('🔐 Tentando login com: $email');

      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = result.user;
      print('✅ Login bem-sucedido: ${result.user?.email}');

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
        print('🔍 Verificando senha temporária...');

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
              print(
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
          print('⚠️ Erro ao verificar senha temporária: $tempError');
        }

        errorMsg = 'Senha incorreta.';
      } else if (e.code == 'user-not-found') {
        errorMsg = 'Usuário não encontrado.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Email inválido.';
      } else if (e.code == 'user-disabled') {
        errorMsg = 'Usuário desabilitado.';
      }

      print('❌ Erro de login: $errorMsg (código: ${e.code})');
      throw errorMsg;
    } on TypeError catch (e) {
      // WORKAROUND: Ignorar erro de type cast do PigeonUserDetails (bug do Firebase Auth)
      print('⚠️ Ignorando erro de type cast (PigeonUserDetails): $e');

      // Mesmo com erro de type cast, o login foi bem-sucedido
      _currentUser = _firebaseAuth.currentUser;

      if (_currentUser != null) {
        print('✅ Login OK apesar do erro de type cast: ${_currentUser!.email}');

        // Carregar role - SE FALHAR, o login deve falhar também
        await _loadUserRole();

        // Inicializar notificações após login
        await initializeNotifications();

        notifyListeners();
        return _currentUser;
      }

      throw 'Erro ao fazer login. Tente novamente.';
    } catch (e) {
      print('❌ Erro inesperado no login: $e');
      throw e.toString();
    }
  }

  /// **RESET DE SENHA**
  Future<void> resetPassword(String email) async {
    try {
      print('📧 Enviando email de reset para: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('✅ Email de reset enviado com sucesso');
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro ao enviar email';

      if (e.code == 'user-not-found') {
        errorMsg = 'Email não encontrado.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Email inválido.';
      }

      print('❌ Erro ao resetar senha: $errorMsg');
      throw errorMsg;
    } catch (e) {
      print('❌ Erro inesperado ao resetar senha: $e');
      throw 'Erro ao resetar senha: $e';
    }
  }

  /// **LOGOUT**
  Future<void> logout() async {
    try {
      // Remover token FCM antes de deslogar
      if (_notificationService != null && _currentUser != null) {
        await _notificationService!.removeUserToken(_currentUser!.uid);
      }

      await _firebaseAuth.signOut();
      _currentUser = null;
      _userRole = null;
      _userName = null;
      notifyListeners();
      print('✅ Logout realizado com sucesso');
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
      throw 'Erro ao fazer logout: $e';
    }
  }

  /// **Configurar serviço de notificações**
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// **Inicializar notificações após login bem-sucedido**
  Future<void> initializeNotifications() async {
    if (_notificationService == null || _currentUser == null) {
      print('⚠️ NotificationService ou currentUser é null');
      return;
    }

    try {
      print(
        '📱 Inicializando notificações para usuário: ${_currentUser!.email}',
      );

      // Inicializar serviço de notificações
      await _notificationService!.initialize();

      // Salvar token FCM no Firestore
      print(
        '💾 Salvando token FCM para userId: ${_currentUser!.uid}, role: $_userRole',
      );
      await _notificationService!.saveUserToken(_currentUser!.uid);
      print('✅ Token FCM salvo com sucesso!');

      // Inscrever em tópicos baseado no role
      if (isAdmin) {
        await _notificationService!.subscribeToTopic('ti_team');
        await _notificationService!.subscribeToTopic('admins');
        print('✅ Inscrito em tópicos: ti_team, admins');
      } else if (isManager) {
        await _notificationService!.subscribeToTopic('managers');
        print('✅ Inscrito em tópico: managers');
      }

      // CRÍTICO: Iniciar listener para receber notificações em tempo real
      _notificationService!.startNotificationListener(_currentUser!.uid);
      print('✅ Listener de notificações iniciado');

      print('✅ Notificações inicializadas com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar notificações: $e');
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
      print('👤 Criando novo usuário: $email com role=$role');

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

      print('✅ Usuário criado com sucesso: $email');
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro ao criar usuário';

      if (e.code == 'email-already-in-use') {
        errorMsg = 'Este email já está registrado.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'A senha é muito fraca.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Email inválido.';
      }

      print('❌ Erro ao criar usuário: $errorMsg');
      throw errorMsg;
    } catch (e) {
      print('❌ Erro inesperado: $e');
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
      print('✅ Role atualizado: $userId -> $newRole');
    } catch (e) {
      print('❌ Erro ao atualizar role: $e');
      throw 'Erro ao atualizar role: $e';
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
      print('✅ Usuário deletado: $userId');
    } catch (e) {
      print('❌ Erro ao deletar usuário: $e');
      throw 'Erro ao deletar usuário: $e';
    }
  }
}

