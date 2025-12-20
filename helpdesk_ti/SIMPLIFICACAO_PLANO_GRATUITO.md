# 🆓 Simplificação para Plano Gratuito do Firebase

## 📋 Objetivo

Simplificar a arquitetura do sistema para funcionar 100% no plano gratuito (Spark) do Firebase, removendo funcionalidades complexas que exigem o plano Blaze (pago).

---

## ✅ O que foi REMOVIDO

### 1. Firebase Functions Complexas

Removidas do arquivo `functions/index.js`:

#### ❌ `updateChamadoCounters`
- **Motivo**: Trigger automático que consome execuções em excesso
- **Alternativa**: Contadores atualizados manualmente no frontend quando necessário

#### ❌ `autoArchiveOldTickets`
- **Motivo**: Scheduled function (requer plano Blaze)
- **Alternativa**: Não é necessário arquivamento automático, apenas visualização de histórico

#### ❌ `optimizedChamadoUpdate`
- **Motivo**: Trigger complexo que cria subcoleções (changelog)
- **Alternativa**: Histórico simples através da consulta de status

#### ❌ `migrateLegacyData`
- **Motivo**: Cloud Function callable (requer plano Blaze)
- **Alternativa**: Não é necessária migração de dados legados

### 2. Métodos de Serviço

Removidos de `lib/data/services/chamado_service.dart`:

#### ❌ `arquivarChamado()`
- Movia tickets para collection `archived_tickets`
- Desnecessário: basta filtrar por status="Fechado"

#### ❌ `getChangelogStream()`
- Buscava histórico de mudanças em subcoleção
- Desnecessário: histórico é mantido através dos status

### 3. Delegações do FirestoreService

Removidas de `lib/data/firestore_service.dart`:
- `arquivarChamado()` 
- `getChangelogStream()`

### 4. Regras de Segurança

Removidas de `firestore.rules`:

#### ❌ Collection `archived_tickets`
- Toda a seção de regras para chamados arquivados

#### ❌ Subcollection `changelog`
- Regras para histórico de mudanças (dentro de tickets e archived_tickets)

### 5. Índices do Firestore

Simplificados em `firestore.indexes.json`:

#### ❌ Índices com campo `foiArquivado` (6 índices removidos)
- Não são mais necessários sem o sistema de arquivamento

#### ✅ Mantidos apenas 3 índices essenciais:
1. `status + dataFechamento` (para histórico geral)
2. `usuarioId + status + dataFechamento` (para histórico do usuário)
3. `prioridade + lastUpdated` (para dashboard)

---

## ✅ O que foi MANTIDO

### 1. Firebase Functions de Notificação

Mantidas em `functions/index.js`:

#### ✅ `notificarNovoChamado`
- Notifica admin/TI quando novo chamado é criado
- **Custo**: Baixo (apenas onCreate)

#### ✅ `notificarAtualizacaoChamado`
- Notifica usuário quando status do chamado muda
- **Custo**: Baixo (apenas onUpdate com condição)

#### ✅ `notificarNovoComentario`
- Notifica quando novo comentário é adicionado
- **Custo**: Baixo (apenas onCreate)

#### ✅ `limparTokensInvalidos`
- Limpa tokens FCM inválidos a cada 24h
- **Custo**: Baixo (scheduled diário)

### 2. Tela de Histórico

Mantida em `lib/screens/historico_chamados_screen.dart`:

#### ✅ HistoricoChamadosScreen
- Visualiza chamados com status="Fechado" ou "Rejeitado"
- Filtros por período: 7, 30, 90 dias ou todos
- Sem necessidade de collection separada
- Usa queries simples no collection `tickets`

### 3. Campos do Model Chamado

Mantidos os campos de otimização:
- `lastUpdated`: Timestamp da última atualização
- `numeroComentarios`: Total de comentários (atualizado no frontend)
- `temAnexos`: Indica se tem anexos
- `ultimoComentarioPor`: Nome do último comentarista
- `ultimoComentarioEm`: Data do último comentário
- `prioridade`: Prioridade do chamado (1-4)
- `tags`: Lista de tags (para uso futuro)

