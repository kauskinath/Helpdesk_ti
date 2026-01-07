import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';
import '../../models/manutencao_enums.dart';
import '../../widgets/manutencao_card.dart';
import 'manutencao_detalhes_chamado_screen.dart';

/// Tela para listar chamados de manutenção do usuário - COM VISUAL TI! 🎨
class ManutencaoMeusChamadosScreen extends StatefulWidget {
  const ManutencaoMeusChamadosScreen({super.key});

  @override
  State<ManutencaoMeusChamadosScreen> createState() =>
      _ManutencaoMeusChamadosScreenState();
}

class _ManutencaoMeusChamadosScreenState
    extends State<ManutencaoMeusChamadosScreen> {
  final _manutencaoService = ManutencaoService();
  final _authService = AuthService();

  StatusChamadoManutencao? _filtroStatus;

  @override
  Widget build(BuildContext context) {
    final user = _authService.firebaseUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Column(
      children: [
        // Badge do filtro ativo
        if (_filtroStatus != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DS.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_filtroStatus!.emoji),
                  const SizedBox(width: 8),
                  Text(
                    'Filtro: ${_filtroStatus!.label}',
                    style: const TextStyle(
                      color: DS.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() => _filtroStatus = null);
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Lista de chamados
        Expanded(
          child: StreamBuilder<List<ChamadoManutencao>>(
            stream: _manutencaoService.getChamadosPorCriador(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar chamados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }

              var chamados = snapshot.data ?? [];

              // Aplicar filtros
              chamados = chamados.where((chamado) {
                // Filtro de status
                if (_filtroStatus != null && chamado.status != _filtroStatus) {
                  return false;
                }

                return true;
              }).toList();

              // Ordenar por data (mais recentes primeiro)
              chamados.sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));

              if (chamados.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _filtroStatus == null
                            ? Icons.construction_outlined
                            : Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filtroStatus == null
                            ? '📋 Nenhum chamado ainda'
                            : '🔍 Nenhum resultado encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_filtroStatus == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Crie seu primeiro chamado!',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                itemCount: chamados.length,
                itemBuilder: (context, index) {
                  final chamado = chamados[index];
                  return ManutencaoCard(
                    chamado: chamado,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManutencaoDetalhesChamadoScreen(
                            chamadoId: chamado.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
