# 📋 PLANO DE REFATORAÇÃO COMPLETO - HELPDESK TI

**Data:** 06/12/2025  
**Status:** ANÁLISE CRÍTICA - Refatoração Necessária  
**Prioridade:** 🔴 ALTA

---

## 📊 ANÁLISE ATUAL DO PROJETO

### **ESTATÍSTICAS GERAIS**
- **Total de arquivos .dart:** 95 arquivos
- **Maior arquivo:** `seed_templates.dart` (1.119 linhas) ⚠️
- **Segundo maior:** `chamado_service.dart` (1.099 linhas) ⚠️
- **Arquivos com 500+ linhas:** 24 arquivos 🔴

### **TOP 10 ARQUIVOS MAIS COMPLEXOS**
```
1. seed_templates.dart                                    1.119 linhas 🔴
2. chamado_service.dart                                   1.099 linhas 🔴
3. ticket_details_refactored.dart                           881 linhas 🔴
4. about_screen.dart                                        858 linhas 🔴
5. chamado_detail_dialog.dart (web)                         834 linhas 🔴
6. dashboard_screen.dart                                    827 linhas 🔴
7. web_chamados_screen.dart                                 787 linhas 🔴
8. notification_service.dart                                779 linhas 🔴
9. selecionar_template_screen.dart                          676 linhas 🔴
10. login_screen.dart                                       673 linhas 🔴
```

### **MÓDULO MANUTENÇÃO - ANÁLISE**
```
manutencao_dashboard_admin_screen.dart                    567 linhas 🟡
manutencao_service.dart                                   512 linhas 🟡
manutencao_dashboard_executor_screen.dart                 497 linhas 🟡
manutencao_executar_screen.dart                           468 linhas 🟡
manutencao_criar_chamado_executor_screen.dart             461 linhas 🟡
manutencao_aprovar_orcamento_screen.dart                  443 linhas 🟡
manutencao_dashboard_gerente_screen.dart                  439 linhas 🟡
```

---

## 🚨 PROBLEMAS IDENTIFICADOS

### **1. ARQUITETURA DESORGANIZADA**

#### **1.1 Estrutura de Pastas Inconsistente**
```
❌ ATUAL (Caótico):
lib/
├── screens/              ← TI screens misturados
│   ├── home_screen.dart
│   ├── about_screen.dart
│   ├── firestore.indexes.json  ← Arquivo no lugar errado!
│   ├── admin/
│   ├── tabs/
│   ├── chamado/
│   └── dashboard/
├── modulos/
│   └── manutencao/       ← Manutenção separado (OK)
│       ├── screens/
│       ├── models/
│       └── services/
├── data/                 ← Mistura service + auth
├── services/             ← Outra pasta de services!
├── widgets/              ← TI widgets genéricos
└── core/

PROBLEMAS:
- Duas pastas de services (data/ e services/)
- Screens TI não estão em módulo próprio
- firestore.indexes.json dentro de screens/
- Widgets genéricos misturados com específicos
```

#### **1.2 Duplicação de Código**
- **Dashboard TI vs Manutenção:** Lógica similar repetida
- **Menu de navegação:** Implementado 3 vezes diferentes
- **Card de chamado:** 3 variações (ticket_card.dart, ticket_card_v2.dart, widget inline)
- **Filtros:** Cada tela implementa filtro de forma diferente

#### **1.3 Visual Inconsistente (TI vs Manutenção)**

**TI (HomeScreen):**
- Menu popup com ícones organizados por categoria
- Filtros no menu hambúrguer
- Design limpo com wallpaper
- Tema claro/escuro
- Botões de atalho integrados

**Manutenção (Dashboards):**
- ❌ Menu diferente (ícones + submenus)
- ❌ Layout diferente
- ❌ Cores diferentes
- ❌ Sem wallpaper
- ❌ Estrutura de navegação diferente

### **2. ARQUIVOS GIGANTES (Violação SOLID - SRP)**

#### **Seed Templates (1.119 linhas)**
```dart
❌ PROBLEMA:
- 1 arquivo com 30+ templates hardcoded
- Lógica de seed misturada com dados
- Impossível manter/adicionar templates

✅ SOLUÇÃO:
- Mover templates para JSON (assets/templates/)
- Criar TemplateLoader service
- Seed apenas carrega JSON
```

#### **ChamadoService (1.099 linhas)**
```dart
❌ PROBLEMA:
- 40+ métodos em 1 classe
- Lógica CRUD + notificações + timeline + comentários + avaliação
- Difícil testar/manter

✅ SOLUÇÃO:
- Dividir em:
  * ChamadoRepositoryService (CRUD Firestore)
  * ChamadoBusinessService (regras de negócio)
  * ComentarioService (comentários)
  * TimelineService (histórico)
  * AvaliacaoService (já existe, integrar)
```

