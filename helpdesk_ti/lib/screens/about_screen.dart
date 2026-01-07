import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Carregando...';
  String _buildNumber = '';
  bool _isCheckingUpdate = false;
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _version = 'Erro ao carregar';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      // Inicializar Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Configurar para buscar atualizações rapidamente (modo desenvolvimento)
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero, // Sem cache durante testes
        ),
      );

      // Definir valores padrão
      await remoteConfig.setDefaults({
        'latest_version': '1.0.0',
        'latest_build_number': '2002',
        'download_url': '',
        'release_notes': 'Nenhuma atualização disponível',
        'force_update': false,
      });

      // Buscar valores do servidor Firebase
      await remoteConfig.fetchAndActivate();

      if (!mounted) return;

      // Ler valores
      final serverVersion = remoteConfig.getString('latest_version');
      final serverBuild = remoteConfig.getString('latest_build_number');
      final downloadUrl = remoteConfig.getString('download_url');
      final releaseNotes = remoteConfig.getString('release_notes');
      final forceUpdate = remoteConfig.getBool('force_update');

      // Comparar versões
      final currentVersionParts = _version.split('.');
      final serverVersionParts = serverVersion.split('.');

      bool needsUpdate = false;

      // Comparação simples de versões
      for (int i = 0; i < 3; i++) {
        final current =
            int.tryParse(
              i < currentVersionParts.length ? currentVersionParts[i] : '0',
            ) ??
            0;
        final server =
            int.tryParse(
              i < serverVersionParts.length ? serverVersionParts[i] : '0',
            ) ??
            0;

        if (server > current) {
          needsUpdate = true;
          break;
        } else if (server < current) {
          break;
        }
      }

      // Verificar build number se versões iguais
      if (!needsUpdate && serverBuild != _buildNumber) {
        final currentBuild = int.tryParse(_buildNumber) ?? 0;
        final serverBuildNum = int.tryParse(serverBuild) ?? 0;
        needsUpdate = serverBuildNum > currentBuild;
      }

      setState(() {
        _isCheckingUpdate = false;
      });

      if (needsUpdate) {
        _showUpdateAvailableDialog(
          serverVersion,
          serverBuild,
          releaseNotes,
          downloadUrl.isNotEmpty ? downloadUrl : null,
          forceUpdate,
        );
      } else {
        _showUpToDateDialog();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCheckingUpdate = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Erro'),
            ],
          ),
          content: Text(
            'Não foi possível verificar atualizações.\n\n'
            'Detalhes: ${e.toString()}\n\n'
            'Verifique sua conexão com a internet.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showUpToDateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Atualizado'),
          ],
        ),
        content: Text(
          '✅ Você está usando a versão mais recente!\n\n'
          'Versão atual: $_version (Build $_buildNumber)',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUpdateAvailableDialog(
    String newVersion,
    String newBuild,
    String? releaseNotes,
    String? downloadUrl,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(
                forceUpdate ? Icons.warning : Icons.system_update,
                color: forceUpdate ? Colors.orange : Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  forceUpdate
                      ? 'Atualização Obrigatória'
                      : 'Nova Versão Disponível',
                  style: GoogleFonts.poppins(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🆕 Versão: $newVersion (Build $newBuild)',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '📦 Atual: $_version (Build $_buildNumber)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (releaseNotes != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '📝 Novidades:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(releaseNotes, style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Depois'),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                if (downloadUrl != null) {
                  await _downloadUpdate(downloadUrl);
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Baixar Agora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadUpdate(String url) async {
    try {
      print('🔗 Tentando abrir URL: $url');

      // Validar URL
      if (url.isEmpty) {
        throw Exception('URL vazia');
      }

      final uri = Uri.parse(url);
      print('📋 URI parseada: $uri');
      print('   Scheme: ${uri.scheme}');
      print('   Host: ${uri.host}');
      print('   Path: ${uri.path}');

      // Tentar abrir de diferentes formas
      bool launched = false;

      // Método 1: ExternalApplication (abre navegador)
      try {
        print('🌐 Tentativa 1: Abrindo no navegador externo...');
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Método 1: ${launched ? "Sucesso" : "Falhou"}');
      } catch (e) {
        print('❌ Método 1 falhou: $e');
      }

      // Método 2: ExternalNonBrowserApplication (para downloads)
      if (!launched) {
        try {
          print('📥 Tentativa 2: Abrindo como download...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          print('✅ Método 2: ${launched ? "Sucesso" : "Falhou"}');
        } catch (e) {
          print('❌ Método 2 falhou: $e');
        }
      }

      // Método 3: PlatformDefault (deixa o sistema decidir)
      if (!launched) {
        try {
          print('📱 Tentativa 3: Deixando o sistema decidir...');
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          print('✅ Método 3: ${launched ? "Sucesso" : "Falhou"}');
        } catch (e) {
          print('❌ Método 3 falhou: $e');
        }
      }

      if (!launched) {
        throw Exception('Nenhum método conseguiu abrir o link');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.download_done, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Download Iniciado!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ O arquivo APK está sendo baixado.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('📱 Próximos passos:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Abra a barra de notificações',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Toque em "app-release.apk"',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Confirme a instalação',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ Se necessário, autorize "Instalar apps desconhecidos" nas configurações.',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Erro geral ao abrir link: $e');
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Text('Erro ao Baixar'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Não foi possível iniciar o download automaticamente.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('💡 Solução:'),
              const SizedBox(height: 8),
              const Text('1. Copie o link abaixo'),
              const Text('2. Cole no navegador Chrome'),
              const Text('3. O download iniciará'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Sobre',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: isDarkMode ? DS.background : const Color(0xFFF5F7FA),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

                return Column(
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
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
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nome do App
                    Text(
                      'Pichau TI',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.displayLarge?.color,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Versão
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Text(
                        'Versão $_version (Build $_buildNumber)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botão Verificar Atualização
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                        icon: _isCheckingUpdate
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.system_update),
                        label: Text(
                          _isCheckingUpdate
                              ? 'Verificando...'
                              : 'Verificar Atualização',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Card de Informações
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            '📱 Sistema de Suporte Técnico',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Descrição
                          Text(
                            'Aplicativo desenvolvido para gerenciar chamados de suporte técnico da Pichau. Sistema completo de tickets, notificações e acompanhamento.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Desenvolvedor
                          _buildInfoRow(
                            icon: Icons.code,
                            label: 'Desenvolvedor',
                            value: 'MATA-TI',
                          ),

                          const SizedBox(height: 12),

                          // Empresa
                          _buildInfoRow(
                            icon: Icons.business,
                            label: 'Empresa',
                            value: 'Pichau Informática',
                          ),

                          const SizedBox(height: 12),

                          // Ano
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Ano',
                            value: '2024',
                          ),

                          const SizedBox(height: 12),

                          // Tecnologia
                          _buildInfoRow(
                            icon: Icons.flutter_dash,
                            label: 'Tecnologia',
                            value: 'Flutter + Firebase',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recursos
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✨ Recursos Principais',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeature('📋', 'Gestão de chamados'),
                          _buildFeature('🔔', 'Notificações em tempo real'),
                          _buildFeature('👥', 'Múltiplos níveis de acesso'),
                          _buildFeature('📊', 'Relatórios e estatísticas'),
                          _buildFeature('🔒', 'Autenticação segura'),
                          _buildFeature('☁️', 'Armazenamento em nuvem'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Rodapé
                    Text(
                      '© 2024 Pichau TI - Todos os direitos reservados',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.iconTheme.color, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(String emoji, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
