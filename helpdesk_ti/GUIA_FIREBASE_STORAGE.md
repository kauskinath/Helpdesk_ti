# 🔥 Como Ativar Firebase Storage e Corrigir Erro de Upload

## ❌ Erro Atual:
```
[firebase_storage/object-not-found] No object exists at the desired reference
```

## ✅ Solução em 3 Passos:

### 1️⃣ Ativar Firebase Storage no Console
1. Acesse: https://console.firebase.google.com/project/helpdesk-ti-4bbf2/storage
2. Clique em **"Get Started"** (Começar)
3. Escolha o modo de produção (com regras de segurança)
4. Selecione a localização: **us-central1** (recomendado)
5. Clique em **"Concluído"**

### 2️⃣ Fazer Deploy das Regras de Segurança
```powershell
cd c:\Users\User\Desktop\PROJETOS\helpdesk_ti
firebase deploy --only storage
```

**Arquivo de regras já criado:** `storage.rules`
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Permitir usuários autenticados
    match /manutencao/{chamadoId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    match /ti/{chamadoId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3️⃣ Verificar no Console
1. Acesse novamente: https://console.firebase.google.com/project/helpdesk-ti-4bbf2/storage
2. Vá em **"Rules"** (Regras)
3. Confirme que as regras foram aplicadas
4. Teste criar um chamado com anexo no app

## 📱 Após Ativar:
- ✅ Upload de orçamentos (PDF/DOCX) funcionará
- ✅ Upload de fotos comprovantes funcionará
- ✅ Anexos em chamados de Admin e Executor funcionarão

## 🎨 Melhorias do Menu Aplicadas:
- ✅ Menu agora mostra **apenas ícones grandes** (sem texto)
- ✅ Grid de 5 colunas para melhor visualização
- ✅ Ícone de logout moderno (Icons.logout em vez de porta 🚪)
- ✅ Ícones coloridos com bordas suaves
- ✅ Bottom sheet ao invés de dialog central

## 📦 APK Atualizado:
```
build\app\outputs\flutter-apk\app-release.apk (65.0MB)
```

Instale este novo APK após ativar o Firebase Storage para testar todas as funcionalidades!