#### **TicketDetailsRefactored (881 linhas)**
```dart
❌ PROBLEMA:
- UI + lógica + API calls em 1 arquivo
- Widgets inline gigantes
- State management confuso

✅ SOLUÇÃO:
- Dividir em widgets menores:
  * TicketDetailsScreen (orquestrador)
  * TicketHeaderWidget
  * TicketInfoWidget
  * TicketTimelineWidget (já existe)
  * TicketCommentsWidget
  * TicketActionsWidget
```

### **3. CÓDIGO DUPLICADO**

#### **3.1 Lógica de Filtros (repetida 8x)**
```dart
// Em cada tela:
StatusChamadoManutencao? _filtroStatus;
String _buscaTexto = '';

// Método de filtro idêntico em 8 lugares
```

#### **3.2 Cards de Chamado (3 variações)**
```dart
1. ticket_card.dart (TI)
2. ticket_card_v2.dart (TI nova versão?)
3. _buildChamadoCard() inline (Manutenção)

// Lógica 80% igual, 20% diferente
```

#### **3.3 Menu de Navegação (3 implementações)**
```dart
1. HomeScreen (TI) - PopupMenu organizado
2. ManutencaoDashboardAdminScreen - PopupMenu com ícones/submenus
3. UserHomeScreen - Tabs + PopupMenu

// Cada um implementado do zero
```

### **4. INCONSISTÊNCIA DE PADRÕES**

#### **4.1 Naming Conventions**
```dart
❌ Inconsistente:
- ManutencaoDashboardAdminScreen (prefixo Manutencao)
- home_screen.dart (TI sem prefixo)
- ticket_details_refactored.dart (sufixo _refactored?)
- admin_management_screen_v2.dart (sufixo _v2?)

✅ Padrão correto:
- TI: ti_dashboard_screen.dart
- Manutenção: manutencao_dashboard_screen.dart
- Sufixos apenas para versões temporárias
```

#### **4.2 Imports Relativos vs Absolutos**
```dart
❌ Misturado:
import '../../services/manutencao_service.dart';        // Relativo
import '../../../services/auth_service.dart';            // Relativo
import 'package:helpdesk_ti/core/app_theme.dart';       // Absoluto

✅ Escolher 1 padrão e aplicar em todo o projeto
```

#### **4.3 Services em 2 lugares**
```dart
lib/data/               ← auth_service, firestore_service
lib/services/           ← notification_service, navigation_service

❌ Confuso: onde criar novo service?
✅ Centralizar tudo em lib/core/services/
```

---

## 🎯 PLANO DE REFATORAÇÃO (6 FASES)

### **FASE 1: REORGANIZAÇÃO DE ARQUITETURA** 🏗️
**Tempo estimado:** 3-4 horas  
**Prioridade:** 🔴 CRÍTICA

