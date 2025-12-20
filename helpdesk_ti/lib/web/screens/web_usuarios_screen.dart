import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';

/// Tela de gerenciamento completo de usuários
class WebUsuariosScreen extends StatefulWidget {
  const WebUsuariosScreen({super.key});

  @override
  State<WebUsuariosScreen> createState() => _WebUsuariosScreenState();
}

class _WebUsuariosScreenState extends State<WebUsuariosScreen> {
  String _searchQuery = '';
  String _roleFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrador TI';
      case 'manager':
        return 'Gerente';
      case 'admin_manutencao':
        return 'Admin Manutenção';
      case 'executor':
        return 'Executor';
      case 'user':
        return 'Usuário';
      default:
        return role ?? 'Desconhecido';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return AppColors.primary;
      case 'manager':
        return Colors.purple;
      case 'admin_manutencao':
        return Colors.orange;
      case 'executor':
        return Colors.teal;
      case 'user':
        return Colors.blueGrey;
      default:
        return AppColors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.supervisor_account;
      case 'admin_manutencao':
        return Icons.build_circle;
      case 'executor':
        return Icons.engineering;
      case 'user':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    var filtered = users;

    // Filtro de busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((u) {
        final nome = (u['nome'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final departamento = (u['departamento'] ?? '').toString().toLowerCase();
        return nome.contains(_searchQuery.toLowerCase()) ||
            email.contains(_searchQuery.toLowerCase()) ||
            departamento.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtro de role
    if (_roleFilter != 'Todos') {
      final roleMap = {
        'Administrador TI': 'admin',
        'Gerente': 'manager',
        'Admin Manutenção': 'admin_manutencao',
        'Executor': 'executor',
        'Usuário': 'user',
      };
      final role = roleMap[_roleFilter];
      if (role != null) {
        filtered = filtered.where((u) => u['role'] == role).toList();
      }
    }

    return filtered;
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getRoleColor(user['role']),
                      child: Icon(
                        _getRoleIcon(user['role']),
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['nome'] ?? 'Sem nome',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(
                                user['role'],
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleLabel(user['role']),
                              style: TextStyle(
                                color: _getRoleColor(user['role']),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildDetailRow(Icons.email, 'Email', user['email'] ?? 'N/A'),
                _buildDetailRow(
                  Icons.business,
                  'Departamento',
                  user['departamento'] ?? 'N/A',
                ),
                _buildDetailRow(
                  Icons.phone,
                  'Telefone',
                  user['telefone'] ?? 'N/A',
                ),
                if (user['criadoEm'] != null)
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Criado em',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format((user['criadoEm'] as dynamic).toDate()),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Fechar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da página
            Text(
              'Gerenciamento de Usuários',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Barra de ferramentas
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Campo de pesquisa
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome, email ou departamento...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.greyLight,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Filtro de role
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.greyLight,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _roleFilter,
                        items:
                            [
                              'Todos',
                              'Administrador TI',
                              'Gerente',
                              'Admin Manutenção',
                              'Executor',
                              'Usuário',
                            ].map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _roleFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tabela de usuários
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: authService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text('Erro: ${snapshot.error}'),
                        ],
                      ),
                    ),
                  );
                }

                final users = _filterUsers(snapshot.data ?? []);

                if (users.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum usuário encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Estatísticas rápidas
                final stats = {
                  'total': users.length,
                  'admins': users.where((u) => u['role'] == 'admin').length,
                  'managers': users.where((u) => u['role'] == 'manager').length,
                  'usuarios': users.where((u) => u['role'] == 'user').length,
                };

                return Column(
                  children: [
                    // Cards de estatísticas
                    Row(
                      children: [
                        _buildStatCard(
                          'Total',
                          stats['total']!,
                          Icons.people,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Admins',
                          stats['admins']!,
                          Icons.admin_panel_settings,
                          Colors.deepPurple,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Gerentes',
                          stats['managers']!,
                          Icons.supervisor_account,
                          Colors.purple,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Usuários',
                          stats['usuarios']!,
                          Icons.person,
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tabela
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.primary.withValues(alpha: 0.1),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Usuário',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Departamento',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Função',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Ações',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: users.map((user) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: _getRoleColor(
                                          user['role'],
                                        ).withValues(alpha: 0.2),
                                        child: Icon(
                                          _getRoleIcon(user['role']),
                                          size: 16,
                                          color: _getRoleColor(user['role']),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(user['nome'] ?? 'Sem nome'),
                                    ],
                                  ),
                                ),
                                DataCell(Text(user['email'] ?? 'N/A')),
                                DataCell(Text(user['departamento'] ?? 'N/A')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(
                                        user['role'],
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getRoleLabel(user['role']),
                                      style: TextStyle(
                                        color: _getRoleColor(user['role']),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          size: 20,
                                        ),
                                        tooltip: 'Ver detalhes',
                                        onPressed: () =>
                                            _showUserDetailsDialog(user),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: AppColors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
