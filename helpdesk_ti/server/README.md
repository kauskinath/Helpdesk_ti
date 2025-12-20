# Servidor de Atualização - Pichau TI

Este diretório contém os arquivos necessários para hospedar o sistema de atualização do app.

## 📁 Estrutura de Arquivos

```
server/
├── server.py           # Servidor HTTP em Python
├── version.json        # Informações da versão atual
├── app-release.apk     # APK do aplicativo (você deve copiar aqui)
└── README.md          # Este arquivo
```

## 🚀 Como Usar

### 1. Preparar o Servidor

1. **Copie o APK para esta pasta:**
   ```bash
   # Após compilar com flutter build apk --release
   copy ..\build\app\outputs\flutter-apk\app-release.apk .
   ```

2. **Atualize o version.json** com os dados da nova versão

### 2. Iniciar o Servidor

**No Windows (PowerShell):**
```powershell
cd server
python server.py
```

**No Windows (Prompt):**
```cmd
cd server
python server.py
```

### 3. Configurar o App

1. Anote o **IP da rede** mostrado pelo servidor (ex: `192.168.1.100`)
2. No código do app, atualize a URL base em `about_screen.dart`:
   ```dart
   static const String UPDATE_SERVER_URL = 'http://192.168.1.100:8080';
   ```

### 4. Testar

1. Abra o app no celular (conectado na mesma rede WiFi)
2. Vá em Menu → Sobre
3. Clique em "Verificar Atualização"
4. O app buscará a versão do servidor

## 🔧 Configurações

### version.json

```json
{
  "latestVersion": "1.0.1",           // Versão mais recente
  "latestBuildNumber": "2003",        // Build number
  "downloadUrl": "http://...",        // URL do APK
  "releaseNotes": "Novidades...",     // Notas de lançamento
  "forceUpdate": false,               // Forçar atualização?
  "minimumVersion": "1.0.0"           // Versão mínima suportada
}
```

### Atualizar para Nova Versão

1. Compile o novo APK:
   ```bash
   flutter build apk --release
   ```

2. Copie para a pasta `server/`:
   ```bash
   copy build\app\outputs\flutter-apk\app-release.apk server\
   ```

3. Atualize `version.json` com nova versão

4. Servidor detectará automaticamente as mudanças

## 🔒 Firewall

Se o app não conseguir conectar:

**Windows:**
1. Painel de Controle → Firewall do Windows
2. Configurações Avançadas → Regras de Entrada
3. Nova Regra → Porta → TCP → Porta 8080 → Permitir

## 📱 Testando na Rede Local

1. PC e celular na mesma WiFi
2. Servidor rodando: `python server.py`
3. Anote o IP mostrado (ex: 192.168.1.100)
4. No celular, abra navegador: `http://192.168.1.100:8080/version.json`
5. Deve mostrar o JSON com a versão

## 🌐 Acesso pela Internet (Opcional)

Para permitir acesso fora da rede local:

1. Configure **Port Forwarding** no roteador (porta 8080)
2. Use serviços como **ngrok** para túnel temporário:
   ```bash
   ngrok http 8080
   ```
3. Ou configure um **IP fixo** com DDNS

## ⚠️ Importante

- **Segurança**: Este servidor é para uso interno/testes
- **Produção**: Use HTTPS e autenticação adequada
- **Firewall**: Libere apenas para dispositivos confiáveis
- **Backup**: Mantenha cópias dos APKs antigos

## 🆘 Problemas Comuns

**"Servidor não inicia"**
- Porta 8080 já em uso → Mude para 8081 no código
- Python não instalado → Instale Python 3.7+

**"App não conecta ao servidor"**
- Celular e PC em redes WiFi diferentes
- Firewall bloqueando porta 8080
- IP errado no código do app

**"Download falha"**
- APK não está na pasta `server/`
- URL errada no `version.json`
- Permissões de arquivo incorretas