#### **1.1 Nova Estrutura de Pastas**
```
lib/
├── core/                           ← Núcleo do app
│   ├── config/
│   │   ├── app_config.dart
│   │   └── firebase_options.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── theme_provider.dart
│   ├── services/                   ← TODOS os services aqui
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── notification_service.dart
│   │   ├── navigation_service.dart
│   │   └── permissions_service.dart
│   ├── utils/
│   │   ├── date_formatter.dart
│   │   ├── snackbar_helper.dart
│   │   └── validators.dart
│   ├── widgets/                    ← Widgets REALMENTE compartilhados
│   │   ├── common/
│   │   │   ├── loading_indicator.dart
│   │   │   ├── empty_state.dart
│   │   │   └── error_widget.dart
│   │   ├── cards/
│   │   │   └── base_card_widget.dart
│   │   └── dialogs/
│   │       └── confirmation_dialog.dart
│   └── constants/
│       ├── app_routes.dart
│       └── app_strings.dart
│
├── features/                       ← FEATURE-BASED (não por tipo)
│   │
│   ├── ti/                         ← MÓDULO TI (antes misturado)
│   │   ├── models/
│   │   │   ├── chamado.dart
│   │   │   ├── comentario.dart
│   │   │   └── avaliacao.dart
│   │   ├── services/
│   │   │   ├── ti_repository.dart        ← CRUD Firestore
│   │   │   ├── ti_business_service.dart  ← Regras de negócio
│   │   │   ├── comentario_service.dart
│   │   │   └── timeline_service.dart
│   │   ├── screens/
│   │   │   ├── dashboard/
│   │   │   │   ├── ti_dashboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── stat_card.dart
│   │   │   │       └── filter_menu.dart
│   │   │   ├── chamados/
│   │   │   │   ├── ti_chamados_list_screen.dart
│   │   │   │   ├── ti_chamado_details_screen.dart
│   │   │   │   └── ti_criar_chamado_screen.dart
│   │   │   ├── admin/
│   │   │   │   ├── user_management_screen.dart
│   │   │   │   └── template_management_screen.dart
│   │   │   └── fila_tecnica/
│   │   │       └── fila_tecnica_screen.dart
│   │   └── widgets/
│   │       ├── ti_chamado_card.dart
│   │       ├── ti_filter_widget.dart
│   │       └── ti_timeline_widget.dart
│   │
│   ├── manutencao/                 ← MÓDULO MANUTENÇÃO (OK, mas refinar)
│   │   ├── models/
│   │   │   ├── chamado_manutencao.dart
│   │   │   └── manutencao_enums.dart
│   │   ├── services/
│   │   │   ├── manutencao_repository.dart
│   │   │   └── manutencao_business_service.dart
│   │   ├── screens/
│   │   │   ├── admin/
│   │   │   │   ├── manutencao_dashboard_screen.dart
│   │   │   │   ├── manutencao_validar_screen.dart
│   │   │   │   └── widgets/
│   │   │   ├── gerente/
│   │   │   │   └── manutencao_aprovar_orcamento_screen.dart
│   │   │   ├── executor/
│   │   │   │   ├── manutencao_executar_screen.dart
│   │   │   │   └── manutencao_recusar_screen.dart
│   │   │   └── comum/
│   │   │       ├── manutencao_meus_chamados_screen.dart
│   │   │       └── manutencao_detalhes_screen.dart
│   │   └── widgets/
│   │       ├── manutencao_chamado_card.dart
│   │       └── manutencao_filter_widget.dart
│   │
│   ├── auth/                       ← Telas de autenticação
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── permission_request_screen.dart
│   │   └── widgets/
│   │       └── login_form.dart
│   │
│   └── common/                     ← Telas comuns (About, etc)
│       └── screens/
│           ├── about_screen.dart
│           └── search_screen.dart
│
├── shared/                         ← Componentes REALMENTE compartilhados
│   ├── widgets/
│   │   ├── base_dashboard_layout.dart    ← Layout base para todos
│   │   ├── base_card.dart                ← Card base reutilizável
│   │   ├── base_filter_menu.dart         ← Filtro base reutilizável
│   │   └── base_navigation_menu.dart     ← Menu base reutilizável
│   └── mixins/
│       ├── filterable_mixin.dart         ← Lógica de filtro reutilizável
│       └── searchable_mixin.dart         ← Lógica de busca reutilizável
│
├── router/
│   ├── app_router.dart
│   └── route_guards.dart
│
└── main.dart
```

#### **1.2 Ações - Fase 1**
1. ✅ Criar nova estrutura de pastas
2. ✅ Mover `core/` (theme, config, constants)
3. ✅ Criar `features/ti/` e mover screens TI
4. ✅ Refatorar `features/manutencao/` (renomear de modulos/)
5. ✅ Centralizar services em `core/services/`
6. ✅ Criar `shared/widgets/` para componentes base
7. ✅ Atualizar todos os imports
8. ✅ Testar compilação

---

### **FASE 2: UNIFICAÇÃO VISUAL (TI ≈ MANUTENÇÃO)** 🎨
**Tempo estimado:** 4-5 horas  
**Prioridade:** 🔴 CRÍTICA (solicitado pelo usuário)

#### **2.1 Criar Design System Base**
```dart
// shared/widgets/base_dashboard_layout.dart
class BaseDashboardLayout extends StatelessWidget {
  final String title;
  final Color primaryColor;
  final Widget body;
  final List<MenuAction> menuActions;
  final FloatingActionButton? fab;
  final bool showWallpaper;
  
  // Layout padrão para TODAS as dashboards (TI + Manutenção)
}

// shared/widgets/base_navigation_menu.dart
class BaseNavigationMenu extends StatelessWidget {
  final List<MenuCategory> categories;
  
  // Menu hambúrguer padrão com categorias e ícones
  // Usado por TI e Manutenção
}
```

#### **2.2 Padronizar Dashboards**

**ANTES (Inconsistente):**
- TI: PopupMenu + Tabs + Filtros inline
- Manutenção Admin: PopupMenu diferente + Cards de stat
- Manutenção Gerente: Header customizado + Lista
- Manutenção Executor: Outro header + Filtros diferentes

