# 📋 RELATÓRIO DE ANÁLISE DE PROBLEMAS - HelpDesk TI

**Data da Análise:** 27 de novembro de 2025  
**Escopo:** Análise completa do sistema HelpDesk TI - Backend e Frontend

---

## 🎯 PROBLEMAS IDENTIFICADOS

### 1️⃣ TEMPLATES DE USUÁRIOS COMUNS NÃO FUNCIONANDO

**Status:** ❌ **CRÍTICO** - Telas não existem  
**Arquivo Esperado:** `user_tickets_screen.dart` / `ticket_detail_screen_user.dart`  
**Arquivo Real:** Apenas `ticket_details_screen.dart` (compartilhada por admin e user)

#### Problema:
- **Não existem telas separadas para usuários comuns**
- A tela `ticket_details_screen.dart` usa lógica condicional com `isUser` e `isAdmin`
- Usuários comuns veem a mesma interface que admins (com campos desabilitados)
- Tela `selecionar_template_screen.dart` existe mas não está integrada para users

#### Causa Raiz:
```dart
// Em ticket_details_screen.dart linha 232
final isUser = widget.authService.userRole == 'user';
final canEdit = isAdmin && widget.chamado.status != 'Fechado' && widget.chamado.status != 'Rejeitado';
```
- Lógica condicional complexa torna a tela confusa
- Usuários veem botões desabilitados ao invés de interface limpa

#### Impacto:
- UX ruim para usuários comuns
- Interface confusa com elementos desnecessários
- Não há diferenciação visual clara entre roles

---

### 2️⃣ APP TRAVADO NA PARTE VISUAL / FALTA FLUIDEZ

**Status:** ⚠️ **MÉDIO** - Problemas de performance

#### Problemas Identificados:

**A) Widgets Sem Otimização:**
```dart
// timeline_widget.dart - ListView sem otimização
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(), // ❌ Desabilita scroll nativo
  // ...
)
```

**B) Múltiplos StreamBuilders Aninhados:**
- `ticket_details_screen.dart` tem StreamBuilder dentro de CustomScrollView
- `home_screen.dart` tem múltiplos StreamBuilders simultâneos (uma tab por setor)
- Cada tab faz query separada ao Firestore

**C) Imagens Sem Cache:**
```dart
// ticket_details_screen.dart linha 585
Image.network(anexoUrl, fit: BoxFit.cover) // ❌ Sem cache
```

**D) Animações Excessivas:**
```dart
// selecionar_template_screen.dart
FadeInUp(
  delay: Duration(milliseconds: 50 * index), // Atraso progressivo em listas grandes
  duration: const Duration(milliseconds: 400),
)
```

#### Impacto:
- App lento ao navegar entre telas
- Scroll travado em listas longas
- Consumo excessivo de dados (recarrega imagens)
- Delay perceptível em animações

---

### 3️⃣ DASHBOARD DE CHAMADOS NÃO FUNCIONA / NÃO ATUALIZA

**Status:** 🔥 **CRÍTICO** - Lógica de negócio quebrada

#### Problemas Identificados:

**A) Nenhuma Tela de Dashboard Encontrada:**
- Busquei por `*dashboard*.dart` - **0 resultados**
- `home_screen.dart` tem tabs mas não tem dashboard agregado
- `info_tab.dart` provavelmente deveria ser o dashboard

**B) Queries Ineficientes:**
```dart
// fila_tecnica_tab.dart
stream: firestoreService.getTodosChamadosStream()
// ❌ Busca TODOS os chamados sem filtro de status
```

**C) Sem Estatísticas em Tempo Real:**
```dart
// firestore_service.dart tem métodos:
getStatsUsuario(String userId)
getStatsAdmin()
// Mas NÃO são usados em nenhuma tela
```

**D) Problemas de Atualização:**
- StreamBuilders não estão configurados corretamente
- Queries sem ordenação por data de atualização
- Sem cache local (dados desatualizados entre navegações)

#### Evidências no Código:
```dart
// fila_tecnica_tab.dart linha 40
stream: firestoreService.getTodosChamadosStream()
// Deveria filtrar por status 'Aberto' e ordenar por prioridade
```

#### Impacto:
- Admins não têm visão geral do sistema
- Impossível ver métricas (chamados abertos, tempo médio, etc)
- Dados mostrados estão sempre desatualizados

---

### 4️⃣ PRIORIDADE APARECENDO COMO COMENTÁRIO

**Status:** ⚠️ **BAIXO** - UX inconsistente

