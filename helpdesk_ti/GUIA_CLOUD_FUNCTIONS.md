# 🚀 Guia Completo: Cloud Functions - Notificações em Background

## 📋 Índice
1. [O que são Cloud Functions](#o-que-são)
2. [Pré-requisitos](#pré-requisitos)
3. [Estrutura Atual](#estrutura-atual)
4. [Deploy das Functions](#deploy)
5. [Testando](#testando)
6. [Monitoramento](#monitoramento)
7. [Custos](#custos)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 O que são Cloud Functions

Cloud Functions são **funções serverless** que rodam automaticamente no servidor do Google quando algo acontece no seu Firebase:

- ✅ **Novo chamado criado** → Notifica todos os admins/TI
- ✅ **Status mudou** → Notifica o usuário que criou o chamado
- ✅ **Novo comentário** → Notifica participantes do chamado
- ✅ **Limpeza automática** → Remove tokens FCM inválidos a cada 24h

### Por que você precisa disso?

Quando o **app está fechado**, os listeners do Firestore morrem. As Cloud Functions garantem que:
- O servidor monitora mudanças no banco 24/7
- Envia notificações push mesmo com app fechado
- Funciona em qualquer dispositivo (Android/iOS)

---

## ✅ Pré-requisitos

### 1. Upgrade para Blaze Plan (Pague conforme o uso)

O plano Spark (gratuito) **NÃO PERMITE** Cloud Functions. Você precisa:

```bash
# Acesse o Firebase Console
https://console.firebase.google.com/project/helpdesk-ti-4bbf2/usage

# Clique em "Upgrade" → "Blaze (Pay as you go)"
```

⚠️ **NÃO SE PREOCUPE COM CUSTOS:**
- **Limites gratuitos mensais:**
  - 2 milhões de invocações
  - 400.000 GB-s de processamento
  - 200.000 GB-s de rede
  - 5GB de saída de internet

Para um helpdesk pequeno/médio (< 500 chamados/mês), você ficará **100% no plano gratuito**.

### 2. Configurar Billing Alert (Segurança)

```bash
# No Firebase Console → Configurações → Uso e faturamento
# Configure um alerta para R$ 10,00/mês

# Assim você recebe email se ultrapassar o limite grátis
```

### 3. Node.js Instalado

```powershell
# Verificar se já tem Node.js
node --version  # Deve retornar v18.x ou superior

# Se não tiver, baixe em: https://nodejs.org
```

---

## 📦 Estrutura Atual

Você já tem tudo implementado em `functions/`:

```
functions/
├── index.js          # 4 Cloud Functions implementadas
├── package.json      # Dependências
└── node_modules/     # (será criado no primeiro deploy)
```

### Functions Implementadas:

#### 1️⃣ `notificarNovoChamado`
- **Trigger**: Quando um documento é criado em `tickets/`
- **Ação**: Envia push para todos os admins/TI
- **Mensagem**: "🆕 Novo Chamado #0123 - João Silva: Impressora quebrou"

#### 2️⃣ `notificarAtualizacaoChamado`
- **Trigger**: Quando um documento é atualizado em `tickets/` E o status mudou
- **Ação**: Envia push para o criador do chamado
- **Mensagens**:
  - Status "Em Andamento" → "✅ Chamado #0123 Aceito"
  - Status "Fechado" → "✔️ Chamado #0123 Finalizado"
  - Status "Rejeitado" → "❌ Chamado #0123 Rejeitado"

#### 3️⃣ `notificarNovoComentario`
- **Trigger**: Quando um documento é criado em `comentarios/`
- **Ação**: Envia push para criador + admin (exceto autor do comentário)
- **Mensagem**: "💬 Novo Comentário - #0123 - Paulo: Já estou indo aí..."

#### 4️⃣ `limparTokensInvalidos`
- **Trigger**: Cron job (a cada 24 horas)
- **Ação**: Remove tokens FCM que não são mais válidos (app desinstalado)
- **Benefício**: Mantém banco limpo e economiza quota de notificações

---

## 🚀 Deploy das Functions

### Passo 1: Instalar Dependências

```powershell
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti\functions
npm install
```

Isso vai:
- Baixar `firebase-admin` e `firebase-functions`
- Criar pasta `node_modules/`
- Gerar arquivo `package-lock.json`

### Passo 2: Login no Firebase

```powershell
# Se ainda não fez login
firebase login

# Verificar projeto ativo
firebase projects:list
```

### Passo 3: Deploy

```powershell
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti
firebase deploy --only functions
```

**Saída esperada:**

```
✔ functions[notificarNovoChamado]: Successful create operation.
✔ functions[notificarAtualizacaoChamado]: Successful create operation.
✔ functions[notificarNovoComentario]: Successful create operation.
✔ functions[limparTokensInvalidos]: Successful create operation.

✔ Deploy complete!
```

⏱️ **Tempo**: 2-5 minutos no primeiro deploy

### Passo 4: Verificar no Console

```bash
# Abrir console do Firebase
https://console.firebase.google.com/project/helpdesk-ti-4bbf2/functions

# Você verá as 4 functions listadas
```

---

## 🧪 Testando

### Teste 1: Novo Chamado

1. **No app**, faça login como usuário comum
2. **Crie um novo chamado**
3. **Saia do app** (feche completamente)
4. **Espere 5-10 segundos**
5. ✅ **Você deve receber notificação push** no celular do admin

### Teste 2: Mudança de Status

1. **Saia do app** do usuário comum
2. **Entre como admin** em outro dispositivo
3. **Aceite o chamado** (mude status para "Em Andamento")
4. ✅ **Usuário comum recebe push** "Chamado Aceito"

### Teste 3: Novo Comentário

1. **Feche o app** em ambos os dispositivos
2. **Entre como admin** em um browser
3. **Adicione um comentário** no Firebase Console diretamente:

```javascript
// Firestore → comentarios → Add document
{
  "chamadoId": "LfbUCeAJZ7NWW6jt0IHD",
  "usuarioId": "Hq3iaGnIC8UNbw0rxBoyhjbXjji1",
  "usuarioNome": "Paulo Admin",
  "texto": "Teste de notificação",
  "dataHora": [timestamp atual]
}
```

4. ✅ **Criador do chamado recebe push**

### Ver Logs em Tempo Real

```powershell
firebase functions:log

# Ou no console:
https://console.firebase.google.com/project/helpdesk-ti-4bbf2/functions/logs
```

Você verá:
```
🎫 Novo chamado criado: #123
✅ Notificação enviada para token: eLQokEHDTN...
📤 Notificações enviadas para 2 dispositivos
```

---

## 📊 Monitoramento

### Dashboard do Firebase

```bash
https://console.firebase.google.com/project/helpdesk-ti-4bbf2/functions
```

Você verá:
- **Invocações**: Quantas vezes cada function rodou
- **Tempo de execução**: Média de latência
- **Erros**: Logs de falhas
- **Custo estimado**: Quanto você está usando (deve ser R$ 0,00)

### Alertas Importantes

Se ver nos logs:

❌ **"messaging/invalid-registration-token"**
- Token FCM inválido (usuário desinstalou app)
- A function `limparTokensInvalidos` resolve isso a cada 24h

❌ **"messaging/registration-token-not-registered"**
- Mesmo caso acima

❌ **"PERMISSION_DENIED"**
- Revise as Firestore Rules (já corrigidas anteriormente)

---

## 💰 Custos

### Calculadora (Cenário Real)

**Suponha:**
- 100 chamados/mês
- 50 mudanças de status/mês
- 200 comentários/mês
- 1 limpeza/dia = 30/mês

**Total de invocações:** ~380/mês

**Custo:**
- ✅ **R$ 0,00** (você tem 2 milhões grátis/mês)

### Quando você pagaria?

Só se tivesse **> 5.000 chamados/mês** (empresa grande)

Mesmo assim:
- Custo extra: ~R$ 0,40 por 100.000 invocações
- Para 10.000 chamados/mês: ~R$ 2,00/mês

**Conclusão:** Pode usar sem medo! 🎉

---

## 🔧 Troubleshooting

### Problema: Deploy falhou

**Erro:** "Billing account not configured"

**Solução:**
```bash
# Você precisa fazer upgrade para Blaze Plan
https://console.firebase.google.com/project/helpdesk-ti-4bbf2/usage
# Clique em "Upgrade"
```

---

### Problema: Notificação não chega

**Checklist:**

1. ✅ Function foi deployada?
```powershell
firebase functions:list
# Deve listar as 4 functions
```

2. ✅ Token FCM está salvo no Firestore?
```javascript
// Firestore → users → [seu_uid]
// Deve ter campo "fcmToken"
```

3. ✅ Ver logs em tempo real:
```powershell
firebase functions:log --only notificarNovoChamado
```

4. ✅ Teste manual de token:
```powershell
# No Firebase Console → Cloud Messaging
# Compose notification → Test on device → Cole o fcmToken
```

---

### Problema: "Error: Could not load default credentials"

**Solução:**
```powershell
# Re-fazer login
firebase logout
firebase login
```

---

### Problema: Function está lenta (> 10s)

**Causas comuns:**
1. Cold start (primeira execução após inatividade)
   - Normal: 2-5s no primeiro uso
   - Depois: < 1s

2. Muitos tokens para processar
   - Solução: Limitar a 100 tokens por batch

**Otimização:**
```javascript
// Enviar em lotes de 100 (já está implementado)
const sendPromises = tokens.slice(0, 100).map(token => {
  // ...
});
```

---

## 📚 Recursos Adicionais

### Documentação Oficial
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

### Comandos Úteis

```powershell
# Ver logs em tempo real
firebase functions:log --only notificarNovoChamado

# Deletar uma function
firebase functions:delete notificarNovoChamado

# Re-deploy apenas uma function
firebase deploy --only functions:notificarNovoChamado

# Testar localmente (emulador)
cd functions
npm run serve
```

### Melhorias Futuras (Opcional)

1. **Notificação de SLA vencendo:**
```javascript
exports.alertarSLAVencendo = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async () => {
    // Buscar chamados com SLA < 2h
    // Notificar admins
  });
```

2. **Resumo diário para admins:**
```javascript
exports.resumoDiario = functions.pubsub
  .schedule('every day 18:00')
  .timeZone('America/Sao_Paulo')
  .onRun(async () => {
    // Total de chamados abertos
    // Tempo médio de resposta
  });
```

3. **Notificação de avaliação pendente:**
```javascript
exports.lembrarAvaliacao = functions.pubsub
  .schedule('every day 10:00')
  .onRun(async () => {
    // Chamados fechados sem avaliação há > 3 dias
  });
```

---

## ✅ Checklist Final

Antes de considerar concluído:

- [ ] Upgrade para Blaze Plan feito
- [ ] Billing alert configurado (R$ 10/mês)
- [ ] `npm install` rodado em `functions/`
- [ ] `firebase deploy --only functions` executado com sucesso
- [ ] 4 functions listadas no Firebase Console
- [ ] Teste de novo chamado com app fechado funcionou
- [ ] Teste de mudança de status funcionou
- [ ] Logs verificados (sem erros)
- [ ] Monitoramento ativo no dashboard

---

## 🎉 Conclusão

Com as Cloud Functions deployadas, seu app agora tem notificações **REAIS** em background, funcionando 24/7, mesmo com o app fechado!

**Você resolveu:**
- ✅ Notificações quando app está fechado
- ✅ Custo zero (dentro dos limites gratuitos)
- ✅ Escalabilidade automática
- ✅ Manutenção zero (Google gerencia tudo)

**Próximos passos:**
1. Deploy das functions
2. Testar em produção
3. Monitorar logs por 1 semana
4. Ajustar mensagens se necessário

**Dúvidas?** Consulte este guia ou os logs do Firebase! 🚀
