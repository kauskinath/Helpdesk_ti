// ============================================================================
// PICHAU TI - Sistema de Suporte Técnico
// ============================================================================
// © 2024-2025 Pichau Informática Ltda. Todos os direitos reservados.
//
// Este software é propriedade exclusiva da Pichau Informática Ltda.
// O uso, cópia, modificação ou distribuição não autorizada deste código
// é estritamente proibida e pode resultar em penalidades civis e criminais.
//
// Desenvolvido por: Departamento de TI - Pichau Informática
// Versão: 1.0.0
// Data: Dezembro/2024
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'data/firestore_service.dart';
import 'data/services/chamado_service.dart';
import 'package:helpdesk_ti/core/services/notification_service.dart';
import 'package:helpdesk_ti/core/services/navigation_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/new_ticket_screen.dart';
import 'screens/admin_management_screen.dart';
import 'screens/permission_request_screen.dart';
import 'screens/template_management_screen.dart';
import 'screens/manutencao_router_screen.dart';
import 'screens/gerente_dashboard_screen.dart';

/// Handler de notificações em background (quando app está fechado/minimizado)
/// IMPORTANTE: Esta função DEVE ser top-level (fora de qualquer classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 BACKGROUND: Notificação recebida enquanto app estava fechado');
  print('🔔 BACKGROUND: Título: ${message.notification?.title}');
  print('🔔 BACKGROUND: Corpo: ${message.notification?.body}');
  // A notificação será mostrada automaticamente pelo sistema
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar handler de notificações em background (para Xiaomi e outros)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const HelpDeskApp());
}

class HelpDeskApp extends StatelessWidget {
  const HelpDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NotificationService>(create: (_) => NotificationService()),
        ChangeNotifierProvider<AuthService>(
          create: (context) {
            final authService = AuthService();
            final notificationService = context.read<NotificationService>();
            authService.setNotificationService(notificationService);
            return authService;
          },
        ),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<ChamadoService>(create: (_) => ChamadoService()),
        // Provider de Tema (Claro/Escuro)
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'PICHAU TI',
            debugShowCheckedModeBanner: false,

            // NavigatorKey para NavigationService (notificações)
            navigatorKey: NavigationService.navigatorKey,

            // Temas personalizados
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/user_home': (context) => const UserHomeScreen(),
              '/new_ticket': (context) => const NewTicketScreen(),
              '/admin': (context) => const AdminManagementScreen(),
              '/templates': (context) => const TemplateManagementScreen(),
              '/manutencao': (context) => const ManutencaoRouterScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    // Solicitar permissões na primeira vez que o app abre
    _requestPermissionsOnFirstLaunch();
  }

  Future<void> _requestPermissionsOnFirstLaunch() async {
    if (!_permissionsRequested) {
      // Aguardar frame ser renderizado
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PermissionRequestScreen(),
          ),
        );

        setState(() {
          _permissionsRequested = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Mostrar loading enquanto solicita permissões
        if (!_permissionsRequested) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Mostrar loading enquanto verifica autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se não está logado, mostra login
        if (!authService.isLoggedIn) {
          print('❌ AuthWrapper: Sem usuário, abrindo LoginScreen');
          return const LoginScreen();
        }

        // Rotear baseado na role
        print(
          '✅ AuthWrapper: Usuário logado (${authService.userRole}), roteando...',
        );

        // Usuário comum: Mostrar tabs (TI + Manutenção)
        if (authService.isUser) {
          print('👤 Roteando para UserHomeScreen (tabs TI + Manutenção)');
          return const UserHomeScreen();
        }

        // Gerente: Dashboard completo com TI e Manutenção
        if (authService.isManager) {
          print('👔 Roteando para GerenteDashboardScreen (TI + Manutenção)');
          return const GerenteDashboardScreen();
        }

        // Admin Manutenção, Executor: Direto para dashboard de manutenção
        if (authService.isAdminManutencao || authService.isExecutor) {
          print('🔧 Roteando para ManutencaoRouterScreen');
          return const ManutencaoRouterScreen();
        }

        // Admin TI e outros: HomeScreen padrão (apenas TI)
        print('💻 Roteando para HomeScreen (TI)');
        return const HomeScreen();
      },
    );
  }
}
