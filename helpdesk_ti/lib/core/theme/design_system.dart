import 'package:flutter/material.dart';

/// Design System centralizado para o Helpdesk TI/Manutenção
/// Siga este padrão em TODO o app para máxima consistência visual.
class DS {
  // Paleta de Cores
  static const Color background = Color(0xFF0F1113); // Quase preto
  static const Color card = Color(0xFF1A1C1E); // Cinza-azulado profundo
  static const Color border = Color(0xFF2C2F33); // Borda sólida
  static const Color divider = Color(0xFF3D4248); // Divisória menus
  static const Color textPrimary = Color(0xFFFFFFFF); // Branco puro
  static const Color textSecondary = Color(0xFF9BA1A6); // Cinza médio
  static const Color textTertiary = Color(0xFFD1D5D8); // Cinza claro
  static const Color textSystem = Color(0xFF7D848C); // Cinza suave
  static const Color action = Color(0xFF007AFF); // Azul principal
  static const Color userBubble = Color(0xFF2F3337); // Balão usuário
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF00BCD4); // Cyan para informações
  // Prioridades (exemplo)
  static const Color prioridadeAlta = Color(0xFFF44336);
  static const Color prioridadeMedia = Color(0xFFFFC107);
  static const Color prioridadeBaixa = Color(0xFF4CAF50);

  // Radius
  static const double cardRadius = 12.0;
  static const double buttonRadius = 16.0;
  static const double inputRadius = 16.0;

  // Tipografia
  static const String fontFamily =
      'Inter'; // Troque para 'PlusJakartaSans' se preferir

  static TextStyle get title => const TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: textPrimary,
  );
  static TextStyle get subtitle => const TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: textPrimary,
  );
  static TextStyle get body => const TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 12,
    color: textPrimary,
  );
  static TextStyle get caption => const TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: textSecondary,
  );
  static TextStyle get systemLog => const TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: textSystem,
    height: 1.2,
  );
  static TextStyle get userName => const TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: textTertiary,
  );

  // Utilitários de borda
  static Border cardBorder = Border.all(color: border, width: 1);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);
  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(buttonRadius);
  static BorderRadius get inputBorderRadius =>
      BorderRadius.circular(inputRadius);
}