**DEPOIS (Consistente):**
```dart
// Todas as dashboards usam BaseDashboardLayout

TIDashboardScreen:
  BaseDashboardLayout(
    title: '💻 TI Helpdesk',
    primaryColor: Colors.blue,
    menuActions: [...],
    body: TIDashboardBody(),
  )

ManutencaoDashboardAdminScreen:
  BaseDashboardLayout(
    title: '🛠️ Manutenção Admin',
    primaryColor: Colors.purple,
    menuActions: [...],
    body: ManutencaoDashboardBody(),
  )

ManutencaoDashboardGerenteScreen:
  BaseDashboardLayout(
    title: '👔 Aprovação de Orçamentos',
    primaryColor: Colors.blue,
    menuActions: [...],
    body: ManutencaoGerenteBody(),
  )
```

#### **2.3 Unificar Componentes Visuais**

**Cards de Chamado:**
```dart
// shared/widgets/base_card.dart
class BaseChamadoCard extends StatelessWidget {
  final String title;
  final String status;
  final String statusEmoji;
  final Color statusColor;
  final DateTime date;
  final String author;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  // Card base usado por TI e Manutenção
  // Customizável via parâmetros
}

// features/ti/widgets/ti_chamado_card.dart
class TIChamadoCard extends StatelessWidget {
  final Chamado chamado;
  
  @override
  Widget build(BuildContext context) {
    return BaseChamadoCard(
      title: chamado.titulo,
      status: chamado.status.label,
      // ... mapeia para card base
    );
  }
}

// features/manutencao/widgets/manutencao_chamado_card.dart
class ManutencaoChamadoCard extends StatelessWidget {
  final ChamadoManutencao chamado;
  
  @override
  Widget build(BuildContext context) {
    return BaseChamadoCard(
      title: chamado.titulo,
      status: chamado.status.label,
      // ... mapeia para card base
    );
  }
}
```

**Menu de Filtros:**
```dart
// shared/widgets/base_filter_menu.dart
class BaseFilterMenu extends StatelessWidget {
  final List<FilterOption> options;
  final FilterOption? selected;
  final ValueChanged<FilterOption?> onChanged;
  
  // Menu de filtro padrão (drawer ou popup)
}

// Usado em TI e Manutenção com enum específico
```

#### **2.4 Aplicar Tema Consistente**
```dart
// core/theme/app_theme.dart
class AppTheme {
  // Cores modulares
  static const tiPrimaryColor = Colors.blue;
  static const manutencaoPrimaryColor = Colors.purple;
  
  // Estilos compartilhados
  static TextStyle get cardTitleStyle => ...;
  static TextStyle get cardSubtitleStyle => ...;
  
  // Layout compartilhado
  static EdgeInsets get screenPadding => EdgeInsets.all(16);
  static double get cardBorderRadius => 12;
}
```

#### **2.5 Ações - Fase 2**
1. ✅ Criar `BaseDashboardLayout`
2. ✅ Criar `BaseNavigationMenu`
3. ✅ Criar `BaseChamadoCard`
4. ✅ Criar `BaseFilterMenu`
5. ✅ Atualizar `TIDashboardScreen` para usar base
6. ✅ Atualizar todas as telas Manutenção para usar base
7. ✅ Remover código duplicado (cards inline, menus customizados)
8. ✅ Testar visual em todas as telas
9. ✅ Gerar APK e validar

---

### **FASE 3: QUEBRAR ARQUIVOS GIGANTES** ✂️
**Tempo estimado:** 3-4 horas  
**Prioridade:** 🟡 ALTA

#### **3.1 Seed Templates (1.119 → 50 linhas)**

**ANTES:**
```dart
// utils/seed_templates.dart (1.119 linhas)
Future<void> seedTemplates() async {
  final template1 = ChamadoTemplate(...); // 30 linhas
  final template2 = ChamadoTemplate(...); // 30 linhas
  // ... 30+ templates hardcoded
}
```

**DEPOIS:**
```json
// assets/templates/ti_templates.json
[
  {
    "id": "email_config",
    "titulo": "Configuração de E-mail",
    "categoria": "E-mail",
    "campos": [...]
  },
  // ... outros templates
]
```

```dart
// core/services/template_loader_service.dart (100 linhas)
class TemplateLoaderService {
  Future<List<ChamadoTemplate>> loadTemplates() async {
    final json = await rootBundle.loadString('assets/templates/ti_templates.json');
    final list = jsonDecode(json) as List;
    return list.map((e) => ChamadoTemplate.fromJson(e)).toList();
  }
}

// utils/seed_templates.dart (50 linhas)
Future<void> seedTemplates() async {
  final templates = await TemplateLoaderService().loadTemplates();
  // Apenas salva no Firestore
}
```

#### **3.2 ChamadoService (1.099 → 250 linhas cada)**

