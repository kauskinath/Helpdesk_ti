# 📱 Guia Completo: Notificações no Xiaomi Android 15

## ✅ Alterações Implementadas para Android 14/15

### 1. **AndroidManifest.xml**
Adicionadas permissões críticas:
- `FOREGROUND_SERVICE_DATA_SYNC` - Serviços em background (Android 14+)
- `SCHEDULE_EXACT_ALARM` - Alarmes precisos para notificações
- `USE_EXACT_ALARM` - Backup para alarmes exatos
- `WAKE_LOCK` - Manter dispositivo acordado (Xiaomi)
- `RECEIVE_BOOT_COMPLETED` - Reiniciar serviços após boot
- `VIBRATE` - Vibração nas notificações

### 2. **build.gradle.kts**
- **minSdk**: 24 (Android 7.0) - Suporte completo FCM
- **targetSdk**: 35 (Android 15) - Compatibilidade máxima
- **compileSdk**: Automático via Flutter

### 3. **Receivers Adicionados**
- `FlutterFirebaseMessagingReceiver` - Receber mensagens FCM
- `FlutterFirebaseMessagingBootReceiver` - Reiniciar após boot

### 4. **Foreground Service Type**
- Serviço FCM configurado com `foregroundServiceType="dataSync"`

---

## 🔧 Configurações Obrigatórias no Xiaomi/MIUI

### **Passo 1: Autostart (Iniciar Automaticamente)**
1. Abra **Configurações** → **Apps** → **Gerenciar apps**
2. Encontre **PICHAU TI**
3. Ative **Autostart (Iniciar automaticamente)**

**Por que?** MIUI mata apps em background por padrão. Autostart mantém o serviço FCM ativo.

---

### **Passo 2: Otimização de Bateria**
1. Vá em **Configurações** → **Apps** → **Gerenciar apps** → **PICHAU TI**
2. Clique em **Economizar bateria**
3. Selecione **Sem restrições**

**Por que?** Otimização de bateria impede que o app receba notificações push em background.

---

### **Passo 3: Permissões de Notificação**
1. **Configurações** → **Notificações e barra de status** → **Notificações do app**
2. Encontre **PICHAU TI**
3. Ative todas as permissões:
   - ✅ **Permitir notificações**
   - ✅ **Mostrar em tela de bloqueio**
   - ✅ **Som**
   - ✅ **Vibração**
   - ✅ **Banner flutuante** (Notificações flutuantes)
   - ✅ **Ponto de notificação no ícone do app**

---

### **Passo 4: Exibir sobre outros apps (Popup)**
1. **Configurações** → **Apps** → **Gerenciar apps** → **PICHAU TI**
2. **Permissões adicionais** → **Exibir janelas pop-up**
3. Ative **Permitir exibir janelas pop-up**

**Por que?** Permite notificações flutuantes quando o app está fechado.

---

### **Passo 5: Proteção de Apps em Background**
1. **Configurações** → **Apps** → **Gerenciar apps**
2. No menu (3 pontos) → **Proteger apps em background**
3. Adicione **PICHAU TI** à lista

**Por que?** MIUI tem uma "lista negra" que mata apps mesmo com autostart. Proteção garante que o app não seja finalizado.

---

### **Passo 6: Limpar Cache de Notificações (Se não funcionar)**
1. **Configurações** → **Apps** → **Gerenciar apps** → **Mostrar todos os apps**
2. No menu (3 pontos) → **Mostrar apps do sistema**
3. Encontre **Serviços do Google Play**
4. **Armazenamento** → **Limpar cache** (NÃO limpar dados!)
5. Reinicie o celular

---

## 🔬 Como Testar Notificações Push

### **Teste 1: Com App Aberto** ✅
1. Faça login como usuário no dispositivo real
2. **NÃO feche o app** (mantenha aberto)
3. Em outro dispositivo (ou web), crie um novo chamado como admin
4. **Resultado esperado**: Notificação aparece instantaneamente na barra de status

---

### **Teste 2: Com App em Background** ✅
1. Faça login como usuário no dispositivo real
2. Pressione **Home** (app vai para background, não feche completamente)
3. Em outro dispositivo, crie um novo chamado como admin
4. **Resultado esperado**: Notificação chega em 5-15 segundos

---

### **Teste 3: Com App Fechado** 🎯 (CRÍTICO)
1. Faça login como usuário no dispositivo real
2. Feche o app **completamente** (deslize para cima no seletor de apps)
3. Aguarde 1 minuto (para FCM estabilizar conexão)
4. Em outro dispositivo, crie um novo chamado como admin
5. **Resultado esperado**: Notificação chega em até 30 segundos

