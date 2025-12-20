# 🎨 PLANO DE CORREÇÕES - FRONTEND

**Projeto:** HelpDesk TI  
**Fase:** Frontend (Flutter/Dart)  
**Prerequisito:** Backend implementado conforme [PLANO_BACKEND.md](PLANO_BACKEND.md)

---

## 📋 ÍNDICE

1. [Telas para Usuários Comuns](#1-telas-para-usuários-comuns)
2. [Dashboard de Estatísticas](#2-dashboard-de-estatísticas)
3. [Sistema de Comentários (Estilo WhatsApp)](#3-sistema-de-comentários-estilo-whatsapp)
4. [Otimização de Performance](#4-otimização-de-performance)
5. [Cards de Chamados](#5-cards-de-chamados)
6. [Controle de Comentários por Status](#6-controle-de-comentários-por-status)
7. [Melhorias Gerais de UX](#7-melhorias-gerais-de-ux)

---

## 1️⃣ TELAS PARA USUÁRIOS COMUNS

### Problema:
Usuários comuns usam a mesma tela que admins, com campos desabilitados.

### Solução:
Criar telas dedicadas com UX otimizada para cada role.

---

### A) Nova Tela: `user_ticket_detail_screen.dart`

**Localização:** `lib/screens/user/user_ticket_detail_screen.dart`

**Características:**
- Interface simplificada (sem opções de admin)
- Foco em visualização e comentários
- Botão de avaliação destacado (quando fechado)
- Timeline de atualizações clara

**Estrutura:**
```dart
import 'package:flutter/material.dart';
import '../../models/chamado.dart';
import '../../data/firestore_service.dart';
import '../../data/auth_service.dart';
import '../../widgets/user/user_ticket_header.dart';
import '../../widgets/user/user_comment_section.dart';
import '../../widgets/user/user_ticket_info_card.dart';

class UserTicketDetailScreen extends StatefulWidget {
  final Chamado chamado;
  final FirestoreService firestoreService;
  final AuthService authService;

  const UserTicketDetailScreen({
    super.key,
    required this.chamado,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<UserTicketDetailScreen> createState() => _UserTicketDetailScreenState();
}

class _UserTicketDetailScreenState extends State<UserTicketDetailScreen> {
  final TextEditingController _comentarioController = TextEditingController();
  bool _podeComentarget _podeComenta() {
    return widget.chamado.status == 'Em Andamento' ||
           widget.chamado.status == 'Aguardando';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Chamado ${widget.chamado.numeroFormatado}'),
        backgroundColor: _getStatusColor(),
      ),
      body: CustomScrollView(
        slivers: [
          // Header com status
          SliverToBoxAdapter(
            child: UserTicketHeader(chamado: widget.chamado),
          ),
          
          // Informações principais
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: UserTicketInfoCard(chamado: widget.chamado),
            ),
          ),
          
          // Seção de comentários
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: UserCommentSection(
                chamadoId: widget.chamado.id,
                firestoreService: widget.firestoreService,
                podeAdicionar: _podeComentarget(),
                onComentarioEnviado: () {
                  setState(() {});
                },
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      
      // Botão flutuante para avaliação (se fechado)
      floatingActionButton: widget.chamado.status == 'Fechado'
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoAvaliacao,
              icon: Icon(Icons.star),
              label: Text('Avaliar Atendimento'),
              backgroundColor: Colors.amber,
            )
          : null,
    );
  }

  Color _getStatusColor() {
    // ... mesma lógica de cores
  }

  Future<void> _mostrarDialogoAvaliacao() async {
    // ... lógica de avaliação
  }
}
```

---

### B) Widget: `user_ticket_header.dart`

**Localização:** `lib/widgets/user/user_ticket_header.dart`

```dart
import 'package:flutter/material.dart';
import '../../models/chamado.dart';

class UserTicketHeader extends StatelessWidget {
  final Chamado chamado;

  const UserTicketHeader({super.key, required this.chamado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getStatusColor(), _getStatusColor().withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número e Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                chamado.numeroFormatado,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          SizedBox(height: 12),
          
          // Título
          Text(
            chamado.titulo,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          
          // Informações rápidas
          Row(
            children: [
              _buildQuickInfo(Icons.calendar_today, _formatDate(chamado.dataCriacao)),
              SizedBox(width: 16),
              _buildQuickInfo(Icons.priority_high, _getPriorityLabel()),
            ],
          ),
          
          // Responsável (se atribuído)
          if (chamado.adminNome != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Responsável: ${chamado.adminNome}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        chamado.status,
        style: TextStyle(
          color: _getStatusColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    // ... lógica de cores
  }

  String _getPriorityLabel() {
    switch (chamado.prioridade) {
      case 1: return 'Baixa';
      case 2: return 'Média';
      case 3: return 'Alta';
      case 4: return 'CRÍTICA';
      default: return 'Normal';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
```

---

### C) Widget: `user_ticket_info_card.dart`

**Localização:** `lib/widgets/user/user_ticket_info_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../models/chamado.dart';

class UserTicketInfoCard extends StatelessWidget {
  final Chamado chamado;

  const UserTicketInfoCard({super.key, required this.chamado});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descrição
            _buildSection(
              icon: Icons.description,
              title: 'Descrição',
              content: Text(chamado.descricao),
            ),
            
            if (chamado.setor != null) ...[
              Divider(height: 32),
              _buildSection(
                icon: Icons.business,
                title: 'Setor',
                content: Text(chamado.setor!),
              ),
            ],
            
            if (chamado.linkOuEspecificacao != null) ...[
              Divider(height: 32),
              _buildSection(
                icon: Icons.link,
                title: 'Link/Especificação',
                content: SelectableText(
                  chamado.linkOuEspecificacao!,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
            
            if (chamado.anexos.isNotEmpty) ...[
              Divider(height: 32),
              _buildSection(
                icon: Icons.attach_file,
                title: 'Anexos (${chamado.anexos.length})',
                content: _buildAnexosGrid(),
              ),
            ],
            
            if (chamado.motivoRejeicao != null) ...[
              Divider(height: 32),
              _buildRejectionSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildAnexosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: chamado.anexos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            chamado.anexos[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.broken_image),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRejectionSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, color: Colors.red[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Motivo da Rejeição',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(chamado.motivoRejeicao!),
        ],
      ),
    );
  }
}
```

---

## 2️⃣ DASHBOARD DE ESTATÍSTICAS

### Nova Tela: `dashboard_tab.dart`

**Localização:** `lib/screens/tabs/dashboard_tab.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/firestore_service.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/chamados_por_status_chart.dart';
import '../../widgets/dashboard/chamados_por_prioridade_chart.dart';
import '../../widgets/dashboard/tempo_medio_card.dart';
import '../../widgets/dashboard/chamados_recentes_list.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() => _isLoading = true);
    
    try {
      final firestore = context.read<FirestoreService>();
      final stats = await firestore.getStatsAdmin();
      
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _carregarEstatisticas,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Visão geral do sistema',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          
          // Cards de estatísticas
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate([
                StatCard(
                  title: 'Chamados Abertos',
                  value: '${_stats['abertos'] ?? 0}',
                  icon: Icons.inbox,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Em Andamento',
                  value: '${_stats['emAndamento'] ?? 0}',
                  icon: Icons.play_circle,
                  color: Colors.blue,
                ),
                StatCard(
                  title: 'Aguardando',
                  value: '${_stats['aguardando'] ?? 0}',
                  icon: Icons.schedule,
                  color: Colors.purple,
                ),
                StatCard(
                  title: 'Fechados Hoje',
                  value: '${_stats['fechadosHoje'] ?? 0}',
                  icon: Icons.check_circle,
                  color: Colors.grey,
                ),
              ]),
            ),
          ),
          
          // Gráficos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  ChamadosPorPrioridadeChart(stats: _stats),
                  SizedBox(height: 16),
                  TempoMedioCard(stats: _stats),
                ],
              ),
            ),
          ),
          
          // Lista de chamados recentes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chamados Recentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ChamadosRecentesList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Widget: `stat_card.dart`

```dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white70, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3️⃣ SISTEMA DE COMENTÁRIOS (ESTILO WHATSAPP)

### Refatorar: `timeline_widget.dart`

**Localização:** `lib/widgets/chamado/timeline_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> comentarios;
  final String? currentUserId; // ID do usuário logado

  const TimelineWidget({
    super.key,
    required this.comentarios,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (comentarios.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'Nenhum comentário ainda',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: comentarios.length,
      itemBuilder: (context, index) {
        final comentario = comentarios[index];
        final isAdmin = comentario['autorRole'] == 'admin';
        final isCurrentUser = comentario['autorId'] == currentUserId;
        
        // ✅ ALINHAMENTO ESTILO WHATSAPP
        return _buildMessageBubble(
          comentario: comentario,
          isAdmin: isAdmin,
          alignRight: isAdmin, // Admins à direita
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required Map<String, dynamic> comentario,
    required bool isAdmin,
    required bool alignRight,
  }) {
    final dataHora = comentario['dataHora'] != null
        ? (comentario['dataHora'] as dynamic).toDate()
        : DateTime.now();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar à esquerda (se não estiver alinhado à direita)
          if (!alignRight) ...[
            _buildAvatar(isAdmin),
            SizedBox(width: 8),
          ],
          
          // Balão de mensagem
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 280, // Máximo 280px de largura
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: alignRight
                    ? Colors.blue[600] // Admin = azul
                    : Colors.grey[300], // User = cinza
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(alignRight ? 16 : 4),
                  bottomRight: Radius.circular(alignRight ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do autor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          comentario['autorNome'] ?? 'Desconhecido',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: alignRight ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildRoleBadge(isAdmin, alignRight),
                    ],
                  ),
                  SizedBox(height: 6),
                  
                  // Mensagem
                  Text(
                    comentario['mensagem'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: alignRight ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  
                  // Hora
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat('HH:mm').format(dataHora),
                      style: TextStyle(
                        fontSize: 11,
                        color: alignRight
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Avatar à direita (se estiver alinhado à direita)
          if (alignRight) ...[
            SizedBox(width: 8),
            _buildAvatar(isAdmin),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isAdmin) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: isAdmin ? Colors.blue[600] : Colors.grey[400],
      child: Icon(
        isAdmin ? Icons.engineering : Icons.person,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRoleBadge(bool isAdmin, bool lightBackground) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: lightBackground
            ? Colors.white.withOpacity(0.3)
            : (isAdmin ? Colors.blue[100] : Colors.grey[400]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAdmin ? 'TI' : 'Usuário',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: lightBackground
              ? Colors.white
              : (isAdmin ? Colors.blue[900] : Colors.black54),
        ),
      ),
    );
  }
}
```

---

## 4️⃣ OTIMIZAÇÃO DE PERFORMANCE

### A) Adicionar Cache de Imagens

**1. Instalar Dependência:**

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.3.1
```

**2. Substituir Image.network por CachedNetworkImage:**

```dart
// ANTES (ticket_details_screen.dart linha 585):
Image.network(anexoUrl, fit: BoxFit.cover)

// DEPOIS:
CachedNetworkImage(
  imageUrl: anexoUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => Center(
    child: CircularProgressIndicator(strokeWidth: 2),
  ),
  errorWidget: (context, url, error) => Icon(
    Icons.broken_image,
    color: Colors.grey,
  ),
  memCacheWidth: 300, // Limita tamanho em memória
  memCacheHeight: 300,
)
```

---

### B) Otimizar ListView com AutomaticKeepAliveClientMixin

```dart
// Aplicar em todas as tabs (meus_chamados_tab.dart, fila_tecnica_tab.dart)
class _MeusChamadosTabState extends State<MeusChamadosTab>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // ✅ Mantém estado ao trocar tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ OBRIGATÓRIO
    
    // ... resto do código
  }
}
```

---

### C) Remover Animações Pesadas

```dart
// ANTES (selecionar_template_screen.dart):
FadeInUp(
  delay: Duration(milliseconds: 50 * index),
  duration: const Duration(milliseconds: 400),
  child: _buildTemplateCard(templates[index]),
)

// DEPOIS:
AnimatedOpacity(
  opacity: 1.0,
  duration: Duration(milliseconds: 150), // ✅ Mais rápido
  child: _buildTemplateCard(templates[index]),
)
```

---

### D) Paginar Comentários

```dart
// Modificar getComentariosStream para aceitar limit
Stream<List<Map<String, dynamic>>> getComentariosStream(
  String chamadoId, {
  int limit = 20, // ✅ Padrão 20 comentários
}) {
  return _firestore
      .collection('comentarios')
      .where('chamadoId', isEqualTo: chamadoId)
      .orderBy('dataHora', descending: true)
      .limit(limit) // ✅ Paginação
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
}
```

---

## 5️⃣ CARDS DE CHAMADOS

### Refatorar: `ticket_card.dart`

```dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class TicketCard extends StatelessWidget {
  final String? numeroFormatado;
  final String titulo;
  final String tipo;
  final String status;
  final DateTime dataCriacao;
  final String usuarioNome;
  final int prioridade;
  final VoidCallback? onTap;

  const TicketCard({
    super.key,
    this.numeroFormatado,
    required this.titulo,
    required this.tipo,
    required this.status,
    required this.dataCriacao,
    required this.usuarioNome,
    required this.prioridade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha 1: Número + Prioridade
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (numeroFormatado != null)
                    Text(
                      numeroFormatado!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  _buildPriorityIndicator(), // ✅ Ícone visual
                ],
              ),
              SizedBox(height: 8),
              
              // Linha 2: Título
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              
              // Linha 3: Status + Info
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Spacer(),
                  
                  // Data
                  Text(
                    _formatDate(dataCriacao),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              
              // Linha 4: Usuário (removido setor - redundante)
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usuarioNome,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Indicador visual de prioridade
  Widget _buildPriorityIndicator() {
    Color color = _getPriorityColor();
    IconData icon = _getPriorityIcon();
    String label = _getPriorityLabel();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'Aberto': return Color(0xFF4CAF50);
      case 'Em Andamento': return Color(0xFF2196F3);
      case 'Pendente Aprovação': return Color(0xFFFFA726);
      case 'Aguardando': return Color(0xFF9C27B0);
      case 'Fechado': return Color(0xFF9E9E9E);
      case 'Rejeitado': return Color(0xFFEF5350);
      default: return AppColors.grey;
    }
  }

  Color _getPriorityColor() {
    switch (prioridade) {
      case 1: return Color(0xFF66BB6A); // Verde
      case 2: return Color(0xFF42A5F5); // Azul
      case 3: return Color(0xFFFF9800); // Laranja
      case 4: return Color(0xFFEF5350); // Vermelho
      default: return Colors.blue;
    }
  }

  IconData _getPriorityIcon() {
    switch (prioridade) {
      case 1: return Icons.arrow_downward;
      case 2: return Icons.remove;
      case 3: return Icons.arrow_upward;
      case 4: return Icons.priority_high;
      default: return Icons.remove;
    }
  }

  String _getPriorityLabel() {
    switch (prioridade) {
      case 1: return 'Baixa';
      case 2: return 'Média';
      case 3: return 'Alta';
      case 4: return 'CRÍTICA';
      default: return 'Normal';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Hoje ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
```

---

## 6️⃣ CONTROLE DE COMENTÁRIOS POR STATUS

### Atualizar: `ticket_details_screen.dart`

```dart
// Dentro de _buildComentariosCard()

// Campo de input para novos comentários
Container(
  decoration: BoxDecoration(
    color: _podeComentarget() ? Colors.white : Colors.grey[300],
    borderRadius: BorderRadius.circular(12),
  ),
  child: TextField(
    controller: _comentarioController,
    focusNode: _comentarioFocusNode,
    enabled: _podeComentarget(), // ✅ Desabilita se não pode comentar
    maxLines: 3,
    decoration: InputDecoration(
      hintText: _podeComentarget()
          ? 'Escreva um comentário...'
          : _getMensagemBloqueio(),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: _podeComentarget() ? Colors.white : Colors.grey[300],
      contentPadding: const EdgeInsets.all(16),
      suffixIcon: _podeComentarget()
          ? IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: _enviarComentario,
            )
          : Icon(Icons.lock, color: Colors.grey[600]),
    ),
  ),
),

// Helper functions
bool _podeComentarget() {
  final status = widget.chamado.status;
  return status == 'Em Andamento' || status == 'Aguardando';
}

String _getMensagemBloqueio() {
  final status = widget.chamado.status;
  switch (status) {
    case 'Aberto':
      return 'Aguarde um admin aceitar o chamado';
    case 'Fechado':
      return 'Chamado finalizado - comentários bloqueados';
    case 'Rejeitado':
      return 'Chamado rejeitado - comentários bloqueados';
    default:
      return 'Comentários não disponíveis';
  }
}
```

---

## 7️⃣ MELHORIAS GERAIS DE UX

### A) Loading Skeletons

**Instalar:**
```yaml
dependencies:
  shimmer: ^3.0.0
```

**Usar em listas:**
```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, index) {
      return ShimmerCard(); // Widget de loading bonito
    },
  );
}
```

---

### B) Pull-to-Refresh em Todas as Tabs

```dart
return RefreshIndicator(
  onRefresh: () async {
    // Força atualização do stream
    setState(() {});
    await Future.delayed(Duration(milliseconds: 500));
  },
  child: ListView(...),
);
```

---

### C) Snackbars Consistentes

```dart
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Telas de Usuário:
- [ ] Criar `user_ticket_detail_screen.dart`
- [ ] Criar `user_ticket_header.dart`
- [ ] Criar `user_ticket_info_card.dart`
- [ ] Criar `user_comment_section.dart`
- [ ] Integrar no `home_screen.dart` baseado em role

### Dashboard:
- [ ] Criar `dashboard_tab.dart`
- [ ] Criar `stat_card.dart`
- [ ] Criar `chamados_por_prioridade_chart.dart`
- [ ] Criar `tempo_medio_card.dart`
- [ ] Criar `chamados_recentes_list.dart`
- [ ] Adicionar tab no `home_screen.dart`

### Sistema de Comentários:
- [ ] Refatorar `timeline_widget.dart` (WhatsApp style)
- [ ] Adicionar parâmetro `currentUserId`
- [ ] Testar alinhamento direita/esquerda
- [ ] Adicionar avatares

### Performance:
- [ ] Instalar `cached_network_image`
- [ ] Substituir todos `Image.network` por `CachedNetworkImage`
- [ ] Adicionar `AutomaticKeepAliveClientMixin` nas tabs
- [ ] Otimizar animações (reduzir durations)
- [ ] Adicionar paginação em comentários

### Cards:
- [ ] Refatorar `ticket_card.dart`
- [ ] Adicionar indicador visual de prioridade
- [ ] Remover informações redundantes (setor)
- [ ] Melhorar formatação de data (relativa)
- [ ] Reduzir altura do card

### Controle de Comentários:
- [ ] Adicionar método `_podeComentarget()`
- [ ] Adicionar método `_getMensagemBloqueio()`
- [ ] Desabilitar TextField quando não pode comentar
- [ ] Mostrar ícone de cadeado quando bloqueado

### UX Geral:
- [ ] Instalar `shimmer` para loading skeletons
- [ ] Adicionar `RefreshIndicator` em todas as tabs
- [ ] Criar helpers de snackbars consistentes
- [ ] Adicionar animações de transição suaves

---

## 📊 ESTIMATIVA DE TEMPO

| Tarefa | Tempo Estimado |
|--------|----------------|
| Telas de Usuário | 5 horas |
| Dashboard | 4 horas |
| Sistema de Comentários | 3 horas |
| Otimização de Performance | 2 horas |
| Refatoração de Cards | 2 horas |
| Controle de Comentários | 1 hora |
| Melhorias de UX | 2 horas |
| **TOTAL** | **19 horas** |

---

## 🧪 TESTES NECESSÁRIOS

### 1. Teste de Roles:
- Logar como admin → Ver tela de admin
- Logar como user → Ver tela de usuário
- Verificar permissões de comentários

### 2. Teste de Performance:
- Lista com 100+ chamados → Scroll suave?
- Abrir chamado com 50+ comentários → Carrega rápido?
- Trocar entre tabs → Mantém estado?

### 3. Teste de UI:
- Comentários alinhados corretamente?
- Cards organizados e legíveis?
- Dashboard mostra dados corretos?

---

**Ordem de Implementação Recomendada:**
1. ✅ Performance (cached images, keep alive)
2. ✅ Cards (visual mais limpo)
3. ✅ Comentários (WhatsApp style)
4. ✅ Controle de comentários por status
5. ✅ Telas de usuário
6. ✅ Dashboard
7. ✅ UX geral (shimmer, refresh, etc)