**ANTES:**
```dart
// data/services/chamado_service.dart (1.099 linhas)
class ChamadoService {
  // CRUD
  Future<void> criarChamado(...) {}
  Future<void> atualizarChamado(...) {}
  Stream<List<Chamado>> getChamados() {}
  
  // Comentários
  Future<void> adicionarComentario(...) {}
  Stream<List<Comentario>> getComentarios(...) {}
  
  // Timeline
  Future<void> registrarHistorico(...) {}
  
  // Notificações
  Future<void> notificarTecnico(...) {}
  
  // Avaliação
  Future<void> avaliarAtendimento(...) {}
  
  // ... 40+ métodos
}
```

**DEPOIS:**
```dart
// features/ti/services/ti_repository.dart (250 linhas)
class TIRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // APENAS CRUD do Firestore
  Future<String> create(Chamado chamado) {}
  Future<void> update(String id, Map<String, dynamic> data) {}
  Future<void> delete(String id) {}
  Stream<List<Chamado>> getAll() {}
  Stream<Chamado> getById(String id) {}
}

// features/ti/services/ti_business_service.dart (300 linhas)
class TIBusinessService {
  final TIRepository _repository;
  final NotificationService _notificationService;
  final TimelineService _timelineService;
  
  // Regras de negócio + orquestração
  Future<void> criarChamado(Chamado chamado) async {
    // 1. Validar
    // 2. Criar no repository
    // 3. Registrar timeline
    // 4. Notificar técnico
  }
  
  Future<void> atribuirTecnico(String chamadoId, String tecnicoId) async {
    // 1. Atualizar status
    // 2. Registrar timeline
    // 3. Notificar técnico
  }
}

// features/ti/services/comentario_service.dart (150 linhas)
class ComentarioService {
  // Lógica de comentários separada
}

// features/ti/services/timeline_service.dart (150 linhas)
class TimelineService {
  // Lógica de histórico separada
}
```

#### **3.3 TicketDetailsRefactored (881 → 200 + widgets)**

**ANTES:**
```dart
// screens/chamado/ticket_details_refactored.dart (881 linhas)
class TicketDetailsRefactored extends StatefulWidget {
  @override
  _TicketDetailsRefactoredState createState() => ...
}

class _TicketDetailsRefactoredState extends State<...> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),  // 50 linhas inline
      body: Column(
        children: [
          _buildHeader(),        // 100 linhas inline
          _buildInfoSection(),   // 150 linhas inline
          _buildTimeline(),      // 200 linhas inline
          _buildComments(),      // 200 linhas inline
          _buildActions(),       // 100 linhas inline
        ],
      ),
    );
  }
  
  Widget _buildHeader() { /* 100 linhas */ }
  Widget _buildInfoSection() { /* 150 linhas */ }
  // ...
}
```

**DEPOIS:**
```dart
// features/ti/screens/chamados/ti_chamado_details_screen.dart (200 linhas)
class TIChamadoDetailsScreen extends StatefulWidget {
  @override
  _TIChamadoDetailsScreenState createState() => ...
}

class _TIChamadoDetailsScreenState extends State<...> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: Column(
        children: [
          TIChamadoHeaderWidget(chamado: chamado),
          TIChamadoInfoWidget(chamado: chamado),
          TIChamadoTimelineWidget(chamadoId: chamado.id),
          TIChamadoCommentsWidget(chamadoId: chamado.id),
          TIChamadoActionsWidget(
            chamado: chamado,
            onAtribuir: _atribuirTecnico,
            onFinalizar: _finalizarChamado,
          ),
        ],
      ),
    );
  }
}

// features/ti/widgets/chamado_details/ti_chamado_header_widget.dart (80 linhas)
class TIChamadoHeaderWidget extends StatelessWidget {
  final Chamado chamado;
  // Só o header (título, status, prioridade)
}

// features/ti/widgets/chamado_details/ti_chamado_info_widget.dart (100 linhas)
class TIChamadoInfoWidget extends StatelessWidget {
  final Chamado chamado;
  // Informações (solicitante, data, descrição, anexos)
}

// features/ti/widgets/chamado_details/ti_chamado_timeline_widget.dart (150 linhas)
class TIChamadoTimelineWidget extends StatelessWidget {
  final String chamadoId;
  // Timeline com StreamBuilder
}

// features/ti/widgets/chamado_details/ti_chamado_comments_widget.dart (150 linhas)
class TIChamadoCommentsWidget extends StatefulWidget {
  final String chamadoId;
  // Comentários + form de adicionar
}

// features/ti/widgets/chamado_details/ti_chamado_actions_widget.dart (100 linhas)
class TIChamadoActionsWidget extends StatelessWidget {
  final Chamado chamado;
  final VoidCallback onAtribuir;
  final VoidCallback onFinalizar;
  // Botões de ação baseado em permissões
}
```

#### **3.4 Outros Arquivos Grandes**

