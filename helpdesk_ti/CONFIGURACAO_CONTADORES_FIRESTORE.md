# Configuração dos Contadores no Firestore

## 📋 O que são os Contadores?

Os contadores são documentos no Firestore usados para gerar numeração sequencial automática para os chamados (TI e Manutenção).

## 🎯 Estrutura no Firestore

```
counters/
├── chamados          → Numeração para chamados TI
│   └── ultimoNumero: 0
└── manutencao        → Numeração para chamados Manutenção
    └── ultimoNumero: 0
```

## 🚀 Como Criar Manualmente no Console do Firebase

### Passo 1: Acessar o Firestore Console
1. Abra o [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. No menu lateral, clique em **Firestore Database**
4. Clique em **Iniciar coleção** (se for a primeira) ou navegue até a raiz

### Passo 2: Criar Collection `counters`
1. Clique em **Iniciar coleção** ou **+ Iniciar coleção**
2. Nome da coleção: `counters`
3. Clique em **Próximo**

### Passo 3: Criar Documento `chamados` (TI)
1. ID do documento: `chamados`
2. Adicionar campo:
   - **Campo**: `ultimoNumero`
   - **Tipo**: `number`
   - **Valor**: `0`
3. Clique em **Salvar**

### Passo 4: Criar Documento `manutencao`
1. Na coleção `counters`, clique em **Adicionar documento**
2. ID do documento: `manutencao`
3. Adicionar campo:
   - **Campo**: `ultimoNumero`
   - **Tipo**: `number`
   - **Valor**: `0`
4. Clique em **Salvar**

## ✅ Resultado Final no Firestore

```
📁 Firestore Database
  └── 📁 counters
      ├── 📄 chamados
      │   └── ultimoNumero: 0
      └── 📄 manutencao
          └── ultimoNumero: 0
```

## 🔐 Regras de Segurança

As regras já foram atualizadas no arquivo `firestore.rules`:

```javascript
match /counters/{counterId} {
  // Leitura: Apenas admins e admin_manutencao
  allow read: if isSignedIn() && (isAdmin() || isAdminManutencao());
  
  // Escrita: Sistema (através das funções) e admins
  allow write: if isSignedIn() && (isAdmin() || isAdminManutencao());
}
```

## 🎨 Como Funciona

### Chamados TI
1. Usuário cria chamado TI
2. Sistema busca `counters/chamados`
3. Incrementa `ultimoNumero` (ex: 0 → 1)
4. Salva chamado com `numero: 1`
5. Exibe como **#0001**

### Chamados Manutenção
1. Usuário cria chamado Manutenção
2. Sistema busca `counters/manutencao`
3. Incrementa `ultimoNumero` (ex: 0 → 1)
4. Salva chamado com `numero: 1`
5. Exibe como **#0001**

## 🔄 Deploy das Regras

Após criar os contadores, faça deploy das regras atualizadas:

```powershell
firebase deploy --only firestore:rules
```

## ⚠️ Importante

- **Nunca delete** os documentos de contadores!
- Se deletar, recomeça de 0
- Os contadores são separados (TI e Manutenção são independentes)
- A transação garante que não há duplicação de números

## 🧪 Teste

Para testar se está funcionando:

1. Crie um chamado de manutenção no app
2. Verifique no Firestore se o campo `numero` foi preenchido
3. Verifique se `counters/manutencao/ultimoNumero` incrementou
4. Na tela de detalhes, deve aparecer **#0001** no header

## 📊 Exemplo Visual

**Antes de criar o primeiro chamado:**
```
counters/manutencao
  ultimoNumero: 0
```

**Depois de criar o primeiro chamado:**
```
counters/manutencao
  ultimoNumero: 1

chamados/abc123
  numero: 1
  titulo: "Problema na impressora"
  ...
```

**Na tela do app:**
```
┌─────────────────────────┐
│ ← #0001                 │ ← Número formatado!
├─────────────────────────┤
│ Detalhes do chamado...  │
└─────────────────────────┘
```

## 🎯 Resumo

✅ **Regras atualizadas** no `firestore.rules`
✅ **Código implementado** no app (ManutencaoService.gerarProximoNumero())
⚠️ **FALTA CRIAR** os documentos manualmente no Firestore Console

Depois de criar os contadores, faça deploy das regras e teste!
