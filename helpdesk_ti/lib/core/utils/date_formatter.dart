import 'package:intl/intl.dart';

/// Utilitário para formatação de datas relativas
/// 
/// Converte timestamps em strings amigáveis como:
/// - "Agora" (menos de 1 minuto)
/// - "5min" (minutos)
/// - "2h" (horas)
/// - "Hoje 14:30" (hoje)
/// - "Ontem 09:15" (ontem)
/// - "3d" (dias)
/// - "2sem" (semanas)
/// - "3m" (meses)
/// - "1a" (anos)
class DateFormatter {
  /// Formata uma data para exibição relativa
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Menos de 1 minuto
    if (difference.inSeconds < 60) {
      return 'Agora';
    }

    // Minutos (1-59)
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    }

    // Horas (1-23)
    if (difference.inHours < 24) {
      // Se for hoje, mostrar "Hoje HH:mm"
      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return 'Hoje ${DateFormat('HH:mm').format(date)}';
      }
      return '${difference.inHours}h';
    }

    // Ontem
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return 'Ontem ${DateFormat('HH:mm').format(date)}';
    }

    // Dias (2-6)
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    // Semanas (1-3)
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}sem';
    }

    // Meses (1-11)
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}m';
    }

    // Anos
    final years = (difference.inDays / 365).floor();
    return '${years}a';
  }

  /// Formata data completa (dd/MM/yyyy HH:mm)
  static String formatFull(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formata apenas data (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formata apenas hora (HH:mm)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Formata para exibição em cards de chamado
  /// 
  /// Retorna string amigável com contexto adicional:
  /// - "Criado agora"
  /// - "Atualizado há 5min"
  /// - "Criado hoje às 14:30"
  /// - "Atualizado há 3d"
  static String formatForCard(DateTime date, {String prefix = 'Atualizado'}) {
    final relative = formatRelative(date);
    
    if (relative == 'Agora') {
      return '$prefix agora';
    }
    
    if (relative.startsWith('Hoje') || relative.startsWith('Ontem')) {
      return '$prefix $relative';
    }
    
    return '$prefix há $relative';
  }

  /// Calcula tempo decorrido em formato legível
  /// 
  /// Exemplo: "2h 30min", "3d 5h", "1sem 2d"
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    }

    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}min';
    }

    if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }

    if (duration.inDays < 7) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }

    final weeks = (duration.inDays / 7).floor();
    final days = duration.inDays % 7;
    return days > 0 ? '${weeks}sem ${days}d' : '${weeks}sem';
  }

  /// Calcula tempo médio de resolução
  /// 
  /// Entrada: lista de durações em segundos
  /// Saída: string formatada (ex: "2h 15min")
  static String formatAverageResolutionTime(List<int> durationsInSeconds) {
    if (durationsInSeconds.isEmpty) return 'N/A';

    final sum = durationsInSeconds.reduce((a, b) => a + b);
    final average = sum / durationsInSeconds.length;
    final duration = Duration(seconds: average.round());

    return formatDuration(duration);
  }
}
