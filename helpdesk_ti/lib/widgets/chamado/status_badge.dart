import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 14,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Aberto':
        return const Color(0xFF4CAF50);
      case 'Em Andamento':
        return const Color(0xFF2196F3);
      case 'Pendente Aprovação':
      case 'Aguardando':
        return const Color(0xFFFFA726);
      case 'Fechado':
        return const Color(0xFF9E9E9E);
      case 'Rejeitado':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: fontSize + 2, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
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
