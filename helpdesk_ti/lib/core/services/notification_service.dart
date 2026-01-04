import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'navigation_service.dart';
import 'package:helpdesk_ti/firebase_options.dart';

/// Serviço de Notificações Push usando Firebase Cloud Messaging
/// SOLUÇÃO GRATUITA: Notificações via TÓPICOS FCM (sem Cloud Functions, sem HTTP API)
///
/// **MELHORIAS v3.0:**
/// - ✅ Singleton pattern para evitar múltiplas instâncias
/// - ✅ Navegação funcional com NavigationService
/// - ✅ Feedback visual em foreground (overlay animado)
/// - ✅ Auto-atualização de token completa
/// - ✅ Background handler funcional
/// - ✅ Prevenção de duplicação
/// - ✅ Badges com contadores
/// - ✅ Categorização por tipo (cores/ícones)
/// - ✅ Logs condicionais (apenas em debug)
class NotificationService {
  // ========== SINGLETON PATTERN ==========
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ========== PROPRIEDADES ==========
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? _currentUserId; // Armazenar userId para auto-atualização de token
  final Set<String> _processedNotificationIds = {}; // Prevenir duplicação
  bool _isInitialized = false; // Evitar inicialização duplicada

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // ========== LOGGING CONDICIONAL ==========
  void _log(String message) {
    if (kDebugMode) print(message);
  }

