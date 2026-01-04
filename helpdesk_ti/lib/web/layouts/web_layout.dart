import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../screens/web_dashboard_screen.dart';
import '../screens/web_user_home_screen.dart';
import '../screens/web_chamados_screen.dart';
import '../screens/web_usuarios_screen.dart';
import '../screens/web_relatorios_screen.dart';
import '../screens/web_configuracoes_screen.dart';

/// Layout principal do painel web com sidebar e header
class WebLayout extends StatefulWidget {
  const WebLayout({super.key});

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  int _selectedIndex = 0;

  // Menu items serão filtrados baseado na role do usuário
  List<_MenuItem> _getMenuItemsForRole(String? role) {
    final allItems = [
      _MenuItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        index: 0,
        roles: ['admin', 'manager', 'admin_manutencao', 'executor', 'user'],
      ),
      _MenuItem(
        icon: Icons.confirmation_number_rounded,
        label: 'Chamados',
        index: 1,
        roles: ['admin', 'manager', 'admin_manutencao', 'executor', 'user'],
      ),
      _MenuItem(
        icon: Icons.people_rounded,
        label: 'Usuários',
        index: 2,
        roles: ['admin'], // Somente admin
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'Relatórios',
        index: 3,
        roles: ['admin', 'manager'], // Admin e gerente
      ),
      _MenuItem(
        icon: Icons.settings_rounded,
        label: 'Configurações',
        index: 4,
        roles: ['admin'], // Somente admin
      ),
    ];

    return allItems
        .where((item) => item.roles.contains(role ?? 'user'))
        .toList();
  }

  String _getRoleTitle(String? role) {
    switch (role) {
      case 'admin':
        return 'Painel Administrativo';
      case 'manager':
        return 'Painel do Gerente';
      case 'admin_manutencao':
        return 'Painel Manutenção';
      case 'executor':
        return 'Painel Executor';
      case 'user':
        return 'Portal do Usuário';
      default:
        return 'HelpDesk TI';
    }
  }

  Widget _getScreen() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _getCurrentScreen(),
    );
  }

  Widget _getCurrentScreen() {
    final authService = context.read<AuthService>();
    final userRole = authService.userRole;

    switch (_selectedIndex) {
      case 0:
        // Usuários comuns vêem a tela home simplificada
        if (userRole == 'user') {
          return const WebUserHomeScreen(key: ValueKey('user_home'));
        }
        return const WebDashboardScreen(key: ValueKey('dashboard'));
      case 1:
        return const WebChamadosScreen(key: ValueKey('chamados'));
      case 2:
        return const WebUsuariosScreen(key: ValueKey('usuarios'));
      case 3:
        return const WebRelatoriosScreen(key: ValueKey('relatorios'));
      case 4:
        return const WebConfiguracoesScreen(key: ValueKey('config'));
      default:
        return const WebDashboardScreen(key: ValueKey('dashboard'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final userName = authService.firebaseUser?.displayName ?? 'Admin';
    final userEmail = authService.firebaseUser?.email ?? '';
    final isTablet = MediaQuery.of(context).size.width < 1024;
    final sidebarWidth = isTablet ? 220.0 : 260.0;

    // Cores adaptativas
    final bgColor = isDarkMode ? const Color(0xFF121212) : AppColors.greyLight;

    // Gradiente da sidebar mais vibrante no modo escuro
    final sidebarGradient = isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppColors.primaryGradient;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              gradient: sidebarGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo/Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/pombo_logo.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    '🐦',
                                    style: TextStyle(fontSize: 36),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'HelpDesk TI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getRoleTitle(authService.userRole),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),

                // Menu Items - filtrados por role
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final menuItems = _getMenuItemsForRole(
                        authService.userRole,
                      );
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final item = menuItems[index];
                          final isSelected = _selectedIndex == item.index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = item.index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white30,
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const Spacer(),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // User info + Logout
                const Divider(color: Colors.white24, height: 1),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await authService.logout();
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sair'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Container(color: bgColor, child: _getScreen()),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;
  final List<String> roles;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.index,
    this.roles = const ['admin'],
  });
}
