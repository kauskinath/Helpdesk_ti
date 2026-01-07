import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/services/secure_storage_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/core/utils/rate_limiter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = SecureStorageService();
  final _rateLimiter = AuthRateLimiter();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Carregar credenciais salvas de forma segura
  Future<void> _loadSavedCredentials() async {
    final credentials = await _secureStorage.loadCredentials();
    final rememberMe = credentials['rememberMe'] as bool? ?? false;
    final savedEmail = credentials['email'] as String?;
    final savedPassword = credentials['password'] as String?;

    if (rememberMe && savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        if (savedPassword != null) {
          _passwordController.text = savedPassword;
        }
        _rememberMe = true;
      });
    }
  }

  // Salvar ou limpar credenciais de forma segura
  Future<void> _saveCredentials() async {
    await _secureStorage.saveCredentials(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    // Verificar rate limit
    if (!_rateLimiter.canAttemptLogin(email)) {
      final remaining = _rateLimiter.getLoginBlockTimeRemaining(email);
      setState(() {
        _errorMessage =
            'Muitas tentativas de login. Tente novamente em ${remaining?.inMinutes ?? 30} minutos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.login(email: email, password: _passwordController.text);

      // Login bem-sucedido - resetar rate limiter
      _rateLimiter.resetLoginAttempts(email);

      // Salvar credenciais se "Lembrar-me" estiver marcado
      await _saveCredentials();

      // Login bem-sucedido - NÃO resetar loading
      // O AuthWrapper detectará a mudança e navegará automaticamente
      // Resetar o loading causaria conflito visual com a navegação
    } catch (e) {
      // Registrar tentativa falha
      final canContinue = _rateLimiter.recordFailedLogin(email);
      final attemptsRemaining = _rateLimiter.getLoginAttemptsRemaining(email);

      if (!mounted) return;

      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (!canContinue) {
        final remaining = _rateLimiter.getLoginBlockTimeRemaining(email);
        errorMsg =
            'Conta bloqueada temporariamente. Tente novamente em ${remaining?.inMinutes ?? 30} minutos.';
      } else if (attemptsRemaining <= 2) {
        errorMsg += '\n⚠️ $attemptsRemaining tentativas restantes.';
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  /// Mostra dialog para recuperação de senha
  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: Color(0xFF1E88E5)),
            const SizedBox(width: 12),
            Text(
              'Recuperar Senha',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digite seu email para receber o link de recuperação de senha:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite seu email';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'seu.email@empresa.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(context); // Fechar dialog primeiro

              // Enviar email de recuperação
              await _resetPassword(emailController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Enviar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Envia email de recuperação de senha via Firebase Auth
  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Email de recuperação enviado! Verifique sua caixa de entrada.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email não encontrado no sistema.';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido.';
          break;
        case 'too-many-requests':
          errorMessage = 'Muitas tentativas. Aguarde alguns minutos.';
          break;
        default:
          errorMessage = 'Erro ao enviar email: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      body: Container(
        color: isDarkMode ? DS.background : const Color(0xFFF5F7FA),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo com animação
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/images/pombo_logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nome do App
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Pichau TI',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          letterSpacing: 1.2,
                          shadows: isDarkMode
                              ? [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    offset: const Offset(0, 1),
                                    blurRadius: 8,
                                  ),
                                ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtítulo
                    FadeInDown(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        'Sistema de Suporte Técnico',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black87.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                          shadows: isDarkMode
                              ? null
                              : [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    offset: const Offset(0, 1),
                                    blurRadius: 6,
                                  ),
                                ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Card de Login
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Campo Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.black87),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Digite seu email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(
                                  color: Colors.black54,
                                ),
                                hintText: 'seu.email@empresa.com',
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black26,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black26,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1E88E5),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Campo Senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.black87),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Digite sua senha';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                labelStyle: const TextStyle(
                                  color: Colors.black54,
                                ),
                                hintText: '••••••••',
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outlined,
                                  color: Colors.black54,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black26,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black26,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1E88E5),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Checkbox Lembrar-me
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF1E88E5),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: Text(
                                      'Lembrar meus dados de login',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Mensagem de Erro
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Botão de Login
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Entrar',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 16),

                            // Esqueceu a senha
                            TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'Esqueceu sua senha?',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF1E88E5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Rodapé
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '© 2024 Pichau TI',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Desenvolvido por MATA-TI',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
