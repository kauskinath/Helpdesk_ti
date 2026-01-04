import 'package:flutter_test/flutter_test.dart';
import 'package:helpdesk_ti/core/permissions/user_permissions.dart';

void main() {
  group('UserPermissions', () {
    group('Admin Role', () {
      late UserPermissions adminPermissions;

      setUp(() {
        adminPermissions = UserPermissions('admin');
      });

      test('admin pode ver fila técnica', () {
        expect(adminPermissions.canViewFilaTecnica, isTrue);
      });

      test('admin pode gerenciar usuários', () {
        expect(adminPermissions.canManageUsers, isTrue);
      });

      test('admin pode editar serviços', () {
        expect(adminPermissions.canEditServicos, isTrue);
      });

      test('admin pode mudar status de tickets', () {
        expect(adminPermissions.canChangeTicketStatus, isTrue);
      });

      test('admin pode deletar tickets', () {
        expect(adminPermissions.canDeleteTickets, isTrue);
      });

      test('admin pode atribuir tickets a si mesmo', () {
        expect(adminPermissions.canAssignTicketsToSelf, isTrue);
      });
    });

    group('Manager Role', () {
      late UserPermissions managerPermissions;

      setUp(() {
        managerPermissions = UserPermissions('manager');
      });

      test('manager pode aprovar/rejeitar solicitações', () {
        expect(managerPermissions.canApproveRejectSolicitacoes, isTrue);
      });

      test('manager pode ver fila técnica', () {
        expect(managerPermissions.canViewFilaTecnica, isTrue);
      });

      test('manager pode ver dashboard', () {
        expect(managerPermissions.canViewDashboard, isTrue);
      });

      test('manager não pode gerenciar usuários', () {
        expect(managerPermissions.canManageUsers, isFalse);
      });

      test('manager não pode deletar tickets', () {
        expect(managerPermissions.canDeleteTickets, isFalse);
      });
    });

    group('User Role', () {
      late UserPermissions userPermissions;

      setUp(() {
        userPermissions = UserPermissions('user');
      });

      test('user pode ver meus chamados', () {
        expect(userPermissions.canViewMeusChamados, isTrue);
      });

      test('user pode criar serviço', () {
        expect(userPermissions.canCreateServico, isTrue);
      });

      test('user pode criar solicitação', () {
        expect(userPermissions.canCreateSolicitacao, isTrue);
      });

      test('user não pode ver fila técnica', () {
        expect(userPermissions.canViewFilaTecnica, isFalse);
      });

      test('user não pode gerenciar usuários', () {
        expect(userPermissions.canManageUsers, isFalse);
      });

      test('user não pode aprovar solicitações', () {
        expect(userPermissions.canApproveRejectSolicitacoes, isFalse);
      });

      test('user não pode editar serviços', () {
        expect(userPermissions.canEditServicos, isFalse);
      });

      test('user não pode ver dashboard', () {
        expect(userPermissions.canViewDashboard, isFalse);
      });
    });
  });
}
