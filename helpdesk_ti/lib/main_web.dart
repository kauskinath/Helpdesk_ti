import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'data/firestore_service.dart';
import 'package:helpdesk_ti/core/services/notification_service.dart';
import 'web/screens/web_login_screen.dart';
import 'web/layouts/web_layout.dart';

/// Entry point para a versão WEB do painel administrativo
/// Uso: flutter run -d chrome --dart-define=WEB_PANEL=true
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const HelpDeskWebPanel());
}

class HelpDeskWebPanel extends StatelessWidget {
  const HelpDeskWebPanel({super.key});

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
        Provider<FirestoreService>(create: (context) => FirestoreService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
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
        },
      ),
    );
  }
}

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

    // Verificar se está logado (qualquer role pode acessar a web agora)
    if (authService.isLoggedIn) {
      // TODO: Futuramente, rotear para telas específicas baseado na role
      // Por enquanto, todos usam o WebLayout (admin tem acesso completo)
      return const WebLayout();
    }

    // Se não está logado, mostrar login
    return const WebLoginScreen();
  }
}