  /// Inicializar o serviço de notificações
  Future<void> initialize() async {
    // Evitar inicialização duplicada
    if (_isInitialized) {
      _log('ℹ️ NotificationService já inicializado');
      return;
    }

    try {
      // Solicitar permissões
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('⚠️ Permissões de notificação negadas');
        return;
      }

      _log(
        '✅ Permissões de notificação concedidas: ${settings.authorizationStatus}',
      );

      // Na web, não deletamos o token (causa erro)
      if (!kIsWeb) {
        // Forçar refresh do token para garantir que seja válido
        // Isso resolve problemas de tokens expirados/inválidos
        try {
          await _messaging.deleteToken();
          _log('🔄 Token antigo deletado, gerando novo...');
        } catch (e) {
          _log('⚠️ Não foi possível deletar token antigo: $e');
        }
      }

      // Obter novo token FCM (sempre válido)
      try {
        _fcmToken = await _messaging.getToken(
          vapidKey: kIsWeb
              ? 'BLPInQvHO7wZNJxgjy-qT5JXtJnPxZVuLmGMzuKmH6QIsMNCIkKIz8R4YQpY1dIqjzM3mXVxyA9svxj3RmWQFho'
              : null,
        );
        if (_fcmToken != null) {
          _log('✅ Token FCM gerado: ${_fcmToken?.substring(0, 20)}...');
        } else {
          _log(
            '⚠️ Token FCM é null (pode ser normal na web sem VAPID key configurada)',
          );
        }
      } catch (e) {
        _log('⚠️ Não foi possível obter token FCM: $e');
        // Na web, se falhar, continuar sem notificações push
        if (kIsWeb) {
          _log('📱 Continuando sem notificações push na web');
          return;
        }
      }

      // Inicializar notificações locais (apenas em plataformas móveis)
      if (!kIsWeb) {
        await _initializeLocalNotifications();
      }

      // Configurar handlers de mensagens
      _setupMessageHandlers();

      // Atualizar token quando mudar (MELHORADO)
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        _log(
          '🔄 Token FCM atualizado automaticamente: ${newToken.substring(0, 20)}...',
        );

        // Auto-atualizar no Firestore se temos userId
        if (_currentUserId != null) {
          await _updateUserToken(newToken, _currentUserId!);
        }
      });

      _isInitialized = true;
      _log('✅ NotificationService inicializado com sucesso');
    } catch (e) {
      _log('❌ Erro ao inicializar notificações: $e');
    }
  }

  /// Inicializar notificações locais com configurações otimizadas para Xiaomi
  Future<void> _initializeLocalNotifications() async {
    // Configurações Android com alta prioridade para Xiaomi
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Aqui você pode navegar para uma tela específica
      },
    );

    // Criar/Atualizar canal de notificação com ALTA PRIORIDADE para Xiaomi
    // IMPORTANTE: Usar MESMO ID do canal antigo para atualizar as configurações
    const androidChannel = AndroidNotificationChannel(
      'helpdesk_channel', // MESMO ID do canal original (não criar novo!)
      'HelpDesk Notificações', // Nome original
      description: 'Notificações de chamados e solicitações',
      importance: Importance.max, // MÁXIMA prioridade (upgrade!)
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _log('✅ Canal de notificação ATUALIZADO com alta prioridade');
    _log(
      '📢 Nome do canal: "HelpDesk Notificações" (mesmo que você vê nas configurações)',
    );
  }

  /// Configurar handlers para diferentes estados de mensagens
  void _setupMessageHandlers() {
    // Mensagem recebida quando app está em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Mensagem clicada quando app estava em background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageNavigation(message);
    });

    // Verificar se o app foi aberto por uma notificação
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessageNavigation(message);
      }
    });
  }

  /// Manipular mensagem recebida em foreground (MELHORADO)
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Mostrar overlay visual com animação
      _showForegroundOverlay(
        title: notification.title ?? 'Nova Notificação',
        body: notification.body ?? '',
        data: data,
      );

      // Também mostrar notificação local para persistência
      _showLocalNotification(
        title: notification.title ?? 'Nova Notificação',
        body: notification.body ?? '',
        data: Map<String, String>.from(data),
      );
    }
  }

  /// Mostrar overlay visual quando app está em foreground
  void _showForegroundOverlay({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final context = NavigationService.currentContext;
    if (context == null) return;

    // Determinar cor e ícone baseado no tipo
    Color backgroundColor = Colors.blue;
    IconData icon = Icons.notifications;

    if (data != null && data.containsKey('tipo')) {
      switch (data['tipo']) {
        case 'novo_chamado':
          backgroundColor = Colors.orange;
          icon = Icons.add_alert;
          break;
        case 'chamado_atualizado':
          backgroundColor = Colors.blue;
          icon = Icons.update;
          break;
        case 'solicitacao_pendente':
          backgroundColor = Colors.purple;
          icon = Icons.approval;
          break;
        case 'solicitacao_aprovada':
          backgroundColor = Colors.green;
          icon = Icons.check_circle;
          break;
      }
    }

    // Mostrar SnackBar com ação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VER',
          textColor: Colors.white,
          onPressed: () =>
              _handleMessageNavigation(RemoteMessage(data: data ?? {})),
        ),
      ),
    );
  }

  /// Manipular navegação baseada na mensagem (IMPLEMENTADO)
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;

    // Navegação baseada no tipo de notificação
    if (data.containsKey('tipo')) {
      switch (data['tipo']) {
        case 'novo_chamado':
          NavigationService.navigateToFilaTecnica();
          _log('🧭 Navegando para Fila Técnica');
          break;

        case 'chamado_atualizado':
          if (data.containsKey('chamadoId')) {
            NavigationService.navigateToChamadoDetails(data['chamadoId']);
            _log('🧭 Navegando para Chamado: ${data['chamadoId']}');
          } else {
            NavigationService.navigateToHome();
          }
          break;

        case 'solicitacao_pendente':
          NavigationService.navigateToAprovarSolicitacoes();
          _log('🧭 Navegando para Aprovar Solicitações');
          break;

        case 'solicitacao_aprovada':
        case 'solicitacao_reprovada':
          NavigationService.navigateToHistoricoSolicitacoes();
          _log('🧭 Navegando para Histórico de Solicitações');
          break;

        default:
          NavigationService.navigateToHome();
          _log('🧭 Navegando para Home (tipo desconhecido: ${data['tipo']})');
      }
    } else {
      // Se não tem tipo, vai para home
      NavigationService.navigateToHome();
      _log('🧭 Navegando para Home (sem tipo especificado)');
    }
  }

  /// Iniciar listener de notificações em tempo real (MELHORADO - COM PREVENÇÃO DE DUPLICAÇÃO)
  /// Monitora a coleção 'notifications' e dispara notificações locais
  void startNotificationListener(String userId) {
    _log('🎧 Listener de notificações INICIADO para userId: $userId');

    // Limpar IDs processados ao iniciar
    _processedNotificationIds.clear();

    // Primeiro, buscar notificações não lidas existentes (quando app abre)
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(10) // Limitar a 10 mais recentes
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            _log(
              '📬 Encontradas ${snapshot.docs.length} notificações não lidas ao abrir app',
            );
            for (var doc in snapshot.docs) {
              final docId = doc.id;

              // Prevenir duplicação
              if (_processedNotificationIds.contains(docId)) {
                _log('⏭️ Notificação $docId já processada, pulando...');
                continue;
              }

              final data = doc.data();
              _log('   📩 Mostrando notificação: ${data['title']}');
              _showLocalNotification(
                title: data['title'] as String,
                body: data['body'] as String,
                data: Map<String, String>.from(data['data'] ?? {}),
              );

              // Marcar como processada
              _processedNotificationIds.add(docId);

              // Marcar como lida no Firestore
              doc.reference.update({'read': true});
            }
          } else {
            _log('✅ Nenhuma notificação pendente ao abrir app');
          }
        })
        .catchError((error) {
          _log('❌ Erro ao buscar notificações antigas: $error');
        });

    // Depois, iniciar listener para novas notificações em tempo real
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final docId = change.doc.id;

                // Prevenir duplicação
                if (_processedNotificationIds.contains(docId)) {
                  _log('⏭️ Notificação $docId já processada, pulando...');
                  continue;
                }

                final data = change.doc.data();
                if (data != null) {
                  _log('🔔 Nova notificação: ${data['title']}');
                  _showLocalNotification(
                    title: data['title'] as String,
                    body: data['body'] as String,
                    data: Map<String, String>.from(data['data'] ?? {}),
                  );

                  // Marcar como processada
                  _processedNotificationIds.add(docId);

                  // Marcar como lida
                  change.doc.reference.update({'read': true});
                }
              }
            }
          },
          onError: (error) {
            _log('❌ Erro no listener de notificações: $error');
          },
        );
  }

  /// Disparar notificação local com configurações otimizadas para Xiaomi
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Usar o canal ATUALIZADO com alta prioridade
      final androidDetails = AndroidNotificationDetails(
        'helpdesk_channel', // MESMO ID do canal criado/atualizado
        'HelpDesk Notificações', // Nome original
        channelDescription: 'Notificações de chamados e solicitações',
        importance:
            Importance.max, // MÁXIMA prioridade (necessário para Xiaomi)
        priority: Priority.high,
        showWhen: true,
        enableVibration: true, // Vibração para chamar atenção
        playSound: true, // Som para dispositivos em modo silencioso
        ticker: 'Novo Chamado', // Texto na barra de status
        fullScreenIntent: false, // Não mostrar em tela cheia
        autoCancel: true, // Auto remover quando clicado
        ongoing: false, // Permitir deslizar para remover
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'HelpDesk TI',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      _log('🔔 DEBUG: Preparando notificação...');
      _log('   Canal: helpdesk_channel');
      _log('   Título: $title');
      _log('   Corpo: $body');

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: data?.toString(),
      );

      _log(
        '✅ DEBUG: Notificação local disparada - ID: $notificationId, Título: $title',
      );
    } catch (e) {
      _log('❌ Erro ao disparar notificação local: $e');
    }
  }

  /// Salvar token FCM do usuário no Firestore (MELHORADO)
  Future<void> saveUserToken(String userId) async {
    // Armazenar userId para auto-atualização
    _currentUserId = userId;

    if (_fcmToken == null) {
      _log('⚠️ Token FCM é null, tentando gerar novo...');
      // Tentar gerar um novo token
      await _messaging.deleteToken();
      _fcmToken = await _messaging.getToken();

      if (_fcmToken == null) {
        _log('❌ Não foi possível gerar token FCM');
        return;
      }
      _log('✅ Novo token gerado: ${_fcmToken!.substring(0, 20)}...');
    }

    try {
      // Verificar se o token mudou antes de salvar
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final oldToken = userDoc.data()?['fcmToken'] as String?;

      if (oldToken == _fcmToken) {
        _log('ℹ️ Token FCM não mudou, sem necessidade de atualizar');
        startNotificationListener(userId);
        return;
      }

      _log(
        '💾 Salvando token FCM: ${_fcmToken!.substring(0, 20)}... para userId: $userId',
      );

      // Usar set com merge:true para criar o campo se não existir
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _log('✅ Token FCM salvo com sucesso no Firestore!');
      startNotificationListener(userId);
    } catch (e) {
      _log('❌ Erro ao salvar token FCM: $e');
    }
  }

  /// Atualizar token do usuário (IMPLEMENTADO)
  Future<void> _updateUserToken(String newToken, String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      _log('✅ Token FCM atualizado no Firestore para userId: $userId');
    } catch (e) {
      _log('❌ Erro ao atualizar token FCM: $e');
    }
  }

  /// Remover token FCM do usuário ao fazer logout
  Future<void> removeUserToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
    } catch (e) {
      _log('❌ Erro ao remover token FCM: $e');
    }
  }

  /// Inscrever em tópico (útil para notificações em grupo)
  Future<void> subscribeToTopic(String topic) async {
    // Na web, tópicos não são suportados pelo FCM
    if (kIsWeb) {
      _log('ℹ️ subscribeToTopic não suportado na web (limitação FCM)');
      return;
    }
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      _log('❌ Erro ao inscrever no tópico $topic: $e');
    }
  }

  /// Desinscrever de tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      _log('❌ Erro ao desinscrever do tópico $topic: $e');
    }
  }

  // ========== MÉTODOS DE ENVIO DE NOTIFICAÇÕES (SOLUÇÃO GRATUITA) ==========

  /// Envia notificação para usuários específicos (por role)
  ///
  /// [titulo] - Título da notificação
  /// [corpo] - Corpo da notificação
  /// [roles] - Lista de roles que devem receber (ex: ['admin', 'ti'])
  /// [data] - Dados extras para navegação
  /// [excludeUserId] - ID do usuário a excluir (geralmente quem criou)
  Future<void> sendNotificationToRoles({
    required String titulo,
    required String corpo,
    required List<String> roles,
    Map<String, String>? data,
    String? excludeUserId,
  }) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('role', whereIn: roles)
          .get();

      _log(
        '🔍 DEBUG: Encontrados ${usersQuery.docs.length} usuários com roles: $roles',
      );

      if (usersQuery.docs.isEmpty) {
        _log('⚠️ AVISO: Nenhum usuário encontrado com roles: $roles');
        return;
      }

      final tokens = <String>[];
      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        final userName = userData['nome'] ?? 'Sem nome';
        final userRole = userData['role'] ?? 'Sem role';

        if (excludeUserId != null && doc.id == excludeUserId) {
          _log(
            '⏭️ Ignorando usuário: $userName (userId: ${doc.id}) - é o criador do chamado',
          );
          continue;
        }

        final token = userData['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          _log(
            '✅ Token encontrado para: $userName ($userRole) - ${token.substring(0, 20)}...',
          );
          tokens.add(token);
        } else {
          _log('❌ SEM TOKEN: $userName ($userRole, userId: ${doc.id})');
        }
      }

      _log('🎫 DEBUG: Coletados ${tokens.length} tokens válidos');

      if (tokens.isEmpty) {
        _log('⚠️ AVISO: Nenhum token FCM válido encontrado!');
        return;
      }

      await _sendFCMNotification(
        tokens: tokens,
        titulo: titulo,
        corpo: corpo,
        data: data,
      );
    } catch (e, stackTrace) {
      _log('❌ ERRO CRÍTICO em sendNotificationToRoles: $e');
      _log(stackTrace.toString());
      rethrow;
    }
  }

  /// Envia notificação para um usuário específico
  ///
  /// [userId] - ID do usuário que deve receber
  /// [titulo] - Título da notificação
  /// [corpo] - Corpo da notificação
  /// [data] - Dados extras para navegação
  Future<void> sendNotificationToUser({
    required String userId,
    required String titulo,
    required String corpo,
    Map<String, String>? data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data();
      final token = userData?['fcmToken'] as String?;

      if (token == null || token.isEmpty) {
        return;
      }

      await _sendFCMNotification(
        tokens: [token],
        titulo: titulo,
        corpo: corpo,
        data: data,
      );
    } catch (e) {
      _log('❌ Erro ao enviar notificação para usuário: $e');
    }
  }

  /// Envia notificação para múltiplos usuários
  ///
  /// [userIds] - Lista de IDs dos usuários
  /// [titulo] - Título da notificação
  /// [corpo] - Corpo da notificação
  /// [data] - Dados extras para navegação
  /// [excludeUserId] - ID do usuário a excluir
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String titulo,
    required String corpo,
    Map<String, String>? data,
    String? excludeUserId,
  }) async {
    try {
      final filteredIds = excludeUserId != null
          ? userIds.where((id) => id != excludeUserId).toList()
          : userIds;

      if (filteredIds.isEmpty) {
        return;
      }

      final tokens = <String>[];
      for (var userId in filteredIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final token = userDoc.data()?['fcmToken'] as String?;
          if (token != null && token.isNotEmpty) {
            tokens.add(token);
          }
        }
      }

      if (tokens.isEmpty) {
        return;
      }

      await _sendFCMNotification(
        tokens: tokens,
        titulo: titulo,
        corpo: corpo,
        data: data,
      );
    } catch (e) {
      _log('❌ Erro ao enviar notificação: $e');
    }
  }

  /// Envia notificação via Firebase Cloud Messaging usando dados no Firestore
  /// Salva notificação no Firestore (Legacy FCM HTTP API foi descontinuada)
  Future<void> _sendFCMNotification({
    required List<String> tokens,
    required String titulo,
    required String corpo,
    Map<String, String>? data,
  }) async {
    try {
      for (var token in tokens) {
        try {
          final userQuery = await _firestore
              .collection('users')
              .where('fcmToken', isEqualTo: token)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            final userId = userQuery.docs.first.id;
            final userName = userQuery.docs.first.data()['nome'] as String?;

            await _firestore.collection('notifications').add({
              'userId': userId,
              'userName': userName,
              'title': titulo,
              'body': corpo,
              'data': data ?? {},
              'read': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
            _log(
              '✅ DEBUG: Notificação salva no Firestore para $userName ($userId)',
            );
          }
        } catch (e) {
          _log('❌ Erro ao processar token de notificação: $e');
        }
      }
    } catch (e, stackTrace) {
      _log('❌ EXCEÇÃO em _sendFCMNotification: $e');
      _log(stackTrace.toString());
      rethrow;
    }
  }
}

// ========== FUNÇÃO DE LOG PARA HANDLERS TOP-LEVEL ==========
void _logBackground(String message) {
  if (kDebugMode) print(message);
}

/// Handler para mensagens em background MELHORADO (função top-level)
/// Deve estar fora da classe e ser anotada com @pragma
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final title = message.notification?.title ?? 'Nova notificação';
  final body = message.notification?.body ?? '';
  _logBackground('🌙 Notificação em background: $title');

  // Salvar no Firestore para exibir quando app abrir
  try {
    final data = message.data;
    if (data.containsKey('userId')) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': data['userId'],
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'receivedInBackground': true,
      });
      _logBackground(
        '✅ Notificação salva no Firestore para exibição posterior',
      );
    }
  } catch (e) {
    _logBackground('❌ Erro ao salvar notificação em background: $e');
  }
}

/// Registrar o background handler
void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