**DashboardScreen (827 → 300 + widgets):**
```dart
// Quebrar em:
- DashboardScreen (orquestrador - 200 linhas)
- DashboardStatsWidget (estatísticas - 150 linhas)
- DashboardChartsWidget (gráficos - 200 linhas)
- DashboardRecentTicketsWidget (chamados recentes - 150 linhas)
```

**NotificationService (779 → 400 + helpers):**
```dart
// Quebrar em:
- NotificationService (core - 400 linhas)
- NotificationHelper (formatação de mensagens - 150 linhas)
- NotificationConfig (configurações - 100 linhas)
```

#### **3.5 Ações - Fase 3**
1. ✅ Mover templates para JSON
2. ✅ Criar TemplateLoaderService
3. ✅ Refatorar seed_templates.dart
4. ✅ Dividir ChamadoService em 4 services
5. ✅ Dividir TicketDetailsRefactored em 6 widgets
6. ✅ Dividir DashboardScreen em 4 widgets
7. ✅ Dividir NotificationService em 3 arquivos
8. ✅ Atualizar imports
9. ✅ Testar funcionalidades

---

### **FASE 4: ELIMINAR DUPLICAÇÃO** 🧹
**Tempo estimado:** 2-3 horas  
**Prioridade:** 🟡 MÉDIA

#### **4.1 Lógica de Filtros (Mixin Reutilizável)**

**ANTES (Repetido em 8 telas):**
```dart
// Em cada tela:
class _SomeDashboardState extends State<SomeDashboard> {
  StatusChamado? _filtroStatus;
  String _buscaTexto = '';
  
  List<Chamado> _aplicarFiltros(List<Chamado> chamados) {
    var resultado = chamados;
    
    if (_filtroStatus != null) {
      resultado = resultado.where((c) => c.status == _filtroStatus).toList();
    }
    
    if (_buscaTexto.isNotEmpty) {
      resultado = resultado.where((c) =>
        c.titulo.toLowerCase().contains(_buscaTexto) ||
        c.descricao.toLowerCase().contains(_buscaTexto)
      ).toList();
    }
    
    return resultado;
  }
}
```

**DEPOIS (Mixin reutilizável):**
```dart
// shared/mixins/filterable_mixin.dart
mixin FilterableMixin<T, S> on State {
  S? filtroStatus;
  String buscaTexto = '';
  
  // Método abstrato que cada tela implementa
  bool matchesFilter(T item, S? status, String texto);
  
  List<T> aplicarFiltros(List<T> items) {
    return items.where((item) => 
      matchesFilter(item, filtroStatus, buscaTexto)
    ).toList();
  }
  
  void limparFiltros() {
    setState(() {
      filtroStatus = null;
      buscaTexto = '';
    });
  }
}

// USO:
class _TIDashboardState extends State<TIDashboard> 
    with FilterableMixin<Chamado, StatusChamado> {
  
  @override
  bool matchesFilter(Chamado chamado, StatusChamado? status, String texto) {
    final statusMatch = status == null || chamado.status == status;
    final textoMatch = texto.isEmpty || 
      chamado.titulo.toLowerCase().contains(texto) ||
      chamado.descricao.toLowerCase().contains(texto);
    return statusMatch && textoMatch;
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Chamado>>(
      stream: service.getChamados(),
      builder: (context, snapshot) {
        final chamadosFiltrados = aplicarFiltros(snapshot.data ?? []);
        return ListView(children: ...);
      },
    );
  }
}
```

#### **4.2 Unificar Cards (1 base, 2 especializados)**

**ANTES:**
- `ticket_card.dart` (230 linhas)
- `ticket_card_v2.dart` (180 linhas)
- `_buildChamadoCard()` inline em manutenção (120 linhas)

**DEPOIS:**
```dart
// shared/widgets/base_card.dart (150 linhas)
class BaseChamadoCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String status;
  final String statusEmoji;
  final Color statusColor;
  final DateTime date;
  final String author;
  final Widget? badge;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onTap;
  
  // Card genérico e customizável
}

// features/ti/widgets/ti_chamado_card.dart (50 linhas)
class TIChamadoCard extends StatelessWidget {
  final Chamado chamado;
  
  @override
  Widget build(BuildContext context) {
    return BaseChamadoCard(
      id: chamado.id,
      title: chamado.titulo,
      description: chamado.descricao,
      status: chamado.status.label,
      statusEmoji: chamado.status.emoji,
      statusColor: chamado.status.color,
      date: chamado.dataAbertura,
      author: chamado.solicitanteNome,
      badge: chamado.prioridade == Prioridade.alta
        ? Icon(Icons.priority_high, color: Colors.red)
        : null,
      onTap: () => Navigator.pushNamed(...),
    );
  }
}

// features/manutencao/widgets/manutencao_chamado_card.dart (50 linhas)
class ManutencaoChamadoCard extends StatelessWidget {
  final ChamadoManutencao chamado;
  
  @override
  Widget build(BuildContext context) {
    return BaseChamadoCard(
      id: chamado.id,
      title: chamado.titulo,
      description: chamado.descricao,
      status: chamado.status.label,
      statusEmoji: chamado.status.emoji,
      statusColor: Color(int.parse('0xFF${chamado.status.colorHex}')),
      date: chamado.dataAbertura,
      author: chamado.criadorNome,
      badge: chamado.orcamento != null
        ? Icon(Icons.attach_money, color: Colors.green)
        : null,
      actionLabel: _getActionLabel(chamado),
      onAction: _getActionCallback(chamado),
      onTap: () => Navigator.push(...),
    );
  }
}

// DELETAR:
- ticket_card_v2.dart
- Métodos _buildChamadoCard inline
```

