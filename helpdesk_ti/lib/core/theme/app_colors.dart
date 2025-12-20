import 'package:flutter/material.dart';

class AppColors {
  // Cores Primárias Modernas (Gradiente Azul Premium)
  static const Color primary = Color(0xFF1E88E5); // Azul Moderno
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Gradiente Principal
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cores Secundárias (Laranja Vibrante)
  static const Color accent = Color(0xFFFF6F00); // Laranja Premium
  static const Color accentLight = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFFFF6F00);

  // Status de Chamados
  static const Color statusOpen = Color(0xFF4CAF50); // Verde - Aberto
  static const Color statusInProgress = Color(
    0xFF2196F3,
  ); // Azul - Em Andamento
  static const Color statusPending = Color(
    0xFFFFC107,
  ); // Amarelo - Pendente Aprovação
  static const Color statusClosed = Color(0xFF9E9E9E); // Cinza - Fechado
  static const Color statusRejected = Color(0xFFf44336); // Vermelho - Rejeitado

  // Cores Neutras
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF424242);
  static const Color textPrimary = Color(0xFF212121); // Texto principal
  static const Color textSecondary = Color(0xFF757575); // Texto secundário

  // Cores de Feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFf44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}
