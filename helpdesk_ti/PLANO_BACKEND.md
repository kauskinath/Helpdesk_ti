# 🏗️ PLANO DE CORREÇÕES - BACKEND

**Projeto:** HelpDesk TI  
**Fase:** Backend (Firestore + Firebase Functions)  
**Prioridade:** Executar ANTES do frontend

---

## 📋 ÍNDICE

1. [Estrutura de Dados](#1-estrutura-de-dados)
2. [Firebase Functions](#2-firebase-functions)
3. [Firestore Indexes](#3-firestore-indexes)
4. [Firestore Rules](#4-firestore-rules)
5. [Services (Dart)](#5-services-dart)

---

## 1️⃣ ESTRUTURA DE DADOS

### A) Nova Coleção: `archived_tickets`

**Objetivo:** Separar chamados fechados para melhorar performance

```javascript
// Estrutura do documento
{
  // Todos os campos do chamado original
  ...chamadoOriginal,
  
  // Novos campos de arquivamento
  "archivedAt": Timestamp,
  "archivedBy": "adminId",
  "archivedByName": "Admin Name",
  "originalTicketId": "tickets/abc123",
  
  // Histórico de mudanças
  "changeLog": [
    {
      "timestamp": Timestamp,
      "field": "status",
      "oldValue": "Em Andamento",
      "newValue": "Fechado",
      "changedBy": "adminId",
      "changedByName": "Admin Name"
    }
  ],
  
  // Totalizadores para relatórios
  "tempoTotal": 3600, // segundos
  "numeroComentarios": 5,
  "foiAvaliado": true,
  "notaAvaliacao": 5
}
```

**Migração Necessária:**
```javascript
// Cloud Function para migrar chamados antigos fechados
exports.migrarChamadosFechados = functions.https.onCall(async (data, context) => {
  const ticketsRef = admin.firestore().collection('tickets');
  const archivedRef = admin.firestore().collection('archived_tickets');
  
  const snapshot = await ticketsRef
    .where('status', 'in', ['Fechado', 'Rejeitado'])
    .get();
  
  const batch = admin.firestore().batch();
  let count = 0;
  
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const archivedDoc = archivedRef.doc(doc.id);
    
    batch.set(archivedDoc, {
      ...data,
      archivedAt: admin.firestore.FieldValue.serverTimestamp(),
      archivedBy: 'SYSTEM',
      archivedByName: 'Sistema de Migração',
      originalTicketId: `tickets/${doc.id}`,
      changeLog: [],
      tempoTotal: data.dataFechamento && data.dataCriacao 
        ? (data.dataFechamento.toMillis() - data.dataCriacao.toMillis()) / 1000 
        : 0,
    });
    
    batch.delete(doc.ref);
    count++;
  });
  
  await batch.commit();
  return { success: true, migrated: count };
});
```

---

### B) Nova Subcoleção: `tickets/{id}/changelog`

**Objetivo:** Rastrear TODAS as mudanças em um chamado

```javascript
{
  "timestamp": Timestamp,
  "action": "status_change" | "priority_change" | "assignment" | "comment_added" | "attachment_added",
  "performedBy": "userId",
  "performedByName": "User Name",
  "performedByRole": "admin" | "user",
  "details": {
    "field": "status",
    "oldValue": "Aberto",
    "newValue": "Em Andamento"
  },
  "metadata": {
    "ipAddress": "192.168.1.1", // Opcional
    "userAgent": "Mozilla/5.0...", // Opcional
  }
}
```

**Implementação:**
```javascript
// Helper function para adicionar ao changelog
async function addToChangeLog(ticketId, change) {
  await admin.firestore()
    .collection('tickets')
    .doc(ticketId)
    .collection('changelog')
    .add({
      ...change,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
}

// Exemplo de uso
await addToChangeLog('ticket123', {
  action: 'status_change',
  performedBy: adminId,
  performedByName: adminNome,
  performedByRole: 'admin',
  details: {
    field: 'status',
    oldValue: 'Aberto',
    newValue: 'Em Andamento'
  }
});
```

---

### C) Adicionar Campos no Model `Chamado`

```dart
// lib/models/chamado.dart
class Chamado {
  // ... campos existentes ...
  
  // NOVOS CAMPOS:
  final DateTime? lastUpdated; // Timestamp da última atualização
  final int numeroComentarios; // Contador de comentários
  final bool temAnexos; // Flag para saber se tem anexos
  final String? ultimoComentarioPor; // Nome do último comentarista
  final DateTime? ultimoComentarioEm; // Data do último comentário
  final bool foiArquivado; // Flag se está arquivado
  final List<String> tags; // Tags para busca e filtros
  
  Chamado({
    // ... parâmetros existentes ...
    this.lastUpdated,
    this.numeroComentarios = 0,
    this.temAnexos = false,
    this.ultimoComentarioPor,
    this.ultimoComentarioEm,
    this.foiArquivado = false,
    this.tags = const [],
  });
}
```

---

### D) Adicionar Índice na Coleção `comentarios`

```javascript
// Estrutura atual:
{
  "chamadoId": "ticket123",
  "autorId": "user456",
  "autorNome": "João Silva",
  "autorRole": "user",
  "mensagem": "Texto do comentário",
  "dataHora": Timestamp,
  "tipo": "comentario" | "atualizacao" | "mudanca_status"
}

// ADICIONAR:
{
  // ... campos existentes ...
  "isSystemMessage": false, // Se foi gerado automaticamente
  "mentions": ["user789"], // IDs de usuários mencionados
  "attachments": [], // URLs de anexos no comentário
  "edited": false, // Se foi editado
  "editedAt": null, // Timestamp da edição
}
```

---

## 2️⃣ FIREBASE FUNCTIONS

### A) Otimizar Trigger de Atualização

**Problema Atual:**
```javascript
// Dispara para QUALQUER mudança no documento
exports.notificarAtualizacaoChamado = functions.firestore
  .document('tickets/{ticketId}')
  .onUpdate(async (change, context) => {
    const antes = change.before.data();
    const depois = change.after.data();
    
    // Verifica se status mudou (mas já carregou documento inteiro)
    if (antes.status === depois.status) {
      return null;
    }
    // ...
  });
```

**Solução:**
```javascript
exports.notificarAtualizacaoChamado = functions.firestore
  .document('tickets/{ticketId}')
  .onUpdate(async (change, context) => {
    const antes = change.before.data();
    const depois = change.after.data();
    
    // ✅ Verificação imediata ANTES de qualquer processamento
    const statusMudou = antes.status !== depois.status;
    const prioridadeMudou = antes.prioridade !== depois.prioridade;
    const adminAtribuido = !antes.adminId && depois.adminId;
    
    if (!statusMudou && !prioridadeMudou && !adminAtribuido) {
      console.log('ℹ️ Nenhuma mudança relevante, ignorando...');
      return null;
    }
    
    // ✅ Adicionar ao changelog
    await change.after.ref.collection('changelog').add({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      action: statusMudou ? 'status_change' : 
              prioridadeMudou ? 'priority_change' : 
              'assignment',
      details: {
        field: statusMudou ? 'status' : 
                prioridadeMudou ? 'prioridade' : 
                'adminId',
        oldValue: statusMudou ? antes.status : 
                  prioridadeMudou ? antes.prioridade : 
                  null,
        newValue: statusMudou ? depois.status : 
                  prioridadeMudou ? depois.prioridade : 
                  depois.adminId,
      },
    });
    
    // Continua com notificações...
  });
```

---

### B) Nova Function: Arquivar Automaticamente

```javascript
/**
 * Arquiva automaticamente chamados fechados após 30 dias
 * Executa diariamente às 2h da manhã
 */
exports.arquivarChamadosAntigos = functions.pubsub
  .schedule('0 2 * * *') // Cron: todo dia às 2h
  .timeZone('America/Sao_Paulo')
  .onRun(async (context) => {
    console.log('🗄️ Iniciando arquivamento automático...');
    
    const trintaDiasAtras = new Date();
    trintaDiasAtras.setDate(trintaDiasAtras.getDate() - 30);
    
    const ticketsRef = admin.firestore().collection('tickets');
    const archivedRef = admin.firestore().collection('archived_tickets');
    
    const snapshot = await ticketsRef
      .where('status', 'in', ['Fechado', 'Rejeitado'])
      .where('dataFechamento', '<=', trintaDiasAtras)
      .get();
    
    if (snapshot.empty) {
      console.log('✅ Nenhum chamado para arquivar');
      return null;
    }
    
    const batch = admin.firestore().batch();
    let count = 0;
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const archivedDoc = archivedRef.doc(doc.id);
      
      // Buscar avaliação (se existir)
      const avaliacaoSnap = await admin.firestore()
        .collection('avaliacoes')
        .where('chamadoId', '==', doc.id)
        .limit(1)
        .get();
      
      const foiAvaliado = !avaliacaoSnap.empty;
      const notaAvaliacao = foiAvaliado 
        ? avaliacaoSnap.docs[0].data().nota 
        : null;
      
      // Contar comentários
      const comentariosSnap = await admin.firestore()
        .collection('comentarios')
        .where('chamadoId', '==', doc.id)
        .get();
      
      batch.set(archivedDoc, {
        ...data,
        archivedAt: admin.firestore.FieldValue.serverTimestamp(),
        archivedBy: 'SYSTEM',
        archivedByName: 'Arquivamento Automático',
        originalTicketId: `tickets/${doc.id}`,
        tempoTotal: data.dataFechamento && data.dataCriacao 
          ? (data.dataFechamento.toMillis() - data.dataCriacao.toMillis()) / 1000 
          : 0,
        numeroComentarios: comentariosSnap.size,
        foiAvaliado,
        notaAvaliacao,
      });
      
      batch.delete(doc.ref);
      count++;
    }
    
    await batch.commit();
    console.log(`✅ ${count} chamados arquivados com sucesso`);
    
    return { success: true, archived: count };
  });
```

---

### C) Nova Function: Atualizar Contadores

```javascript
/**
 * Atualiza contadores no documento principal quando comentário é adicionado
 */
exports.atualizarContadores = functions.firestore
  .document('comentarios/{comentarioId}')
  .onCreate(async (snap, context) => {
    const comentario = snap.data();
    const ticketRef = admin.firestore()
      .collection('tickets')
      .doc(comentario.chamadoId);
    
    await ticketRef.update({
      numeroComentarios: admin.firestore.FieldValue.increment(1),
      ultimoComentarioPor: comentario.autorNome,
      ultimoComentarioEm: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`✅ Contadores atualizados para ticket ${comentario.chamadoId}`);
    return null;
  });
```

---

## 3️⃣ FIRESTORE INDEXES

### Criar Índices Compostos Necessários

**Arquivo:** `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "prioridade", "order": "DESCENDING" },
        { "fieldPath": "dataCriacao", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "usuarioId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "lastUpdated", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "adminId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "prioridade", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "foiArquivado", "order": "ASCENDING" },
        { "fieldPath": "lastUpdated", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "archived_tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "usuarioId", "order": "ASCENDING" },
        { "fieldPath": "archivedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "comentarios",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "chamadoId", "order": "ASCENDING" },
        { "fieldPath": "dataHora", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "changelog",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Deploy:**
```powershell
firebase deploy --only firestore:indexes
```

---

## 4️⃣ FIRESTORE RULES

### Adicionar Regras de Segurança

**Arquivo:** `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    function isAdmin() {
      return isAuthenticated() && getUserRole() in ['admin', 'ti'];
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Tickets - acesso baseado em role
    match /tickets/{ticketId} {
      // Leitura: admins veem tudo, users veem apenas seus
      allow read: if isAdmin() || isOwner(resource.data.usuarioId);
      
      // Criação: qualquer usuário autenticado
      allow create: if isAuthenticated() 
        && request.resource.data.usuarioId == request.auth.uid;
      
      // Atualização: apenas admins ou dono (para comentários)
      allow update: if isAdmin() || isOwner(resource.data.usuarioId);
      
      // Deleção: apenas admins
      allow delete: if isAdmin();
      
      // Subcoleção changelog - apenas leitura
      match /changelog/{changeId} {
        allow read: if isAdmin() || isOwner(get(/databases/$(database)/documents/tickets/$(ticketId)).data.usuarioId);
        allow write: if false; // Apenas via Functions
      }
    }
    
    // Archived Tickets - apenas admins
    match /archived_tickets/{ticketId} {
      allow read: if isAdmin();
      allow write: if false; // Apenas via Functions
    }
    
    // Comentários
    match /comentarios/{comentarioId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() 
        && request.resource.data.autorId == request.auth.uid;
      allow update, delete: if false; // Comentários não podem ser editados/deletados
    }
    
    // Avaliações
    match /avaliacoes/{avaliacaoId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() 
        && request.resource.data.usuarioId == request.auth.uid;
      allow update, delete: if false;
    }
    
    // Templates - apenas admins
    match /templates/{templateId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Users - leitura para todos, escrita apenas para próprio user
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) || isAdmin();
    }
  }
}
```

**Deploy:**
```powershell
firebase deploy --only firestore:rules
```

---

## 5️⃣ SERVICES (DART)

### A) Adicionar Métodos em `ChamadoService`

```dart
// lib/data/services/chamado_service.dart

/// Busca apenas chamados ativos (não arquivados)
Stream<List<Chamado>> getChamadosAtivosStream() {
  return _firestore
      .collection('tickets')
      .where('foiArquivado', isEqualTo: false)
      .where('status', whereIn: ['Aberto', 'Em Andamento', 'Aguardando'])
      .orderBy('lastUpdated', descending: true)
      .limit(50) // ✅ Paginação
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Chamado.fromMap(doc.data(), doc.id))
          .toList());
}

/// Busca chamados por prioridade (para dashboard)
Future<Map<String, int>> getChamadosPorPrioridade() async {
  final snapshot = await _firestore
      .collection('tickets')
      .where('foiArquivado', isEqualTo: false)
      .get();
  
  final contadores = {
    'critica': 0,
    'alta': 0,
    'media': 0,
    'baixa': 0,
  };
  
  for (var doc in snapshot.docs) {
    final prioridade = doc.data()['prioridade'] ?? 2;
    switch (prioridade) {
      case 4:
        contadores['critica'] = contadores['critica']! + 1;
        break;
      case 3:
        contadores['alta'] = contadores['alta']! + 1;
        break;
      case 2:
        contadores['media'] = contadores['media']! + 1;
        break;
      case 1:
        contadores['baixa'] = contadores['baixa']! + 1;
        break;
    }
  }
  
  return contadores;
}

/// Arquiva um chamado
Future<void> arquivarChamado(String chamadoId) async {
  final chamadoRef = _firestore.collection('tickets').doc(chamadoId);
  final chamado = await chamadoRef.get();
  
  if (!chamado.exists) {
    throw Exception('Chamado não encontrado');
  }
  
  final data = chamado.data()!;
  
  // Copiar para archived_tickets
  await _firestore.collection('archived_tickets').doc(chamadoId).set({
    ...data,
    'archivedAt': FieldValue.serverTimestamp(),
    'originalTicketId': 'tickets/$chamadoId',
  });
  
  // Deletar original
  await chamadoRef.delete();
}

/// Busca changelog de um chamado
Stream<List<Map<String, dynamic>>> getChangelogStream(String chamadoId) {
  return _firestore
      .collection('tickets')
      .doc(chamadoId)
      .collection('changelog')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
}
```

---

### B) Atualizar `FirestoreService` (Fachada)

```dart
// lib/data/firestore_service.dart

// Adicionar delegações:

Stream<List<Chamado>> getChamadosAtivosStream() =>
    _chamadoService.getChamadosAtivosStream();

Future<Map<String, int>> getChamadosPorPrioridade() =>
    _chamadoService.getChamadosPorPrioridade();

Future<void> arquivarChamado(String chamadoId) =>
    _chamadoService.arquivarChamado(chamadoId);

Stream<List<Map<String, dynamic>>> getChangelogStream(String chamadoId) =>
    _chamadoService.getChangelogStream(chamadoId);
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Firestore Structure:
- [ ] Criar coleção `archived_tickets`
- [ ] Adicionar subcoleção `changelog` nos tickets
- [ ] Adicionar novos campos no model `Chamado`
- [ ] Atualizar campos na coleção `comentarios`

### Firebase Functions:
- [ ] Otimizar trigger `notificarAtualizacaoChamado`
- [ ] Criar function `arquivarChamadosAntigos`
- [ ] Criar function `atualizarContadores`
- [ ] Criar function `migrarChamadosFechados` (uma vez)

### Firestore Indexes:
- [ ] Criar arquivo `firestore.indexes.json`
- [ ] Adicionar 7 índices compostos
- [ ] Deploy com `firebase deploy --only firestore:indexes`

### Firestore Rules:
- [ ] Atualizar `firestore.rules`
- [ ] Adicionar regras para `archived_tickets`
- [ ] Adicionar regras para `changelog`
- [ ] Deploy com `firebase deploy --only firestore:rules`

### Dart Services:
- [ ] Adicionar `getChamadosAtivosStream()` em `ChamadoService`
- [ ] Adicionar `getChamadosPorPrioridade()` em `ChamadoService`
- [ ] Adicionar `arquivarChamado()` em `ChamadoService`
- [ ] Adicionar `getChangelogStream()` em `ChamadoService`
- [ ] Atualizar delegações em `FirestoreService`

---

## 🧪 TESTES NECESSÁRIOS

### 1. Teste de Migração:
```powershell
# No Firebase Console -> Functions
# Chamar manualmente: migrarChamadosFechados
```

### 2. Teste de Arquivamento:
```dart
// Criar chamado de teste
// Fechar chamado
// Aguardar 30 dias (ou modificar function para 1 minuto)
// Verificar se foi arquivado automaticamente
```

### 3. Teste de Performance:
```dart
// Antes: Buscar todos os chamados
final stopwatch1 = Stopwatch()..start();
final todos = await getTodosChamadosStream().first;
print('Tempo (todos): ${stopwatch1.elapsedMilliseconds}ms'); // ~500ms

// Depois: Buscar apenas ativos
final stopwatch2 = Stopwatch()..start();
final ativos = await getChamadosAtivosStream().first;
print('Tempo (ativos): ${stopwatch2.elapsedMilliseconds}ms'); // ~50ms (10x mais rápido)
```

---

## 📊 ESTIMATIVA DE TEMPO

| Tarefa | Tempo Estimado |
|--------|----------------|
| Estrutura de Dados | 1 hora |
| Firebase Functions | 3 horas |
| Firestore Indexes | 30 minutos |
| Firestore Rules | 1 hora |
| Dart Services | 2 horas |
| **TOTAL** | **7.5 horas** |

---

**Próximo Passo:** Após concluir backend, iniciar [PLANO_FRONTEND.md](#)