#### **4.3 Ações - Fase 4**
1. ✅ Criar FilterableMixin
2. ✅ Aplicar mixin em 8 telas
3. ✅ Remover código de filtro duplicado
4. ✅ Criar BaseChamadoCard
5. ✅ Migrar TIChamadoCard para base
6. ✅ Migrar ManutencaoChamadoCard para base
7. ✅ Deletar ticket_card_v2.dart
8. ✅ Remover inline cards
9. ✅ Testar funcionalidade de filtros

---

### **FASE 5: PADRONIZAÇÃO DE CÓDIGO** 📝
**Tempo estimado:** 2 horas  
**Prioridade:** 🟢 BAIXA

#### **5.1 Naming Conventions**
```dart
✅ PADRÃO DEFINIDO:
- Screens: {modulo}_{funcao}_screen.dart
  * ti_dashboard_screen.dart
  * manutencao_aprovar_orcamento_screen.dart
  * auth_login_screen.dart

- Widgets: {modulo}_{componente}_widget.dart
  * ti_chamado_card.dart
  * manutencao_filter_menu.dart
  * base_loading_indicator.dart

- Services: {modulo}_{tipo}_service.dart
  * ti_repository_service.dart
  * ti_business_service.dart
  * notification_service.dart

- Models: {modulo}_{entidade}.dart
  * ti_chamado.dart (renomear de chamado.dart)
  * manutencao_chamado.dart
  * user.dart (entities globais)

- Remover sufixos:
  * ticket_details_refactored.dart → ti_chamado_details_screen.dart
  * admin_management_screen_v2.dart → admin_management_screen.dart
```

#### **5.2 Imports (Escolher 1 padrão)**
```dart
✅ PADRÃO: Imports ABSOLUTOS (package:)

❌ ANTES (Relativo):
import '../../services/manutencao_service.dart';
import '../../../core/app_theme.dart';

✅ DEPOIS (Absoluto):
import 'package:helpdesk_ti/features/manutencao/services/manutencao_service.dart';
import 'package:helpdesk_ti/core/theme/app_theme.dart';

RAZÕES:
- Mais legível
- Independente de localização do arquivo
- Facilita refactoring (mover arquivos)
- Padrão da comunidade Flutter
```

#### **5.3 Ações - Fase 5**
1. ✅ Renomear arquivos seguindo padrão
2. ✅ Converter imports relativos → absolutos
3. ✅ Remover sufixos (_v2, _refactored)
4. ✅ Atualizar referências
5. ✅ Testar compilação

---

### **FASE 6: DOCUMENTAÇÃO E TESTES** 📚
**Tempo estimado:** 2 horas  
**Prioridade:** 🟢 BAIXA

#### **6.1 Documentar Arquitetura**
```markdown
// docs/ARQUITETURA.md
# Arquitetura do Projeto

## Estrutura de Pastas
- `core/`: Núcleo (services, theme, utils)
- `features/`: Módulos (ti, manutencao, auth)
- `shared/`: Componentes reutilizáveis
- `router/`: Navegação

## Padrões
- Feature-based (não por tipo)
- Repository + Business Service
- Widgets compostos (não gigantes)
- Mixins para lógica reutilizável

## Naming Conventions
...
```

#### **6.2 Adicionar Comentários JSDoc**
```dart
/// Service responsável por gerenciar chamados de TI
/// 
/// Orquestra [TIRepository] para CRUD e [NotificationService]
/// para notificações. Implementa regras de negócio da aplicação.
class TIBusinessService {
  /// Cria um novo chamado e notifica o técnico responsável
  /// 
  /// Parâmetros:
  /// - [chamado]: Dados do chamado a ser criado
  /// 
  /// Retorna: ID do chamado criado
  /// 
  /// Throws: [ValidationException] se dados inválidos
  Future<String> criarChamado(Chamado chamado) async { ... }
}
```

