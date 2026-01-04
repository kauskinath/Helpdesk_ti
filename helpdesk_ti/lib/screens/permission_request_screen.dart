import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';

/// Tela de boas-vindas que solicita TODAS as permissões necessárias
/// ANTES do usuário fazer login (especialmente importante para Xiaomi)
class PermissionRequestScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const PermissionRequestScreen({super.key, this.onComplete});

  @override
  State<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  final List<String> _grantedPermissions = [];
  final List<String> _deniedPermissions = [];

  @override
  void initState() {
    super.initState();
    // Solicitar permissões automaticamente ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAllPermissions();
    });
  }

  Future<void> _requestAllPermissions() async {
    _grantedPermissions.clear();
    _deniedPermissions.clear();

    // NOTIFICAÇÕES (Firebase Cloud Messaging) - CRÍTICO para Xiaomi
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true, // Máxima prioridade (iOS)
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _grantedPermissions.add('✅ Notificações (Autorizada)');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _grantedPermissions.add('✅ Notificações (Provisória)');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _deniedPermissions.add('❌ Notificações (Negada)');
      } else {
        _deniedPermissions.add('⚠️ Notificações (Não Determinada)');
      }
    } catch (e) {
      print('⚠️ Erro ao solicitar permissões de notificação: $e');
      _deniedPermissions.add('❌ Notificações (Erro: $e)');
    }

    // Prosseguir direto para login
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      _proceedToLogin();
    }
  }

  void _proceedToLogin() {
    // Se temos callback, usar ele; senão, usar Navigator.pop
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isDarkMode
                  ? 'assets/images/wallpaper_dark.png'
                  : 'assets/images/wallpaper_light.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo simples
                Icon(Icons.notifications_active, size: 80, color: Colors.white),
                SizedBox(height: 24),

                // Título
                Text(
                  'HelpDesk TI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 48),

                // Loading indicator simples
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 24),
                Text(
                  'Configurando...',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
