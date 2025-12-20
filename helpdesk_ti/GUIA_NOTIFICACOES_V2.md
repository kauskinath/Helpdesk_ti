# 🔔 Guia de Notificações Push v2.0

## 📋 Visão Geral

Sistema completo de notificações push com Firebase Cloud Messaging (FCM), incluindo navegação automática, feedback visual, prevenção de duplicação e gerenciamento inteligente de tokens.

---

## ✨ Melhorias Implementadas

### 1. **Navegação Automática** ✅
- Quando usuário clica em notificação, navega automaticamente para a tela correta
- Tipos de navegação:
  - `novo_chamado` → Fila Técnica
  - `chamado_atualizado` → Detalhes do Chamado
  - `solicitacao_pendente` → Aprovar Solicitações
  - `solicitacao_aprovada/reprovada` → Histórico de Solicitações

### 2. **Feedback Visual em Foreground** ✅
- Quando app está aberto, mostra overlay animado (SnackBar)
- Cores personalizadas por tipo:
  - 🟠 Laranja: Novo chamado
  - 🔵 Azul: Chamado atualizado
  - 🟣 Roxo: Solicitação pendente
  - 🟢 Verde: Solicitação aprovada
- Botão "VER" para navegação imediata
- Duração: 4 segundos

### 3. **Auto-Atualização de Token** ✅
- Token FCM é automaticamente atualizado no Firestore quando muda
- Campo `fcmTokenUpdatedAt` registra timestamp da atualização
- Garante que usuário sempre receba notificações

### 4. **Background Handler Inteligente** ✅
- Quando app está fechado/morto:
  - Salva notificação no Firestore
  - Marca `receivedInBackground: true`
  - Notificação é exibida quando app abrir
- Evita perda de notificações

### 5. **Prevenção de Duplicação** ✅
- Usa `Set<String>` para rastrear IDs já processados
- Limpa automaticamente ao iniciar listener
- Previne notificações duplicadas (Firestore + FCM)

### 6. **Limite de Notificações Antigas** ✅
- Ao abrir app, carrega apenas 10 notificações mais recentes
- Ordenação por timestamp (mais recentes primeiro)
- Evita sobrecarga de notificações antigas

---

## 📦 Arquitetura

### **NavigationService** (novo)
```dart
// Navegação global sem BuildContext
NavigationService.navigateToChamadoDetails('chamado123');
NavigationService.navigateToFilaTecnica();
NavigationService.showSnackBar('Mensagem global');
```

**Registro no MaterialApp:**
```dart
MaterialApp(
  navigatorKey: NavigationService.navigatorKey, // ← OBRIGATÓRIO
  ...
)
```

### **NotificationService** (melhorado)
- `initialize()` - Inicializa FCM e listeners
- `saveUserToken()` - Salva token com userId
- `_handleForegroundMessage()` - Feedback visual
- `_handleMessageNavigation()` - Navegação por tipo
- `_updateUserToken()` - Auto-atualização
- `startNotificationListener()` - Listener com prevenção de duplicação
- `_firebaseMessagingBackgroundHandler()` - Handler em background

---

## 🎯 Como Enviar Notificações

### **Estrutura de Dados Obrigatória**

```dart
await FirebaseFirestore.instance.collection('notifications').add({
  'userId': 'user123',              // ← OBRIGATÓRIO
  'title': 'Novo chamado #1234',
  'body': 'Seu chamado foi criado',
  'data': {
    'tipo': 'novo_chamado',         // ← Define navegação e cor
    'chamadoId': '1234',            // ← Para chamado_atualizado
  },
  'read': false,
  'timestamp': FieldValue.serverTimestamp(),
});
```

### **Tipos de Notificação**

| Tipo                   | Cor     | Ícone         | Navegação                    |
|------------------------|---------|---------------|------------------------------|
| `novo_chamado`         | Laranja | add_alert     | Fila Técnica                 |
| `chamado_atualizado`   | Azul    | update        | Detalhes do Chamado (precisa `chamadoId`) |
| `solicitacao_pendente` | Roxo    | approval      | Aprovar Solicitações         |
| `solicitacao_aprovada` | Verde   | check_circle  | Histórico de Solicitações    |
| `solicitacao_reprovada`| Verde   | check_circle  | Histórico de Solicitações    |

---

## 🧪 Testes

### **Teste 1: App em Foreground**
1. Abrir app
2. Enviar notificação (via Firestore)
3. ✅ Verificar: Overlay aparece com cor correta
4. ✅ Clicar "VER": Navega para tela correta

### **Teste 2: App em Background**
1. Minimizar app (Home + Recentes)
2. Enviar notificação
3. ✅ Verificar: Notificação no sistema
4. ✅ Clicar notificação: App abre na tela correta

### **Teste 3: App Fechado/Morto**
1. Fechar app completamente (swipe Recentes)
2. Enviar notificação
3. ✅ Verificar: Notificação salva no Firestore
4. ✅ Abrir app: Notificação é exibida
5. ✅ Clicar "VER": Navega corretamente

### **Teste 4: Token Refresh**
1. Desinstalar e reinstalar app
2. Fazer login
3. ✅ Verificar: Novo token salvo no Firestore
4. ✅ Campo `fcmTokenUpdatedAt` atualizado
5. ✅ Notificações continuam funcionando

