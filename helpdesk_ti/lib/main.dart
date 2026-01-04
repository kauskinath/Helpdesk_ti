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

import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/new_ticket_screen.dart';
import 'screens/admin_management_screen.dart';
import 'screens/template_management_screen.dart';
import 'screens/manutencao_router_screen.dart';
import 'screens/gerente_dashboard_screen.dart';
// Telas Web
import 'web/screens/web_login_screen.dart';
import 'web/layouts/web_layout.dart';

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

  // Registrar handler de notificações em background (apenas para mobile)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

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
          // Se está rodando na WEB, usar layout web
          if (kIsWeb) {
            return MaterialApp(
              title: 'HelpDesk TI - Painel Web',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.light,
                ),
                primaryColor: AppColors.primary,
                scaffoldBackgroundColor: AppColors.greyLight,
                cardTheme: CardThemeData(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.dark,
                ),
                primaryColor: AppColors.primary,
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardTheme: CardThemeData(
                  elevation: 4,
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              home: const WebAuthWrapper(),
            );
          }

          // Mobile: usar layout normal
          return MaterialApp(
            title: 'PICHAU TI',
            debugShowCheckedModeBanner: false,

            // NavigatorKey para NavigationService (notificações)
            navigatorKey: NavigationService.navigatorKey,

            // Temas personalizados
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            home: const MobileAuthWrapper(),
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

/// Auth wrapper para versão WEB
class WebAuthWrapper extends StatelessWidget {
  const WebAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Se está logado mas role ainda não carregou, mostrar loading
    if (authService.isLoggedIn && authService.userRole == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando...'),
            ],
          ),
        ),
      );
    }

    // Se não está logado, mostrar login web
    if (!authService.isLoggedIn) {
      return const WebLoginScreen();
    }

    // Se está logado, mostrar layout web
    return const WebLayout();
  }
}

/// Auth wrapper para versão MOBILE
class MobileAuthWrapper extends StatelessWidget {
  const MobileAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostrar loading enquanto verifica autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se há erro no stream, mostrar login
        if (snapshot.hasError) {
          debugPrint('❌ AuthWrapper: Erro no stream: ${snapshot.error}');
          return const LoginScreen();
        }

        // Se não há usuário autenticado, mostrar login
        if (snapshot.data == null) {
          return const LoginScreen();
        }

        // Usar Consumer para escutar apenas mudanças do AuthService (role loaded)
        return Consumer<AuthService>(
          builder: (context, auth, _) {
            // Se role ainda não foi carregada, mostrar loading
            if (auth.userRole == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Rotear baseado na role
            debugPrint(
              '✅ AuthWrapper: Usuário logado (${auth.userRole}), roteando...',
            );

            // Usuário comum: Mostrar tabs (TI + Manutenção)
            if (auth.isUser) {
              return const UserHomeScreen();
            }

            // Gerente: Dashboard completo com TI e Manutenção
            if (auth.isManager) {
              return const GerenteDashboardScreen();
            }

            // Admin Manutenção, Executor: Direto para dashboard de manutenção
            if (auth.isAdminManutencao || auth.isExecutor) {
              return const ManutencaoRouterScreen();
            }

            // Admin TI e outros: HomeScreen padrão (apenas TI)
            return const HomeScreen();
          },
        );
      },
    );
  }
}
