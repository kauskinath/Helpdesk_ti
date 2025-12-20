# 🔥 ÍNDICES FIRESTORE NECESSÁRIOS

## ⚠️ PROBLEMA ATUAL
O app está falhando ao carregar chamados e templates porque faltam índices compostos no Firestore.

## 📋 ÍNDICES QUE PRECISAM SER CRIADOS

### 1. Índice para `tickets` collection
**Query:** Buscar chamados de um usuário ordenados por data de criação (decrescente)

**Campos do índice:**
- Collection ID: `tickets`
- Fields:
  1. `usuarioId` (Ascending)
  2. `dataCriacao` (Descending)
  3. `__name__` (Descending)

**Link direto para criar:**
```
https://console.firebase.google.com/v1/r/project/helpdesk-ti-4bbf2/firestore/indexes?create_composite=ClFwcm9qZWN0cy9oZWxwZGVzay10aS00YmJmMi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvdGlja2V0cy9pbmRleGVzL18QARoNCgl1c3VhcmlvSWQQARoPCgtkYXRhQ3JpYWNhbxACGgwKCF9fbmFtZV9fEAI
```

---

### 2. Índice para `templates` collection
**Query:** Buscar templates ativos ordenados por título

**Campos do índice:**
- Collection ID: `templates`
- Fields:
  1. `ativo` (Ascending)
  2. `titulo` (Ascending)
  3. `__name__` (Ascending)

**Link direto para criar:**
```
https://console.firebase.google.com/v1/r/project/helpdesk-ti-4bbf2/firestore/indexes?create_composite=ClNwcm9qZWN0cy9oZWxwZGVzay10aS00YmJmMi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvdGVtcGxhdGVzL2luZGV4ZXMvXxABGgkKBWF0aXZvEAEaCgoGdGl0dWxvEAEaDAoIX19uYW1lX18QAQ
```

---

## 🚀 COMO CRIAR OS ÍNDICES

### Opção 1: Usar os links diretos (MAIS RÁPIDO)
1. Clique no link acima
2. Aguarde 2-5 minutos para o índice ser construído
3. Recarregue o app

### Opção 2: Criar manualmente no Console Firebase
1. Acesse: https://console.firebase.google.com/project/helpdesk-ti-4bbf2/firestore/indexes
2. Clique em "Create Index"
3. Configure conforme descrito acima

### Opção 3: Copiar do erro no console
O próprio Firebase gera o link no erro. Copie e abra no navegador.

---

## ✅ VERIFICAÇÃO
Após criar os índices, você verá no console:
```
✅ Index created successfully
Status: Building... → Enabled
```

Tempo de construção: **2-5 minutos** (dependendo do tamanho da collection)

---

## 🔍 POR QUE ISSO ACONTECE?
Firestore exige índices compostos quando você:
- Filtra por um campo (`where`)
- Ordena por outro campo (`orderBy`)

No nosso caso:
- `tickets`: Filtra por `usuarioId` + ordena por `dataCriacao`
- `templates`: Filtra por `ativo` + ordena por `titulo`

---

## 📝 NOTA IMPORTANTE
Estes índices são **necessários** para o app funcionar corretamente. Sem eles:
- ❌ Usuários não conseguem ver seus chamados
- ❌ Tela de criar chamado não carrega templates
- ❌ App fica em loading infinito
