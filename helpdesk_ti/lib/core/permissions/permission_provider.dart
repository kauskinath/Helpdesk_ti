import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'user_permissions.dart';

/// Provider que facilita acesso às permissões em qualquer widget
///
/// Uso:
/// ```dart
/// final permissions = PermissionProvider.of(context);
/// if (permissions.canEditServicos) {
///   // Mostrar botão de editar
/// }
/// ```

class PermissionProvider {
  /// Obtém as permissões do usuário atual
  static UserPermissions of(BuildContext context) {
    final authService = context.watch<AuthService>();
    final role = authService.userRole ?? 'user';
    return UserPermissions(role);
  }

  /// Obtém as permissões sem escutar mudanças (para callbacks)
  static UserPermissions read(BuildContext context) {
    final authService = context.read<AuthService>();
    final role = authService.userRole ?? 'user';
    return UserPermissions(role);
  }

  /// Obtém as permissões de uma role específica (para comparações)
  static UserPermissions forRole(String role) {
    return UserPermissions(role);
  }
}

/// Extension para facilitar acesso às permissões
extension PermissionContext on BuildContext {
  /// Acesso rápido às permissões do usuário
  UserPermissions get permissions => PermissionProvider.of(this);
}