### **Teste 5: Duplicação**
1. Enviar mesma notificação múltiplas vezes
2. ✅ Verificar: Notificação aparece apenas UMA vez
3. ✅ Console mostra: "⏭️ Notificação já processada, pulando..."

### **Teste 6: Notificações Antigas**
1. Criar 20 notificações não lidas
2. Abrir app
3. ✅ Verificar: Apenas 10 mais recentes são exibidas
4. ✅ Sem sobrecarga de notificações

---

## 🐛 Troubleshooting

### **Notificação não navega**
**Causa:** NavigationService.navigatorKey não registrado
**Solução:**
```dart
// main.dart
MaterialApp(
  navigatorKey: NavigationService.navigatorKey, // ← Adicionar
  ...
)
```

### **Token não atualiza**
**Causa:** userId não está sendo salvo
**Solução:** Verificar `saveUserToken(userId)` é chamado no login

### **Notificações duplicadas**
**Causa:** Set de IDs não está funcionando
**Solução:** Verificar console para logs "⏭️ já processada"

### **Background handler não funciona**
**Causa:** Firebase não inicializado
**Solução:** Verificar `await Firebase.initializeApp()` no handler

### **Overlay não aparece**
**Causa:** NavigationService.currentContext é null
**Solução:** Verificar navigatorKey registrado no MaterialApp

---

## 📊 Logs e Debugging

### **Logs Importantes**

```
🎧 Listener de notificações INICIADO           ← Listener iniciado
📬 Encontradas X notificações não lidas        ← Notificações antigas
📩 Mostrando notificação: Título               ← Notificação exibida
⏭️ Notificação X já processada, pulando...    ← Duplicação prevenida
🔔 Nova notificação: Título                    ← Nova notificação
🧭 Navegando para Fila Técnica                 ← Navegação aconteceu
✅ Token FCM atualizado no Firestore           ← Token sincronizado
🌙 Notificação em background: Título           ← Background handler
```

### **Debug de Navegação**
```dart
// Ativar logs detalhados
NavigationService.navigateToChamadoDetails('123');
// Console mostrará estado do navigatorKey
```

---

## 📱 Requisitos do Sistema

### **Android**
- `android/app/build.gradle`: minSdkVersion 21+
- `android/app/src/main/AndroidManifest.xml`: Permissões de notificação
- Firebase configurado (`google-services.json`)

### **iOS**
- `ios/Runner/Info.plist`: Permissões de notificação
- Firebase configurado (`GoogleService-Info.plist`)
- Push Notification capability habilitada

---

## 🔒 Segurança

### **Firestore Rules**
```javascript
// Regra para notificações
match /notifications/{notificationId} {
  // Apenas o usuário pode ler suas notificações
  allow read: if request.auth != null && 
              resource.data.userId == request.auth.uid;
  
  // Apenas admin/manager pode criar notificações
  allow create: if request.auth != null && 
                get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
}

// Regra para tokens FCM
match /users/{userId} {
  allow update: if request.auth != null && 
                request.auth.uid == userId &&
                request.resource.data.diff(resource.data).affectedKeys().hasOnly(['fcmToken', 'fcmTokenUpdatedAt']);
}
```

---

## 💾 Estrutura do Firestore

### **Coleção: `notifications`**
```json
{
  "userId": "user123",
  "title": "Novo chamado #1234",
  "body": "Descrição da notificação",
  "data": {
    "tipo": "novo_chamado",
    "chamadoId": "1234"
  },
  "read": false,
  "timestamp": "2024-01-15T10:30:00Z",
  "receivedInBackground": false
}
```

### **Documento: `users/{userId}`**
```json
{
  "fcmToken": "token_longo_aqui",
  "fcmTokenUpdatedAt": "2024-01-15T10:30:00Z"
}
```

---

## 🚀 Performance

### **Otimizações**
- Apenas 10 notificações mais recentes carregadas
- Set de IDs limpo ao iniciar listener (evita memory leak)
- Notificações marcadas como lidas automaticamente
- Background handler leve (apenas salva no Firestore)

### **Limites Firebase (FREE)**
- 2M invocações/mês (Cloud Functions)
- Notificações ilimitadas (FCM gratuito)
- 1 GB read/month (Firestore)
- 10 GB transfer/month

---

## 📝 Changelog

### **v2.0** (Atual)
- ✅ NavigationService criado
- ✅ Navegação automática implementada
- ✅ Feedback visual em foreground
- ✅ Auto-atualização de token
- ✅ Background handler inteligente
- ✅ Prevenção de duplicação
- ✅ Limite de notificações antigas

### **v1.0** (Anterior)
- Notificações básicas via FCM
- Listener de Firestore simples
- Sem navegação automática
- Sem feedback visual

---

## 🤝 Contribuindo

### **Para adicionar novo tipo de notificação:**

1. **Atualizar `_handleMessageNavigation()`:**
```dart
case 'novo_tipo':
  NavigationService.navigateToNovaTela();
  break;
```

2. **Atualizar `_showForegroundOverlay()`:**
```dart
case 'novo_tipo':
  backgroundColor = Colors.red;
  icon = Icons.new_icon;
  break;
```

3. **Documentar na tabela de tipos (acima)**

---

## 📚 Referências

- [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Flutter](https://pub.dev/packages/firebase_messaging)

---

**Versão:** 2.0  
**Última atualização:** Janeiro 2024  
**Status:** ✅ Produção
