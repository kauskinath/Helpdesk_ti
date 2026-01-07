import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 14});

  Color _getStatusColor() {
    switch (status) {
      case 'Aberto':
        return DS.success;
      case 'Em Andamento':
        return DS.action;
      case 'Pendente Aprovação':
      case 'Aguardando':
        return DS.warning;
      case 'Fechado':
        return DS.textSecondary;
      case 'Rejeitado':
        return DS.error;
      default:
        return DS.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'Aberto':
        return Icons.fiber_new_rounded;
      case 'Em Andamento':
        return Icons.pending_actions;
      case 'Pendente Aprovação':
      case 'Aguardando':
        return Icons.hourglass_empty;
      case 'Fechado':
        return Icons.check_circle;
      case 'Rejeitado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: fontSize + 2, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
