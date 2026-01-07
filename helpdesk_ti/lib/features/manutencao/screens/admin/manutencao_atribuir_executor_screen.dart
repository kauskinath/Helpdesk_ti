import 'package:flutter/material.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';
import '../../services/manutencao_service.dart';
import '../../models/chamado_manutencao_model.dart';

/// Tela para atribuir executor ao chamado
class ManutencaoAtribuirExecutorScreen extends StatefulWidget {
  final ChamadoManutencao chamado;

  const ManutencaoAtribuirExecutorScreen({super.key, required this.chamado});

  @override
  State<ManutencaoAtribuirExecutorScreen> createState() =>
      _ManutencaoAtribuirExecutorScreenState();
}

class _ManutencaoAtribuirExecutorScreenState
    extends State<ManutencaoAtribuirExecutorScreen> {
  final _manutencaoService = ManutencaoService();
  final _firestore = FirebaseFirestore.instance;

  String? _executorSelecionadoId;
  String? _executorSelecionadoNome;
  bool _isLoading = false;

  Future<void> _atribuir() async {
    if (_executorSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Selecione um executor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👷 Atribuir Executor?'),
        content: Text(
          'Confirma a atribuição do executor $_executorSelecionadoNome?\n\n'
          'Ele receberá uma notificação e poderá iniciar o trabalho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Atribuir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      await _manutencaoService.atribuirExecutor(
        chamadoId: widget.chamado.id,
        executorId: _executorSelecionadoId!,
        executorNome: _executorSelecionadoNome!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Executor atribuído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Voltar para a tela anterior (dashboard)
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // DS cores usadas diretamente

    return WallpaperScaffold(
      appBar: AppBar(
        title: const Text(
          '👷 Atribuir Executor',
          style: TextStyle(color: DS.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: DS.textPrimary),
      ),
      body: Column(
        children: [
          // Informações do chamado
          Card(
            margin: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.construction, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.chamado.titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.chamado.descricao,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

          // Lista de executores
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'executor')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final executores = snapshot.data?.docs ?? [];

                if (executores.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          color: Colors.grey.shade400,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum executor cadastrado',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: executores.length,
                  itemBuilder: (context, index) {
                    final executor = executores[index];
                    final data = executor.data() as Map<String, dynamic>;
                    final executorId = executor.id;
                    final executorNome =
                        data['nome'] ?? data['email'] ?? 'Executor';
                    final executorEmail = data['email'] ?? '';
                    final isSelected = _executorSelecionadoId == executorId;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        // ignore: deprecated_member_use
                        leading: Radio<String>(
                          value: executorId,
                          // ignore: deprecated_member_use
                          groupValue: _executorSelecionadoId,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              _executorSelecionadoId = value;
                              _executorSelecionadoNome = executorNome;
                            });
                          },
                        ),
                        title: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(
                              executorNome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(executorEmail),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _executorSelecionadoId = executorId;
                            _executorSelecionadoNome = executorNome;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Botão atribuir
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _atribuir,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add),
                label: const Text(
                  'ATRIBUIR EXECUTOR',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