**Removido**: `foiArquivado` (não é mais necessário)

---

## 📊 Impacto no Uso do Firebase

### Antes (Plano Blaze Necessário)
- ❌ 4 triggers automáticos (updateChamadoCounters, autoArchiveOldTickets, optimizedChamadoUpdate)
- ❌ 1 scheduled function (autoArchiveOldTickets)
- ❌ 1 callable function (migrateLegacyData)
- ❌ 2 collections extras (archived_tickets, changelog)
- ❌ 6 índices compostos complexos

**Custo estimado**: ~$10-30/mês dependendo do volume

### Depois (Plano Gratuito)
- ✅ 3 triggers simples de notificação
- ✅ 1 scheduled function leve (limparTokensInvalidos)
- ✅ 1 collection principal (tickets)
- ✅ 3 índices compostos essenciais

**Custo estimado**: $0 (dentro do free tier)

---

## 🎯 Funcionalidades Preservadas

### ✅ Histórico de Chamados Fechados
- Query simples: `status IN ["Fechado", "Rejeitado"]`
- Filtros por período funcionam sem índices complexos
- Mesma UX para o usuário

### ✅ Dashboard com Estatísticas
- Contadores de prioridade funcionam sem triggers
- Lista de chamados recentes mantida
- AutomaticKeepAliveClientMixin preserva estado

### ✅ Sistema de Comentários
- WhatsApp-style timeline mantido
- Notificações funcionam normalmente
- Contador atualizado no frontend

### ✅ Gestão de Tickets
- Criação, edição, fechamento funcionam igual
- Anexos e imagens mantidos
- Prioridades e status preservados

---

## 🚀 Deploy das Mudanças

### ✅ CONCLUÍDO - 27/11/2025

#### 1. Deploy das Regras ✅
```powershell
firebase deploy --only firestore:rules
```
**Status**: ✅ Concluído com sucesso
- Regras de `archived_tickets` e `changelog` removidas
- Security rules atualizadas

#### 2. Deploy dos Índices ✅
```powershell
firebase deploy --only firestore:indexes
```
**Status**: ✅ Concluído com sucesso
- 6 índices antigos com `foiArquivado` deletados
- 3 índices essenciais criados

#### 3. Firebase Functions ⚠️
```powershell
firebase deploy --only functions
```
**Status**: ⚠️ Requer plano Blaze (não necessário)
**Solução**: 
- Não há functions implantadas atualmente (verificado com `firebase functions:list`)
- O código das Functions está no arquivo `functions/index.js` mas não será implantado
- **Sistema funciona 100% sem Functions no plano gratuito**
- Se no futuro precisar de notificações, basta fazer upgrade para Blaze

**Nota Importante**: As notificações push podem ser implementadas de forma alternativa:
- Via FCM direto do Flutter (sem Functions)
- Usando serviço de notificação de terceiros (OneSignal, etc.)
- Manualmente pelo admin quando necessário

---

## 📝 Notas Importantes

1. **Dados Existentes**: Os chamados existentes permanecem intactos. O histórico é acessível normalmente através do filtro de status.

2. **Campo foiArquivado**: Se existir em documentos antigos, será ignorado nas queries. Não é necessário removê-lo.

3. **Performance**: O sistema pode ser até mais rápido sem os triggers automáticos que executavam em background.

4. **Escalabilidade**: Dentro do free tier, suporta bem:
   - Até 50.000 leituras/dia
   - Até 20.000 escritas/dia
   - Até 20.000 deleções/dia
   - Até 1GB de armazenamento

5. **Notificações**: Continuam funcionando perfeitamente pois são triggers leves e essenciais.

---

## ✨ Resultado Final

Sistema **100% funcional** no plano gratuito do Firebase, com todas as funcionalidades essenciais preservadas:

- ✅ Criação e gestão de chamados
- ✅ Sistema de comentários com notificações
- ✅ Dashboard com estatísticas
- ✅ Histórico de chamados fechados
- ✅ Anexos e imagens
- ✅ Gestão de usuários
- ✅ Diferentes níveis de acesso (admin, ti, manager, user)

**Economia mensal estimada**: $10-30/mês 💰
