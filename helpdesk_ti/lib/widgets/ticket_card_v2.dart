import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/core/utils/date_formatter.dart';

/// TicketCard V2 - Design System Novo
///
/// Layout:
/// - Fundo #1A1C1E, borda #2C2F33, radius 12px
/// - Barra de prioridade 3px à esquerda
/// - Linha 1: ID à esquerda, Status à direita (11px, cinza)
/// - Linha 2: Título (16px, bold, branco)
/// - Linha 3: Ícone usuário + nome (12px)
/// - Badge de prioridade no canto superior direito
class TicketCardV2 extends StatelessWidget {
  final String? numeroFormatado;
  final String titulo;
  final String status;
  final int prioridade;
  final String? usuarioNome;
  final String? setorNome;
  final DateTime? lastUpdated;
  final int numeroComentarios;
  final bool temAnexos;
  final VoidCallback? onTap;

  const TicketCardV2({
    super.key,
    this.numeroFormatado,
    required this.titulo,
    required this.status,
    required this.prioridade,
    this.usuarioNome,
    this.setorNome,
    this.lastUpdated,
    this.numeroComentarios = 0,
    this.temAnexos = false,
    this.onTap,
  });

  Color get _prioridadeColor {
    switch (prioridade) {
      case 4:
        return DS.prioridadeAlta; // Crítica
      case 3:
        return const Color(0xFFFF9800); // Alta - Laranja
      case 2:
        return DS.prioridadeMedia; // Média
      case 1:
      default:
        return DS.prioridadeBaixa; // Baixa
    }
  }

  String get _prioridadeLabel {
    switch (prioridade) {
      case 4:
        return 'CRÍTICA';
      case 3:
        return 'Alta';
      case 2:
        return 'Média';
      case 1:
      default:
        return 'Baixa';
    }
  }

  String _getTimeAgo() {
    if (lastUpdated == null) return '';
    return DateFormatter.formatRelative(lastUpdated!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Stack(
          children: [
            // Card principal com barra de prioridade
            Row(
              children: [
                // Barra de prioridade (3px à esquerda)
                Container(
                  width: 3,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _prioridadeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(DS.cardRadius),
                      bottomLeft: Radius.circular(DS.cardRadius),
                    ),
                  ),
                ),
                // Card principal
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 100),
                    decoration: BoxDecoration(
                      color: DS.card,
                      border: Border.all(color: DS.border, width: 1),
                      borderRadius: BorderRadius.circular(DS.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Linha 1: ID à esquerda, Status + Prioridade à direita
                          Row(
                            children: [
                              if (numeroFormatado != null)
                                Text(
                                  numeroFormatado!,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: DS.textSecondary,
                                  ),
                                ),
                              const Spacer(),
                              // Status
                              Text(
                                status,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: DS.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge de prioridade inline
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _prioridadeColor.withAlpha(38),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _prioridadeLabel,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _prioridadeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Linha 2: Título
                          Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DS.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Linha 3: Setor (ou usuário se não tiver setor)
                          Row(
                            children: [
                              Icon(
                                setorNome != null
                                    ? Icons.business
                                    : Icons.person_outline,
                                size: 16,
                                color: DS.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  setorNome ?? usuarioNome ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: DS.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Indicadores
                              if (temAnexos) ...[
                                const Icon(
                                  Icons.attach_file,
                                  size: 14,
                                  color: DS.textSecondary,
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (lastUpdated != null) ...[
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: DS.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _getTimeAgo(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: DS.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
