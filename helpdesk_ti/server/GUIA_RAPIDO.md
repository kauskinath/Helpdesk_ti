# 🚀 GUIA RÁPIDO - Sistema de Atualização

## ✅ Checklist de Configuração

### 1️⃣ Preparar o Servidor (5 minutos)

```powershell
# 1. Compilar o APK
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti
flutter build apk --release

# 2. Copiar APK para pasta do servidor
copy build\app\outputs\flutter-apk\app-release.apk server\

# 3. Iniciar servidor
cd server
python server.py
```

### 2️⃣ Configurar o IP no App (1 minuto)

1. **Anote o IP** mostrado pelo servidor (ex: `192.168.1.50`)
2. **Abra** `lib/screens/about_screen.dart`
3. **Encontre** a linha 18:
   ```dart
   static const String UPDATE_SERVER_URL = 'http://192.168.1.100:8080';
   ```
4. **Substitua** `192.168.1.100` pelo seu IP
5. **Recompile** o app:
   ```powershell
   flutter build apk --release
   ```

### 3️⃣ Testar (2 minutos)

1. Instale o APK no celular
2. Conecte celular na **mesma rede WiFi** do PC
3. Abra o app → Menu (⋮) → Sobre
4. Clique em "Verificar Atualização"

---

## 📝 Quando Lançar Nova Versão

### Passo 1: Atualizar Versão no Código
```yaml
# pubspec.yaml - linha 19
version: 1.0.1+2003  # Incrementar versão e build
```

### Passo 2: Compilar Novo APK
```powershell
flutter build apk --release
copy build\app\outputs\flutter-apk\app-release.apk server\
```

### Passo 3: Atualizar version.json
```json
{
  "latestVersion": "1.0.1",
  "latestBuildNumber": "2003",
  "downloadUrl": "http://SEU_IP:8080/app-release.apk",
  "releaseNotes": "- Nova funcionalidade X\n- Correção de bug Y",
  "forceUpdate": false
}
```

### Passo 4: Servidor Já Atualizado! ✅
O servidor detecta automaticamente o novo `version.json`.

---

## 🔧 Resolver Problemas

### ❌ "Erro de Conexão"
```powershell
# Windows: Abrir porta no Firewall
netsh advfirewall firewall add rule name="Pichau TI Server" dir=in action=allow protocol=TCP localport=8080

# Verificar se servidor está rodando
netstat -ano | findstr :8080
```

### ❌ "Celular não conecta"
- ✅ PC e celular na **mesma rede WiFi**?
- ✅ Servidor está **rodando**?
- ✅ IP no código está **correto**?
- ✅ Firewall está **permitindo** porta 8080?

### ❌ "Download falha"
- ✅ APK está na pasta `server/`?
- ✅ URL no `version.json` está correta?

---

## 📱 URLs Importantes

- **Versão JSON**: `http://SEU_IP:8080/version.json`
- **Download APK**: `http://SEU_IP:8080/app-release.apk`
- **Testar no navegador**: Abra essas URLs no celular

---

## 🎯 Exemplo Completo

```powershell
# Terminal 1: Iniciar servidor
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti\server
python server.py
# Anote o IP mostrado: 192.168.1.50

# Terminal 2: Compilar app com IP correto
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti
# (Já atualizou o IP no about_screen.dart)
flutter build apk --release

# Copiar APK
copy build\app\outputs\flutter-apk\app-release.apk server\

# Instalar no celular e testar!
```

---

## 💡 Dicas

1. **Mantenha o servidor rodando** enquanto testa
2. **Firewall**: Adicione exceção permanente
3. **IP Fixo**: Configure no roteador para não mudar
4. **Backup**: Guarde versões antigas dos APKs

---

## 🆘 Suporte Rápido

**Servidor não inicia?**
- `python --version` → Instale Python 3.7+

**IP muda toda hora?**
- Configure IP estático no roteador

**Quer acesso externo?**
- Use ngrok: `ngrok http 8080`
