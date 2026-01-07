import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';

/// Layout base para todas as dashboards do sistema (TI e Manutenção)
///
/// Fornece estrutura consistente com:
/// - Fundo escuro fixo usando DS (Design System)
/// - Menu popup (3 pontinhos) organizado por categorias
/// - Header com saudação personalizada
class BaseDashboardLayout extends StatelessWidget {
  final String title;
  final String titleEmoji;
  final Color primaryColor;
  final Widget body;
  final List<MenuCategory> menuCategories;
  final FloatingActionButton? floatingActionButton;
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
    this.showMenu = true,
    this.showHeader = true,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // Se showHeader é false, não renderiza scaffold
    // (usado quando é uma sub-tela dentro de outro dashboard)
    if (!showHeader) {
      return Column(children: [Expanded(child: body)]);
    }

    // Modo normal: com DS e header
    return Container(
      color: DS.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header com menu
              _buildHeader(context),
              // Body customizável
              Expanded(child: body),
            ],
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: DS.textPrimary,
                        ),
                      ),
                      Text(
                        '$titleEmoji $title',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: DS.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '$titleEmoji $title',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: DS.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),

          // Menu popup moderno (3 pontinhos)
          if (showMenu)
            Container(
              decoration: BoxDecoration(
                color: DS.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DS.border, width: 1),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: DS.textPrimary),
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
