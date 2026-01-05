import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';

/// Layout base para todas as dashboards do sistema (TI e Manutenção)
///
/// Fornece estrutura consistente com:
/// - Wallpaper (claro/escuro) baseado no tema
/// - Botão de tema no canto superior esquerdo
/// - Menu hambúrguer organizado por categorias
/// - AppBar transparente sobre o wallpaper
class BaseDashboardLayout extends StatelessWidget {
  final String title;
  final String titleEmoji;
  final Color primaryColor;
  final Widget body;
  final List<MenuCategory> menuCategories;
  final FloatingActionButton? floatingActionButton;
  final bool showThemeToggle;
  final bool showMenu;
  final bool showHeader;
  final String? userName;

  const BaseDashboardLayout({
    super.key,
    required this.title,
    required this.titleEmoji,
    required this.primaryColor,
    required this.body,
    required this.menuCategories,
    this.floatingActionButton,
    this.showThemeToggle = true,
    this.showMenu = true,
    this.showHeader = true,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    // Se showHeader é false, não renderiza wallpaper nem scaffold
    // (usado quando é uma sub-tela dentro de outro dashboard)
    if (!showHeader) {
      return Column(children: [Expanded(child: body)]);
    }

    // Modo normal: com cor sólida e header
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header com tema + menu
              _buildHeader(context, isDarkMode),
              // Body customizável
              Expanded(child: body),
            ],
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Título centralizado ou saudação com nome
          Expanded(
            child: userName != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Olá, $userName!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$titleEmoji $title',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '$titleEmoji $title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Botão de tema ao lado do menu
          if (showThemeToggle)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                tooltip: isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                onPressed: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
            ),

          // Menu popup moderno (3 pontinhos)
          if (showMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              offset: const Offset(0, 50),
              onSelected: (String value) {
                // Encontrar o item pelo value e executar seu onTap
                for (var category in menuCategories) {
                  final item = category.items.firstWhere(
                    (item) => item.value == value,
                    orElse: () =>
                        const MenuItem(value: '', emoji: '', label: ''),
                  );
                  if (item.value == value && item.onTap != null) {
                    item.onTap!(context);
                    break;
                  }
                }
              },
              itemBuilder: (context) {
                final List<PopupMenuEntry<String>> menuItems = [];

                for (int i = 0; i < menuCategories.length; i++) {
                  final category = menuCategories[i];

                  // Adicionar items da categoria
                  for (var item in category.items) {
                    menuItems.add(
                      PopupMenuItem<String>(
                        value: item.value,
                        child: Row(
                          children: [
                            Icon(
                              item.icon ?? Icons.circle,
                              size: 20,
                              color: category.color,
                            ),
                            const SizedBox(width: 12),
                            Text(item.label),
                          ],
                        ),
                      ),
                    );
                  }

                  // Adicionar divider entre categorias (exceto após a última)
                  if (i < menuCategories.length - 1) {
                    menuItems.add(const PopupMenuDivider());
                  }
                }

                return menuItems;
              },
            ),
        ],
      ),
    );
  }
}

/// Categoria de menu com ícone e items
class MenuCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<MenuItem> items;

  const MenuCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

/// Item de menu individual
class MenuItem {
  final String value;
  final String emoji;
  final IconData? icon; // Ícone moderno para o menu visual
  final String label;
  final void Function(BuildContext)? onTap;

  const MenuItem({
    required this.value,
    required this.emoji,
    this.icon,
    required this.label,
    this.onTap,
  });
}
