# 🚀 GUIA DE DEPLOY - FIREBASE HOSTING

## Helpdesk TI - Versão Web

Este guia contém todas as instruções para publicar a versão web do Helpdesk TI no Firebase Hosting.

---

## 📋 PRÉ-REQUISITOS

Antes de começar, certifique-se de ter:

1. **Flutter SDK** instalado e configurado para web
2. **Node.js** instalado (versão 18 ou superior)
3. **Firebase CLI** instalado globalmente

### Verificar instalações:

```powershell
# Verificar Flutter
flutter --version

# Verificar Node.js
node --version

# Verificar Firebase CLI
firebase --version
```

### Instalar Firebase CLI (se necessário):

```powershell
npm install -g firebase-tools
```

---

## 🔐 PASSO 1: AUTENTICAÇÃO

### 1.1 Login no Firebase

```powershell
firebase login
```

Isso abrirá o navegador para autenticação com sua conta Google.

### 1.2 Verificar projeto vinculado

```powershell
firebase projects:list
```

O projeto `helpdesk-ti-4bbf2` deve aparecer na lista.

---

## 🏗️ PASSO 2: BUILD DA APLICAÇÃO WEB

### Opção A: Usando o script automatizado (Recomendado)

```powershell
cd "c:\Users\User\Desktop\PROJETOS\helpdesk_ti"
.\deploy-web.ps1
```

### Opção B: Comandos manuais

```powershell
# Navegar para o projeto
cd "c:\Users\User\Desktop\PROJETOS\helpdesk_ti"

# Limpar builds anteriores
flutter clean

# Obter dependências
flutter pub get

# Gerar build web em modo release
flutter build web --release --web-renderer html
```

> **Nota:** Usamos `--web-renderer html` para melhor compatibilidade com navegadores antigos.

---

## 🚀 PASSO 3: DEPLOY NO FIREBASE HOSTING

### 3.1 Deploy apenas do Hosting

```powershell
firebase deploy --only hosting
```

### 3.2 Deploy completo (Hosting + Functions + Firestore Rules)

```powershell
firebase deploy
```

---

## 🌐 PASSO 4: ACESSAR A APLICAÇÃO

Após o deploy bem-sucedido, sua aplicação estará disponível em:

- **URL Principal:** https://helpdesk-ti-4bbf2.web.app
- **URL Alternativa:** https://helpdesk-ti-4bbf2.firebaseapp.com

---

## 🔧 CONFIGURAÇÕES DO FIREBASE.JSON

O arquivo `firebase.json` foi configurado com:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [{ "key": "Cache-Control", "value": "max-age=31536000" }]
      },
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp|ico)",
        "headers": [{ "key": "Cache-Control", "value": "max-age=31536000" }]
      }
    ]
  }
}
```

### Explicação das configurações:

| Configuração | Descrição |
|--------------|-----------|
| `public: "build/web"` | Diretório com os arquivos compilados do Flutter |
| `rewrites` | Redireciona todas as rotas para index.html (SPA) |
| `headers` | Cache otimizado para assets estáticos (1 ano) |

---

## 🔥 COMANDOS ÚTEIS

### Visualizar preview antes do deploy

```powershell
firebase hosting:channel:deploy preview --expires 1h
```

### Ver histórico de deploys

```powershell
firebase hosting:sites:list
```

### Reverter para versão anterior

```powershell
firebase hosting:clone helpdesk-ti-4bbf2:live helpdesk-ti-4bbf2:rollback
```

### Testar localmente

```powershell
# Após o build
firebase serve --only hosting
```

---

## 🐛 SOLUÇÃO DE PROBLEMAS

### Erro: "Firebase not found"

```powershell
npm install -g firebase-tools
```

### Erro: "Not logged in"

```powershell
firebase login --reauth
```

### Erro: "Permission denied"

Verifique se você tem permissão de Editor ou Owner no projeto Firebase.

### Erro: "Build failed"

```powershell
flutter clean
flutter pub get
flutter build web --release
```

### Página em branco após deploy

1. Verifique o console do navegador (F12)
2. Certifique-se de que o Firebase está inicializado corretamente
3. Verifique se o `base href` no index.html está correto

---

## 📱 DOMÍNIO PERSONALIZADO (Opcional)

Para usar um domínio personalizado:

1. Acesse o [Console Firebase](https://console.firebase.google.com)
2. Vá em **Hosting** → **Add custom domain**
3. Siga as instruções para configurar DNS

---

## 📊 MONITORAMENTO

Após o deploy, monitore sua aplicação em:

- **Firebase Console:** https://console.firebase.google.com/project/helpdesk-ti-4bbf2
- **Analytics:** Seção Analytics no console
- **Logs:** Seção Functions → Logs

---

## ✅ CHECKLIST FINAL

- [ ] Flutter atualizado
- [ ] Firebase CLI instalado
- [ ] Logado no Firebase
- [ ] Build web gerado sem erros
- [ ] Deploy concluído com sucesso
- [ ] Aplicação acessível na URL
- [ ] Funcionalidades testadas

---

**Última atualização:** 02/01/2026
