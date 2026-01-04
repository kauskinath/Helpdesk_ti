import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../widgets/avaliacao_manutencao_widget.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../executor/manutencao_executar_screen.dart';
import '../admin/manutencao_validar_chamado_screen.dart';
import '../admin/manutencao_atribuir_executor_screen.dart';

/// Tela de detalhes do chamado de manutenção
class ManutencaoDetalhesChamadoScreen extends StatelessWidget {
  final String chamadoId;

  const ManutencaoDetalhesChamadoScreen({super.key, required this.chamadoId});

  @override
  Widget build(BuildContext context) {
    final manutencaoService = ManutencaoService();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final authService = context.watch<AuthService>();
    final isAdminManutencao = authService.userRole == 'admin_manutencao';
    final isExecutor = authService.userRole == 'executor';
    final userId = authService.firebaseUser?.uid;

    // DEBUG: Print para verificar
    print('🔍 DEBUG BOTÕES:');
    print('   isExecutor: $isExecutor');
    print('   userId: $userId');
    print('   userRole: ${authService.userRole}');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isDarkMode
                  ? 'assets/images/wallpaper_dark.png'
                  : 'assets/images/wallpaper_light.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<ChamadoManutencao>(
            future: manutencaoService.getChamadoById(chamadoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Erro: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final chamado = snapshot.data!;
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chamado.numeroFormatado,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        // Botão de deletar (apenas para admin_manutencao)
                        if (isAdminManutencao)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () =>
                                  _confirmarExclusao(context, chamado.id),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 28,
                              ),
                              tooltip: 'Deletar chamado',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Conteúdo
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(context, chamado, isDarkMode),

                          // Botões de ação para ADMIN MANUTENÇÃO
                          if (isAdminManutencao)
                            _buildBotoesAdminManutencao(
                              context,
                              chamado,
                              manutencaoService,
                              isDarkMode,
                            ),

                          // Botões de ação para EXECUTOR
                          if (isExecutor &&
                              chamado.execucao?.executorId == userId)
                            _buildBotoesExecutor(
                              context,
                              chamado,
                              manutencaoService,
                            ),

                          // Widget de avaliação (apenas para o criador do chamado quando finalizado)
                          if (chamado.criadorId == userId &&
                              chamado.status ==
                                  StatusChamadoManutencao.finalizado)
                            AvaliacaoManutencaoWidget(
                              chamado: chamado,
                              onAvaliacaoEnviada: () {
                                // Pode recarregar a tela se necessário
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(StatusChamadoManutencao status) {
    final hexColor = status.colorHex.replaceAll('#', '');
    return Color(int.parse('0xFF$hexColor'));
  }

  Widget _buildInfoCard(
    BuildContext context,
    ChamadoManutencao chamado,
    bool isDarkMode,
  ) {
    final statusColor = _getStatusColor(chamado.status);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data de criação
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Text(
                'Criado em ${DateFormat('dd/MM/yyyy \'às\' HH:mm').format(chamado.dataAbertura)}',
                style: TextStyle(fontSize: 13, color: secondaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Última atualização
          if (chamado.dataFinalizacao != null)
            Row(
              children: [
                const Icon(Icons.update, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Finalizado em ${DateFormat('dd/MM/yyyy \'às\' HH:mm').format(chamado.dataFinalizacao!)}',
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chamado.status.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  chamado.status.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Text(
            chamado.titulo,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Informações básicas
          _buildInfoRow(
            context,
            Icons.person,
            'Solicitante',
            chamado.criadorNome,
            isDarkMode,
          ),
          _buildInfoRow(
            context,
            Icons.description,
            'Descrição',
            chamado.descricao,
            isDarkMode,
          ),

          // Validação
          if (chamado.precisaValidacao) ...[
            const Divider(height: 32),
            Text(
              '🔍 VALIDAÇÃO DO SUPERVISOR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              chamado.validado ? Icons.check_circle : Icons.pending,
              'Status',
              chamado.validado ? '✅ Validado' : '⏳ Aguardando validação',
              isDarkMode,
            ),
            if (chamado.adminValidadorNome != null)
              _buildInfoRow(
                context,
                Icons.person,
                'Validado por',
                chamado.adminValidadorNome!,
                isDarkMode,
              ),
            if (chamado.dataValidacao != null)
              _buildInfoRow(
                context,
                Icons.calendar_today,
                'Data da Validação',
                DateFormat(
                  'dd/MM/yyyy \'às\' HH:mm',
                ).format(chamado.dataValidacao!),
                isDarkMode,
              ),
          ],

          // Orçamento
          if (chamado.orcamento != null) ...[
            const Divider(height: 32),
            Text(
              '💰 ORÇAMENTO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            if (chamado.orcamento!.valorEstimado != null)
              _buildInfoRow(
                context,
                Icons.attach_money,
                'Valor Estimado',
                'R\$ ${chamado.orcamento!.valorEstimado!.toStringAsFixed(2)}',
                isDarkMode,
              ),
            if (chamado.orcamento!.arquivoUrl != null)
              _buildLinkButton(
                context,
                '📄 Visualizar Orçamento',
                chamado.orcamento!.arquivoUrl!,
              ),
            if (chamado.orcamento!.itens.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '📦 Materiais:',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              ...chamado.orcamento!.itens.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item, style: TextStyle(color: textColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],

          // Fotos do Local
          if (chamado.fotosUrls.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              '📸 FOTOS DO LOCAL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: chamado.fotosUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _mostrarFotoCompleta(
                        context,
                        chamado.fotosUrls,
                        index,
                      ),
                      child: Hero(
                        tag: 'foto_${chamado.id}_$index',
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: chamado.fotosUrls[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade300,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Erro ao carregar',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${chamado.fotosUrls.length} foto(s) • Toque para ampliar',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Aprovação do Gerente
          if (chamado.aprovacaoGerente != null) ...[
            const Divider(height: 32),
            Text(
              chamado.aprovacaoGerente!.aprovado
                  ? '✅ APROVAÇÃO DO GERENTE'
                  : '❌ ORÇAMENTO REJEITADO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: chamado.aprovacaoGerente!.aprovado
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.person,
              'Gerente',
              chamado.aprovacaoGerente!.gerenteNome,
              isDarkMode,
            ),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Data',
              DateFormat(
                'dd/MM/yyyy \'às\' HH:mm',
              ).format(chamado.aprovacaoGerente!.dataAprovacao),
              isDarkMode,
            ),
            if (!chamado.aprovacaoGerente!.aprovado &&
                chamado.aprovacaoGerente!.motivoRejeicao != null)
              _buildInfoRow(
                context,
                Icons.warning,
                'Motivo da Rejeição',
                chamado.aprovacaoGerente!.motivoRejeicao!,
                isDarkMode,
                isAlert: true,
              ),
          ],

          // Compra
          if (chamado.compra != null) ...[
            const Divider(height: 32),
            Text(
              '🛒 COMPRA DE MATERIAIS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.shopping_cart,
              'Status da Compra',
              chamado.compra!.statusCompra == StatusCompra.naoIniciado
                  ? '⏸️ Não iniciado'
                  : chamado.compra!.statusCompra == StatusCompra.emAndamento
                  ? '🛒 Em andamento'
                  : '✅ Concluído',
              isDarkMode,
            ),
            if (chamado.compra!.dataChegadaMateriais != null)
              _buildInfoRow(
                context,
                Icons.calendar_today,
                'Materiais Chegaram em',
                DateFormat(
                  'dd/MM/yyyy \'às\' HH:mm',
                ).format(chamado.compra!.dataChegadaMateriais!),
                isDarkMode,
              ),
            if (chamado.compra!.notasFiscaisUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '📑 Notas Fiscais:',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              ...chamado.compra!.notasFiscaisUrls.asMap().entries.map(
                (entry) => _buildLinkButton(
                  context,
                  '📄 Nota Fiscal ${entry.key + 1}',
                  entry.value,
                ),
              ),
            ],
          ],

          // Execução
          if (chamado.execucao != null) ...[
            const Divider(height: 32),
            Text(
              '🔧 EXECUÇÃO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.engineering,
              'Executor',
              chamado.execucao!.executorNome,
              isDarkMode,
            ),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Atribuído em',
              DateFormat(
                'dd/MM/yyyy \'às\' HH:mm',
              ).format(chamado.execucao!.dataAtribuicao),
              isDarkMode,
            ),
            if (chamado.execucao!.dataInicio != null)
              _buildInfoRow(
                context,
                Icons.play_arrow,
                'Iniciado em',
                DateFormat(
                  'dd/MM/yyyy \'às\' HH:mm',
                ).format(chamado.execucao!.dataInicio!),
                isDarkMode,
              ),
            if (chamado.execucao!.dataFim != null)
              _buildInfoRow(
                context,
                Icons.check,
                'Finalizado em',
                DateFormat(
                  'dd/MM/yyyy \'às\' HH:mm',
                ).format(chamado.execucao!.dataFim!),
                isDarkMode,
              ),
            if (chamado.execucao!.fotoComprovanteUrl != null)
              _buildLinkButton(
                context,
                '📷 Ver Foto Comprovante',
                chamado.execucao!.fotoComprovanteUrl!,
              ),
          ],

          // Recusa
          if (chamado.recusa != null) ...[
            const Divider(height: 32),
            const Text(
              '🚫 RECUSA DO EXECUTOR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.person,
              'Executor',
              chamado.recusa!.executorNome,
              isDarkMode,
            ),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Data da Recusa',
              DateFormat(
                'dd/MM/yyyy \'às\' HH:mm',
              ).format(chamado.recusa!.dataRecusa),
              isDarkMode,
            ),
            _buildInfoRow(
              context,
              Icons.warning,
              'Motivo',
              chamado.recusa!.motivo,
              isDarkMode,
              isAlert: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String valor,
    bool isDarkMode, {
    bool isAlert = false,
  }) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final labelColor = isDarkMode ? Colors.white60 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isAlert ? Colors.red : labelColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 15,
                    color: isAlert ? Colors.red : textColor,
                    fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String label, String url) {
    // Detectar tipo de arquivo pela extensão
    final urlLower = url.toLowerCase();
    final isImage = urlLower.contains(RegExp(r'\.(jpg|jpeg|png|gif|webp)'));
    final isPdf = urlLower.contains('.pdf');
    final isWord = urlLower.contains(RegExp(r'\.(doc|docx)'));
    final isExcel = urlLower.contains(RegExp(r'\.(xls|xlsx)'));
    final isPowerPoint = urlLower.contains(RegExp(r'\.(ppt|pptx)'));
    final isText = urlLower.contains('.txt');

    // Escolher ícone e cor apropriados
    IconData icon;
    Color? iconColor;

    if (isImage) {
      icon = Icons.image;
      iconColor = Colors.blue;
    } else if (isPdf) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (isWord) {
      icon = Icons.description;
      iconColor = Colors.blue[700];
    } else if (isExcel) {
      icon = Icons.table_chart;
      iconColor = Colors.green[700];
    } else if (isPowerPoint) {
      icon = Icons.slideshow;
      iconColor = Colors.orange[700];
    } else if (isText) {
      icon = Icons.text_snippet;
      iconColor = Colors.grey[700];
    } else {
      icon = Icons.open_in_new;
      iconColor = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          if (isImage) {
            // Mostrar imagem em tela cheia com zoom
            _mostrarImagemCompleta(context, url, label);
          } else {
            // Abrir qualquer outro arquivo (PDF, DOCX, etc.) no app externo
            try {
              print('🔗 Tentando abrir URL: $url');
              final uri = Uri.parse(url);
              print('📱 URI parseada: $uri');

              final result = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );

              print('✅ Launch result: $result');

              if (!result && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '❌ Falha ao abrir arquivo.\nVerifique se há um app instalado para abrir este tipo de arquivo.',
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
              print('❌ Erro ao abrir arquivo: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Erro ao abrir arquivo: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          }
        },
        icon: Icon(icon, size: 18, color: iconColor),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _mostrarImagemCompleta(BuildContext context, String url, String titulo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Erro ao carregar imagem',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botões de ação para o ADMIN MANUTENÇÃO
  Widget _buildBotoesAdminManutencao(
    BuildContext context,
    ChamadoManutencao chamado,
    ManutencaoService manutencaoService,
    bool isDarkMode,
  ) {
    final status = chamado.status;

    // DEBUG: Verificar condições
    print('🔧 DEBUG ADMIN MANUTENCAO:');
    print('   Status: ${status.value}');
    print('   precisaValidacao: ${chamado.precisaValidacao}');
    print('   validado: ${chamado.validado}');
    print('   execucao: ${chamado.execucao}');

    // Precisa validar: chamado aberto que ainda não foi validado
    final precisaValidacao =
        !chamado.validado &&
        (status == StatusChamadoManutencao.aberto ||
            status == StatusChamadoManutencao.emValidacaoAdmin);

    // Pode atribuir executor: já validado ou não precisa validação, sem executor atribuído
    final podeAtribuirExecutor =
        chamado.execucao == null &&
        (status == StatusChamadoManutencao.liberadoParaExecucao ||
            (chamado.validado && status != StatusChamadoManutencao.cancelado));

    print('   precisaValidacao (calc): $precisaValidacao');
    print('   podeAtribuirExecutor (calc): $podeAtribuirExecutor');

    // Se não há ações disponíveis, não mostrar nada
    if (!precisaValidacao && !podeAtribuirExecutor) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card de informação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    precisaValidacao
                        ? 'Este chamado aguarda sua validação'
                        : 'Este chamado precisa de um executor',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // VALIDAR CHAMADO
          if (precisaValidacao) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ManutencaoValidarChamadoScreen(chamado: chamado),
                        ),
                      );
                      if (result == true && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'VALIDAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _rejeitarChamado(context, chamado, manutencaoService),
                    icon: const Icon(Icons.cancel, size: 24),
                    label: const Text(
                      'REJEITAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ATRIBUIR EXECUTOR
          if (podeAtribuirExecutor) ...[
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ManutencaoAtribuirExecutorScreen(chamado: chamado),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.person_add, size: 24),
              label: const Text(
                'ATRIBUIR EXECUTOR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Rejeitar chamado diretamente
  Future<void> _rejeitarChamado(
    BuildContext context,
    ChamadoManutencao chamado,
    ManutencaoService manutencaoService,
  ) async {
    // Capturar referências ANTES de qualquer await
    final authService = context.read<AuthService>();
    final user = authService.firebaseUser;
    final userName = authService.userName ?? user?.email ?? 'Admin';
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (user == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('❌ Usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Rejeitar Chamado?'),
          ],
        ),
        content: const Text(
          'Confirma a rejeição deste chamado?\n\nEle será cancelado e o solicitante será notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await manutencaoService.validarChamado(
        chamadoId: chamado.id,
        adminId: user.uid,
        adminNome: userName,
        aprovado: false,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('❌ Chamado rejeitado'),
          backgroundColor: Colors.red,
        ),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('❌ Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Botões de ação para o EXECUTOR
  Widget _buildBotoesExecutor(
    BuildContext context,
    ChamadoManutencao chamado,
    ManutencaoService manutencaoService,
  ) {
    final status = chamado.status;
    final authService = context.watch<AuthService>();
    final userId = authService.firebaseUser?.uid;

    // DEBUG: Verificar IDs
    print('🎯 DEBUG EXECUTOR:');
    print('   executorId do chamado: ${chamado.execucao?.executorId}');
    print('   userId logado: $userId');
    print('   Status: ${status.value}');
    print('   Match: ${chamado.execucao?.executorId == userId}');

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card de informação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Você é o executor atribuído a este chamado',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // INICIAR TRABALHO
          if (status == StatusChamadoManutencao.atribuidoExecutor)
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ManutencaoExecutarScreen(chamado: chamado),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text(
                'INICIAR TRABALHO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          // TRABALHO EM EXECUÇÃO - Botões de pausar/finalizar
          if (status == StatusChamadoManutencao.emExecucao) ...[
            Row(
              children: [
                // Botão PAUSAR
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await manutencaoService.pausarExecucao(chamado.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⏸️ Trabalho pausado'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('PAUSAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botão FINALIZAR
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ManutencaoExecutarScreen(chamado: chamado),
                        ),
                      );
                      if (result == true && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'FINALIZAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Botão RECUSAR removido - executores não podem mais recusar trabalhos
          ],
        ],
      ),
    );
  }

  /// Confirma exclusão do chamado
  Future<void> _confirmarExclusao(
    BuildContext context,
    String chamadoId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja deletar este chamado?\n\n'
          'Esta ação irá remover:\n'
          '• O chamado do Firestore\n'
          '• Todos os comentários\n'
          '• Todos os arquivos do Storage\n\n'
          '⚠️ ESTA AÇÃO NÃO PODE SER DESFEITA!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final manutencaoService = ManutencaoService();
        await manutencaoService.deletarChamado(chamadoId);

        if (context.mounted) {
          Navigator.pop(context); // Fechar loading
          Navigator.pop(context); // Voltar para lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Chamado deletado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Fechar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao deletar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Mostra a foto em tela cheia com navegação entre fotos
  static void _mostrarFotoCompleta(
    BuildContext context,
    List<String> fotosUrls,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FotoCompletaScreen(
          fotosUrls: fotosUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Tela para visualizar foto em tela cheia com navegação
class _FotoCompletaScreen extends StatefulWidget {
  final List<String> fotosUrls;
  final int initialIndex;

  const _FotoCompletaScreen({
    required this.fotosUrls,
    required this.initialIndex,
  });

  @override
  State<_FotoCompletaScreen> createState() => _FotoCompletaScreenState();
}

class _FotoCompletaScreenState extends State<_FotoCompletaScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Foto ${_currentIndex + 1} de ${widget.fotosUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.fotosUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'foto_${widget.fotosUrls[index]}_$index',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: widget.fotosUrls[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Erro ao carregar foto',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Navegação anterior
          if (_currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          // Navegação próxima
          if (_currentIndex < widget.fotosUrls.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