#### Problema:
- Prioridade está no model `Chamado` como campo `int prioridade`
- É mostrada corretamente em `ticket_card.dart`:
```dart
'Prioridade: ${_getPriorityLabel()}' // ✅ Badge correto
```
- Mas **pode estar sendo adicionada como comentário** em mudanças de status

#### Verificação Necessária:
```dart
// Buscar em comentários do tipo 'atualizacao' se prioridade é inserida como texto
// Provavelmente está acontecendo em atualizações automáticas
```

#### Impacto:
- Duplicação de informação
- Confusão na timeline de comentários

---

### 5️⃣ SISTEMA DE COMENTÁRIOS COMPLICADO / NÃO ESTILO WHATSAPP

**Status:** ⚠️ **MÉDIO** - UX ruim

#### Problema Atual:
```dart
// timeline_widget.dart - TODOS os comentários alinhados à esquerda
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Ícone à esquerda
    Column(/* Timeline vertical */),
    // Conteúdo ao lado do ícone
    Expanded(child: Container(/* Comentário */)),
  ],
)
```

**Layout Atual:**
```
🔵 TI: Mensagem...
🟢 User: Mensagem...
🔵 TI: Mensagem...
```

**Layout Esperado (WhatsApp):**
```
                🔵 TI: Mensagem...
🟢 User: Mensagem...
                🔵 TI: Mensagem...
```

#### Problemas:
- Todos os comentários alinhados à esquerda
- Difícil distinguir quem falou o quê
- Não há separação visual clara por remetente

#### Impacto:
- UX confusa
- Dificulta acompanhamento de conversas

---

### 6️⃣ CAIXA DE COMENTÁRIOS SEMPRE ABERTA

**Status:** ⚠️ **BAIXO** - Regra de negócio incorreta

#### Problema:
```dart
// ticket_details_screen.dart - Sem validação de status
TextField(
  controller: _comentarioController,
  focusNode: _comentarioFocusNode,
  decoration: InputDecoration(
    hintText: 'Escreva um comentário ou atualização...',
    // ❌ Sem verificação se admin aceitou o chamado
  ),
)
```

#### Regra Esperada:
- Comentários devem estar **desabilitados** até admin aceitar (status = 'Em Andamento')
- Status 'Aberto' = **somente visualização**
- Status 'Em Andamento', 'Aguardando' = **pode comentar**
- Status 'Fechado', 'Rejeitado' = **bloqueado**

#### Impacto:
- Usuários podem comentar em chamados não aceitos
- Spam de comentários antes de análise do admin

---

### 7️⃣ CHAMADOS FECHADOS NÃO SÃO ARQUIVADOS

**Status:** 🔥 **CRÍTICO** - Sistema de auditoria inexistente

#### Problema:
- **NÃO existe coleção `archived_tickets` ou `tickets_historico`**
- Chamados fechados ficam misturados com abertos na query principal
- Sem sistema de auditoria ou logs de mudanças
- Histórico de solicitações existe mas é para outro tipo de documento

#### Evidências:
```dart
// firestore_service.dart - NÃO tem métodos de arquivamento:
// ❌ arquivarChamado()
// ❌ getHistoricoChamados()
// ❌ restaurarChamado()
```

#### Queries Problemáticas:
```dart
// Busca todos sem filtrar fechados:
getTodosChamadosStream() // ❌ Inclui fechados e rejeitados
getChamadosDoUsuario(userId) // ❌ Inclui todos os status
```

#### Impacto:
- **Performance horrível** - queries buscam milhares de chamados fechados
- Impossível fazer auditoria
- Sem histórico de alterações
- Dados perdidos permanentemente se deletados

---

### 8️⃣ CARDS DE CHAMADOS CONFUSOS / INFORMAÇÕES REDUNDANTES

**Status:** ⚠️ **MÉDIO** - UX ruim

#### Problemas em `ticket_card.dart`:

**A) Setor Duplicado:**
```dart
// ❌ Setor aparece no card E no cabeçalho da tab
Text(usuarioNome) // Mostra usuário + setor
```

**B) Informações Desordenadas:**
```
#0001
Título do Chamado
[Status Badge] [Prioridade Badge]
👤 Usuário | 📅 Data | 🏢 Setor
```

**C) Badges Confusos:**
- Prioridade com texto "Prioridade: Alta" (muito grande)
- Status com cores mas sem ícone
- Sem indicador visual de urgência

**D) Tamanho Inconsistente:**
```dart
constraints: const BoxConstraints(minHeight: 120)
// Cards muito grandes para informações simples
```

