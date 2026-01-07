import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gerenciar o tema da aplicação (Claro/Escuro)
///
/// **Funcionalidades:**
/// - Alternar entre tema claro e escuro
/// - Salvar preferência do usuário (persiste ao reiniciar app)
/// - Notificar mudanças para toda a aplicação
///
/// **Como usar:**
/// ```dart
/// // No main.dart
/// ChangeNotifierProvider(
///   create: (_) => ThemeProvider(),
///   child: MyApp(),
/// )
///
/// // Em qualquer widget
/// final themeProvider = context.watch<ThemeProvider>();
/// bool isDark = themeProvider.isDarkMode;
///
/// // Alternar tema
/// themeProvider.toggleTheme();
/// ```
class ThemeProvider extends ChangeNotifier {
  // Chave para salvar no SharedPreferences
  static const String _themeKey = 'theme_mode';

  // Estado do tema (true = escuro, false = claro)
  bool _isDarkMode = false;

  // Indica se já carregou a preferência salva
  bool _isLoaded = false;

  /// Retorna se o tema escuro está ativo
  bool get isDarkMode => _isDarkMode;

  /// Retorna se já carregou as preferências
  bool get isLoaded => _isLoaded;

  /// Retorna o ThemeMode atual
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Construtor - Carrega preferência salva automaticamente
  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  /// Carrega a preferência de tema salva
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Buscar tema salvo (padrão: claro)
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _isLoaded = true;

      print('🎨 Tema carregado: ${_isDarkMode ? "Escuro" : "Claro"}');

      // Notificar mudança
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar tema: $e');
      _isDarkMode = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Alterna entre tema claro e escuro
  Future<void> toggleTheme() async {
    try {
      // Inverter estado
      _isDarkMode = !_isDarkMode;

      print('🎨 Alternando tema para: ${_isDarkMode ? "Escuro" : "Claro"}');

      // Salvar preferência
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);

      // Notificar mudança (atualiza UI)
      notifyListeners();

      print('✅ Tema salvo com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar tema: $e');
      // Reverter mudança em caso de erro
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }

  /// Define o tema manualmente (sem toggle)
  ///
  /// [isDark] - true para tema escuro, false para claro
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return; // Já está no tema desejado

    try {
      _isDarkMode = isDark;

      print('🎨 Definindo tema: ${_isDarkMode ? "Escuro" : "Claro"}');

      // Salvar preferência
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);

      // Notificar mudança
      notifyListeners();

      print('✅ Tema salvo com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar tema: $e');
      // Reverter mudança
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }

  /// Reseta o tema para o padrão (claro)
  Future<void> resetTheme() async {
    await setTheme(false);
  }
}
