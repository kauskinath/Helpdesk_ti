import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';

/// Tela de configurações do sistema
class WebConfiguracoesScreen extends StatefulWidget {
  const WebConfiguracoesScreen({super.key});

  @override
  State<WebConfiguracoesScreen> createState() => _WebConfiguracoesScreenState();
}

class _WebConfiguracoesScreenState extends State<WebConfiguracoesScreen> {
  // Configurações gerais
  bool _notificacoesEmail = true;
  bool _notificacoesPush = true;
  bool _somNotificacoes = true;

  // Configurações de chamados
  bool _autoAtribuicao = false;
  String _prioridadePadrao = 'Média';
  int _diasParaArquivar = 30;

  // Configurações de segurança
  bool _loginDoisFatores = false;
  int _sessaoTimeout = 30;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userName = authService.firebaseUser?.displayName ?? 'Admin';
    final userEmail = authService.firebaseUser?.email ?? '';
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      // Fundo limpo para web
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da página
            Text(
              'Configurações',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna esquerda
                Expanded(
                  child: Column(
                    children: [
                      // Perfil do usuário
                      _buildSection(
                        'Perfil do Usuário',
                        Icons.person,
                        Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    userName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        userEmail,
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Administrador',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showEditProfileDialog();
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Editar Perfil'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showChangePasswordDialog();
                                    },
                                    icon: const Icon(Icons.lock),
                                    label: const Text('Alterar Senha'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notificações
                      _buildSection(
                        'Notificações',
                        Icons.notifications,
                        Column(
                          children: [
                            _buildSwitchTile(
                              'Notificações por Email',
                              'Receber notificações via email',
                              Icons.email,
                              _notificacoesEmail,
                              (value) =>
                                  setState(() => _notificacoesEmail = value),
                            ),
                            _buildSwitchTile(
                              'Notificações Push',
                              'Receber notificações no navegador',
                              Icons.notifications_active,
                              _notificacoesPush,
                              (value) =>
                                  setState(() => _notificacoesPush = value),
                            ),
                            _buildSwitchTile(
                              'Som de Notificações',
                              'Reproduzir som ao receber notificações',
                              Icons.volume_up,
                              _somNotificacoes,
                              (value) =>
                                  setState(() => _somNotificacoes = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Coluna direita
                Expanded(
                  child: Column(
                    children: [
                      // Configurações de Chamados
                      _buildSection(
                        'Configurações de Chamados',
                        Icons.confirmation_number,
                        Column(
                          children: [
                            _buildSwitchTile(
                              'Auto-atribuição',
                              'Atribuir chamados automaticamente',
                              Icons.auto_mode,
                              _autoAtribuicao,
                              (value) =>
                                  setState(() => _autoAtribuicao = value),
                            ),
                            const Divider(),
                            _buildDropdownTile(
                              'Prioridade Padrão',
                              'Prioridade inicial dos novos chamados',
                              Icons.flag,
                              _prioridadePadrao,
                              ['Baixa', 'Média', 'Alta'],
                              (value) {
                                if (value != null) {
                                  setState(() => _prioridadePadrao = value);
                                }
                              },
                            ),
                            const Divider(),
                            _buildNumberTile(
                              'Dias para Arquivar',
                              'Arquivar chamados fechados após',
                              Icons.archive,
                              _diasParaArquivar,
                              (value) =>
                                  setState(() => _diasParaArquivar = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Segurança
                      _buildSection(
                        'Segurança',
                        Icons.security,
                        Column(
                          children: [
                            _buildSwitchTile(
                              'Autenticação de Dois Fatores',
                              'Adicionar camada extra de segurança',
                              Icons.verified_user,
                              _loginDoisFatores,
                              (value) =>
                                  setState(() => _loginDoisFatores = value),
                            ),
                            const Divider(),
                            _buildNumberTile(
                              'Timeout de Sessão',
                              'Minutos de inatividade para logout',
                              Icons.timer,
                              _sessaoTimeout,
                              (value) => setState(() => _sessaoTimeout = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Informações do Sistema
                      _buildSection(
                        'Sobre o Sistema',
                        Icons.info,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Versão', '1.0.0'),
                            _buildInfoRow('Ambiente', 'Produção'),
                            _buildInfoRow('Última Atualização', '15/01/2025'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Verificando atualizações...',
                                          ),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.update),
                                    label: const Text('Verificar Atualizações'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botões de ação
            Container(
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: isDarkMode
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkMode ? 0.2 : 0.08,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Reset para padrões
                      setState(() {
                        _notificacoesEmail = true;
                        _notificacoesPush = true;
                        _somNotificacoes = true;
                        _autoAtribuicao = false;
                        _prioridadePadrao = 'Média';
                        _diasParaArquivar = 30;
                        _loginDoisFatores = false;
                        _sessaoTimeout = 30;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Configurações resetadas para o padrão',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white70 : null,
                      side: BorderSide(
                        color: isDarkMode ? Colors.white30 : AppColors.grey,
                      ),
                    ),
                    child: const Text('Restaurar Padrões'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configurações salvas com sucesso!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Alterações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: content),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subtitleColor),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return null;
        }),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subtitleColor),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.grey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
            style: TextStyle(color: textColor),
            items: options.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberTile(
    String title,
    String subtitle,
    IconData icon,
    int value,
    Function(int) onChanged,
  ) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subtitleColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            color: AppColors.primary,
          ),
          Container(
            width: 50,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.grey.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(4),
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : null,
            ),
            child: Text(
              value.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 1),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final labelColor = isDarkMode ? Colors.white70 : AppColors.grey;
    final valueColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Editar Perfil'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perfil atualizado!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Alterar Senha'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha Atual',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nova Senha',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar Nova Senha',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Senha alterada com sucesso!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }
}