#### **6.3 Criar Testes Unitários (Básicos)**
```dart
// test/features/ti/services/ti_business_service_test.dart
void main() {
  group('TIBusinessService', () {
    test('Deve criar chamado e notificar técnico', () async {
      // Arrange
      final mockRepo = MockTIRepository();
      final mockNotification = MockNotificationService();
      final service = TIBusinessService(mockRepo, mockNotification);
      
      // Act
      await service.criarChamado(chamadoTeste);
      
      // Assert
      verify(mockRepo.create(chamadoTeste)).called(1);
      verify(mockNotification.notifyTecnico(...)).called(1);
    });
  });
}
```

#### **6.4 Ações - Fase 6**
1. ✅ Criar docs/ARQUITETURA.md
2. ✅ Adicionar JSDoc nos services principais
3. ✅ Criar testes unitários básicos (5-10 testes críticos)
4. ✅ Atualizar README.md

---

## 📈 MÉTRICAS DE SUCESSO

### **ANTES DA REFATORAÇÃO**
```
❌ Arquivos 500+ linhas: 24 arquivos
❌ Maior arquivo: 1.119 linhas
❌ Código duplicado: ~30%
❌ Visual inconsistente: TI ≠ Manutenção
❌ Arquitetura: Misturada (data/ + services/ + screens/)
❌ Naming: Inconsistente (prefixos, sufixos aleatórios)
❌ Imports: Misturado (relativo + absoluto)
❌ Manutenção: Difícil (código acoplado)
```

### **DEPOIS DA REFATORAÇÃO**
```
✅ Arquivos 500+ linhas: 0 arquivos
✅ Maior arquivo: ~400 linhas
✅ Código duplicado: <5%
✅ Visual consistente: TI ≈ Manutenção (mesmo design system)
✅ Arquitetura: Feature-based clara
✅ Naming: Consistente (padrão único)
✅ Imports: Absolutos (100%)
✅ Manutenção: Fácil (código desacoplado)
```

---

## ⏱️ CRONOGRAMA TOTAL

| Fase | Descrição | Tempo | Prioridade |
|------|-----------|-------|------------|
| 1 | Reorganização de Arquitetura | 3-4h | 🔴 CRÍTICA |
| 2 | Unificação Visual (TI ≈ Manutenção) | 4-5h | 🔴 CRÍTICA |
| 3 | Quebrar Arquivos Gigantes | 3-4h | 🟡 ALTA |
| 4 | Eliminar Duplicação | 2-3h | 🟡 MÉDIA |
| 5 | Padronização de Código | 2h | 🟢 BAIXA |
| 6 | Documentação e Testes | 2h | 🟢 BAIXA |
| **TOTAL** | **16-20 horas** | **2-3 dias** | |

---

## 🚀 PRÓXIMOS PASSOS

### **IMEDIATO (Hoje):**
1. ✅ Revisar este plano com usuário
2. ✅ Aprovar prioridades (FASES 1+2 são críticas)
3. ✅ Iniciar FASE 1 (Reorganização)

### **CURTO PRAZO (Amanhã):**
1. ✅ Concluir FASE 1
2. ✅ Iniciar FASE 2 (Unificação Visual)
3. ✅ Testar APK com novo design

### **MÉDIO PRAZO (Esta semana):**
1. ✅ Concluir FASE 2
2. ✅ Executar FASES 3-4
3. ✅ Deploy e testes finais

### **LONGO PRAZO (Próxima semana):**
1. ✅ Executar FASES 5-6 (polimento)
2. ✅ Documentação completa
3. ✅ Testes de integração

---

## ❓ PERGUNTAS PARA O USUÁRIO

1. **Prioridade:** Concordas que FASES 1+2 são críticas? (arquitetura + visual)
2. **Visual:** Preferes manter o design atual do TI ou do Manutenção como base?
3. **Tempo:** Tens disponibilidade para testar após cada fase ou preferes tudo junto no final?
4. **Escopo:** Há alguma funcionalidade nova para adicionar durante a refatoração?
5. **Breaking Changes:** Podemos fazer mudanças que quebrem dados existentes (ex: renomear collections)?

---

## 📋 CONCLUSÃO

O projeto está **funcional mas desorganizado**. A refatoração é **necessária** para:
- ✅ Manutenibilidade a longo prazo
- ✅ Adicionar novas features sem bagunçar mais
- ✅ Onboarding de novos desenvolvedores
- ✅ Reduzir bugs (código duplicado = bugs duplicados)
- ✅ Melhorar performance (menos código = app mais leve)

**Recomendação:** Iniciar pelas **FASES 1-2 (arquitetura + visual)** que são críticas e resolverão 70% dos problemas. FASES 3-6 são incrementais e podem ser feitas gradualmente.

---

**Status:** Aguardando aprovação para iniciar refatoração 🚀