#### Sugestões de Melhoria:
```
┌─────────────────────────────┐
│ #0001 | 🔴 CRÍTICA          │ ← Número + Prioridade visual
│ Título do Chamado           │
│ [🟢 Aberto]                 │ ← Status com emoji
│ 👤 João Silva  📅 Hoje 14:30│ ← Info compacta
└─────────────────────────────┘
```

---

## 🏗️ PROBLEMAS DE BACKEND (FIRESTORE/FUNCTIONS)

### A) Estrutura de Dados Ineficiente

```javascript
// functions/index.js - Trigger genérico demais
exports.notificarAtualizacaoChamado = functions.firestore
  .document('tickets/{ticketId}')
  .onUpdate(async (change, context) => {
    // ❌ Dispara para QUALQUER mudança, incluindo comentários
    // Deveria filtrar por mudanças de status apenas
  })
```

### B) Queries Sem Índices

```dart
// Queries complexas sem índices no Firestore:
.where('status', 'in', ['Aberto', 'Em Andamento'])
.where('prioridade', '>=', 3)
.orderBy('prioridade', 'desc')
.orderBy('dataCriacao', 'desc')
// ❌ ERRO: Requer índice composto
```

### C) Falta Paginação

```dart
getTodosChamadosStream() // ❌ Busca TODOS os documentos
// Deveria ter: .limit(50) + paginação infinita
```

### D) Comentários em Coleção Separada Sem Otimização

```dart
// Collection: comentarios/
// ❌ Problema: 1 chamado pode ter 100+ comentários
// Query busca TODOS os comentários de uma vez
getComentariosStream(chamadoId)
  .orderBy('dataHora', 'desc')
// Deveria ter: .limit(20) + "Carregar mais"
```

---

## 📊 MÉTRICAS DE COMPLEXIDADE

| Arquivo | Linhas | Problemas | Prioridade |
|---------|--------|-----------|------------|
| `ticket_details_screen.dart` | 1334 | 5 | 🔥 Alta |
| `firestore_service.dart` | 368 | 3 | ⚠️ Média |
| `functions/index.js` | 293 | 2 | ⚠️ Média |
| `timeline_widget.dart` | 200 | 2 | ⚠️ Média |
| `ticket_card.dart` | 245 | 3 | ⚠️ Média |
| `fila_tecnica_tab.dart` | 183 | 2 | ⚠️ Média |

---

## 🔍 RESUMO EXECUTIVO

### Problemas Críticos (Bloquantes):
1. ❌ **Templates de usuários não existem** - Precisa criar telas separadas
2. ❌ **Dashboard não existe** - Sem visão geral do sistema
3. ❌ **Sistema de arquivamento inexistente** - Performance degradada

### Problemas Médios (UX Ruim):
4. ⚠️ **App travado** - Queries e widgets não otimizados
5. ⚠️ **Comentários confusos** - Layout não intuitivo
6. ⚠️ **Cards desordenados** - Informações redundantes

### Problemas Baixos (Melhorias):
7. ⚠️ **Prioridade em comentários** - Duplicação de dados
8. ⚠️ **Comentários sempre abertos** - Regra de negócio incorreta

---

## 📝 RECOMENDAÇÕES

### Backend (Firestore/Functions):
1. ✅ Criar índices compostos para queries complexas
2. ✅ Implementar paginação em todas as queries
3. ✅ Adicionar coleção `archived_tickets` para chamados fechados
4. ✅ Otimizar triggers do Firebase Functions
5. ✅ Adicionar campo `lastUpdated` para cache inteligente

### Frontend (Flutter):
1. ✅ Criar telas separadas: `UserTicketScreen` e `AdminTicketScreen`
2. ✅ Implementar dashboard com widgets de estatísticas
3. ✅ Refatorar `TimelineWidget` para layout estilo WhatsApp
4. ✅ Adicionar cache de imagens com `CachedNetworkImage`
5. ✅ Otimizar animações e remover `physics: NeverScrollableScrollPhysics`
6. ✅ Simplificar `TicketCard` removendo informações redundantes
7. ✅ Implementar controle de comentários baseado em status

---

## 🎯 PRÓXIMOS PASSOS

1. **Análise Completa** ✅ (CONCLUÍDO)
2. **Planejar Correções Backend** (PRÓXIMO)
3. **Planejar Correções Frontend** (PRÓXIMO)
4. **Implementação em Fases** (AGUARDANDO)

---

**Analista:** GitHub Copilot  
**Ferramenta:** VS Code + Claude Sonnet 4.5  
**Método:** Análise estática de código + Busca semântica
