import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

/// Card unificado para chamados TI e Manutenção
/// Segue o padrão visual solicitado
class ChamadoCard extends StatelessWidget {
  final String id;
  final String status;
  final String titulo;
  final String usuarioNome;
  final int prioridade; // 1=Baixa, 2=Média, 3=Alta, 4=Crítica
  final VoidCallback? onTap;

  const ChamadoCard({
    super.key,
    required this.id,
    required this.status,
    required this.titulo,
    required this.usuarioNome,
    required this.prioridade,
    this.onTap,
  });

  Color get prioridadeColor {
    switch (prioridade) {
      case 3:
      case 4:
        return DS.prioridadeAlta;
      case 2:
        return DS.prioridadeMedia;
      case 1:
      default:
        return DS.prioridadeBaixa;
    }
  }

  String get prioridadeLabel {
    switch (prioridade) {
      case 4:
        return 'Crítica';
      case 3:
        return 'Alta';
      case 2:
        return 'Média';
      case 1:
      default:
        return 'Baixa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Stack(
        children: [
          Row(
            children: [
              // Barra de prioridade
              Container(
                width: 3,
                height: 96,
                decoration: BoxDecoration(
                  color: prioridadeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(DS.cardRadius),
                    bottomLeft: Radius.circular(DS.cardRadius),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: DS.card,
                      border: DS.cardBorder,
                      borderRadius: BorderRadius.circular(DS.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Linha 1: ID e Status
                          Row(
                            children: [
                              Text(
                                '#$id',
                                style: DS.caption.copyWith(
                                  fontSize: 11,
                                  color: DS.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                status,
                                style: DS.caption.copyWith(
                                  fontSize: 11,
                                  color: DS.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Linha 2: Título
                          Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DS.title.copyWith(
                              fontSize: 16,
                              color: DS.textPrimary,
                            ),
                          ),
                          // Linha 3: Usuário
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: DS.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  usuarioNome,
                                  style: DS.userName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Badge de prioridade (canto superior direito)
          Positioned(
            top: 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: prioridadeColor.withAlpha(38), // 15% opacidade
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                prioridadeLabel,
                style: DS.caption.copyWith(
                  color: prioridadeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