**⚠️ Se NÃO chegar:**
- Verifique se **Autostart** está ativo
- Verifique se **Otimização de bateria** está DESATIVADA
- Verifique se **Proteger apps em background** está ativo
- Limpe o cache do Serviços do Google Play e reinicie

---

## 📊 Logs de Diagnóstico

### **Ver Logs do App (Conectado ao PC)**
```bash
# No terminal do VS Code
adb -s HRBDFUN logcat | Select-String "flutter"
```

Procure por:
```
✅ Novo token FCM gerado: exvxDxoPQFihYHKJYaQL...
✅ Token FCM salvo com sucesso no Firestore!
🔔 BACKGROUND: Notificação recebida enquanto app estava fechado
```

---

### **Verificar Token no Firestore**
1. Abra **Firebase Console** → **Firestore Database**
2. Navegue até `users` → `[seu_userId]`
3. Verifique campos:
   - `fcmToken`: Token gerado (deve ter ~150 caracteres)
   - `fcmTokenUpdatedAt`: Timestamp recente (< 5 minutos)

---

### **Testar Envio Manual do Firebase**
1. Abra **Firebase Console** → **Cloud Messaging**
2. Clique em **Send your first message**
3. Configure:
   - **Notification title**: Teste Manual
   - **Notification text**: Testando notificação push
   - **Target**: Single device
   - **FCM registration token**: Cole o token do Firestore
4. Clique em **Send message**
5. **Resultado**: Notificação deve chegar em 10-20 segundos

---

## 🚨 Problemas Comuns e Soluções

### ❌ **"Notificação não chega com app fechado"**
**Causa**: MIUI matou o serviço FCM em background

**Solução**:
1. Ative **Autostart**
2. Desative **Otimização de bateria**
3. Ative **Proteger apps em background**
4. Reinicie o celular
5. Teste novamente após 2 minutos

---

### ❌ **"Token FCM muda constantemente"**
**Causa**: App está sendo reinstalado ou cache FCM corrompido

**Solução**:
1. Limpe cache do **Serviços do Google Play**
2. Limpe cache do **PICHAU TI**
3. Desinstale o app
4. Reinicie o celular
5. Reinstale o app
6. Faça login uma vez e aguarde 2 minutos

---

### ❌ **"Erro: registration-token-not-registered"**
**Causa**: Token FCM expirou ou inválido

**Solução**: Já corrigido! O app agora:
1. Deleta o token antigo automaticamente no login
2. Gera um novo token fresco
3. Salva no Firestore com timestamp

---

### ❌ **"GoogleApiManager: Failed to get service from broker"**
**Causa**: Emulador sem Google Play Services completo

**Solução**: Use apenas dispositivos físicos reais para testar notificações push.

---

## 📦 Build e Deploy

### **Compilar APK Release**
```powershell
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti
flutter clean
flutter pub get
flutter build apk --release
```

**APK gerado em**: `build\app\outputs\flutter-apk\app-release.apk`

---

### **Instalar no Xiaomi**
```powershell
# Via cabo USB
adb -s HRBDFUN install -r build\app\outputs\flutter-apk\app-release.apk

# Ou transferir via cabo/WhatsApp e instalar manualmente
```

---

## 🎯 Checklist Final

Antes de reportar problema, verifique:

- [ ] **targetSdk 35** está no `build.gradle.kts`
- [ ] **Autostart ativado** no MIUI
- [ ] **Otimização de bateria DESATIVADA**
- [ ] **Proteger apps em background ATIVADO**
- [ ] **Todas permissões de notificação ATIVAS**
- [ ] **Token FCM salvo no Firestore** (< 5 min)
- [ ] **Cloud Functions ATIVAS** (`firebase functions:list`)
- [ ] **Testando em dispositivo REAL** (não emulador)
- [ ] **Aguardou 2 minutos** após abrir app pela primeira vez

---

## 📞 Suporte

Se após todas as configurações acima as notificações ainda não chegarem:

1. Exporte logs do logcat: `adb logcat > logs.txt`
2. Tire screenshot das configurações do app no MIUI
3. Verifique logs do Cloud Functions: `firebase functions:log`
4. Verifique token no Firestore Database

---

**Última atualização**: 28 de novembro de 2025
**Versão Android testada**: Android 15 (MIUI 14)
**Dispositivo testado**: Xiaomi (HRBDFUN)
