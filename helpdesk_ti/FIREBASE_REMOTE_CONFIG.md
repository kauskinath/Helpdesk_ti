# 🔥 Firebase Remote Config - Guia de Configuração

## ⚡ Configuração Rápida (5 minutos)

### 1️⃣ Acessar Firebase Console

1. Abra: https://console.firebase.google.com
2. Selecione seu projeto: **helpdesk_ti**
3. Menu lateral → **Remote Config**

### 2️⃣ Criar Parâmetros

Clique em **"Adicionar parâmetro"** e crie estes 5 parâmetros:

#### Parâmetro 1: `latest_version`
- **Tipo**: String
- **Valor padrão**: `1.0.0`
- **Descrição**: Versão mais recente do app

#### Parâmetro 2: `latest_build_number`
- **Tipo**: String  
- **Valor padrão**: `2002`
- **Descrição**: Build number da versão mais recente

#### Parâmetro 3: `download_url`
- **Tipo**: String
- **Valor padrão**: `https://drive.google.com/uc?export=download&id=SEU_ID_AQUI`
- **Descrição**: Link direto para download do APK

#### Parâmetro 4: `release_notes`
- **Tipo**: String
- **Valor padrão**: Descrição das novidades
```
- Salvamento de credenciais de login
- Tela Sobre com informações do app
- Verificação de atualização via Firebase
- Melhorias de performance
```
- **Descrição**: Notas da versão (novidades)

#### Parâmetro 5: `force_update`
- **Tipo**: Boolean
- **Valor padrão**: `false`
- **Descrição**: Se true, força o usuário a atualizar

### 3️⃣ Publicar Alterações

1. Clique em **"Publicar alterações"** no topo
2. Confirme a publicação
3. ✅ Pronto! Os valores estão ativos

---

## 📤 Hospedar APK no Google Drive

### Passo 1: Upload do APK
1. Acesse: https://drive.google.com
2. Clique em **"Novo"** → **"Upload de arquivos"**
3. Selecione: `build/app/outputs/flutter-apk/app-release.apk`

### Passo 2: Compartilhar
1. Clique com botão direito no arquivo → **"Compartilhar"**
2. Em "Acesso geral" → **"Qualquer pessoa com o link"**
3. Permissão: **"Leitor"**
4. Copie o link (ex: `https://drive.google.com/file/d/1AbCdEfGhIjKlMnOpQrStUvWxYz/view`)

### Passo 3: Converter para Link Direto
Pegue o **ID** do link (parte entre `/d/` e `/view`):
```
https://drive.google.com/file/d/1AbCdEfGhIjKlMnOpQrStUvWxYz/view
                              ↑ Este é o ID ↑
```

Converta para link direto:
```
https://drive.google.com/uc?export=download&id=1AbCdEfGhIjKlMnOpQrStUvWxYz
```

### Passo 4: Atualizar Firebase
1. Volte ao **Remote Config**
2. Edite o parâmetro `download_url`
3. Cole o link direto
4. Clique em **"Publicar alterações"**

---

## 🆕 Lançar Nova Versão

### 1. Atualizar Código
```yaml
# pubspec.yaml - linha 19
version: 1.0.1+2003  # Incrementar versão e build
```

### 2. Compilar APK
```powershell
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti
flutter build apk --release
```

### 3. Upload para Google Drive
- Faça upload do novo APK
- Obtenha o link direto (mesmo processo acima)

### 4. Atualizar Firebase Remote Config
No console Firebase → Remote Config:

| Parâmetro | Novo Valor |
|-----------|------------|
| `latest_version` | `1.0.1` |
| `latest_build_number` | `2003` |
| `download_url` | Link direto do novo APK |
| `release_notes` | Descreva as novidades |
| `force_update` | `false` (ou `true` se obrigatória) |

Clique em **"Publicar alterações"** → ✅ Pronto!

---

## 🧪 Testar

### No Emulador/Celular:
1. Abra o app
2. Menu (⋮) → **Sobre**
3. Clique em **"Verificar Atualização"**
4. Se há nova versão → Aparece diálogo com botão "Baixar Agora"
5. Clica no botão → Abre navegador → Download do APK

---

## 🎯 Vantagens desta Solução

✅ **Sem servidor**: Tudo no Firebase  
✅ **Atualização instantânea**: Mude valores sem rebuild  
✅ **Grátis**: Firebase Remote Config é gratuito  
✅ **Seguro**: Hospedagem confiável (Google Drive)  
✅ **Fácil**: Interface visual no console  
✅ **Rápido**: Cache inteligente do Firebase  

---

## 📋 Exemplo de Configuração Completa

```json
{
  "latest_version": "1.0.2",
  "latest_build_number": "2004",
  "download_url": "https://drive.google.com/uc?export=download&id=1a2b3c4d5e6f7g8h9i0j",
  "release_notes": "🎉 Versão 1.0.2\n\n✨ Novidades:\n- Correção de bugs\n- Melhor performance\n- Nova interface",
  "force_update": false
}
```

---

## ⚠️ Importante

### Atualização Forçada (`force_update: true`)
- Usuário **não pode fechar** o diálogo
- **Deve** atualizar para continuar usando
- Use apenas para bugs críticos ou mudanças obrigatórias

### Cache do Remote Config
- Por padrão, busca nova config a cada **12 horas**
- Configuramos para **1 minuto** (modo desenvolvimento)
- Para produção, aumente para **12 horas**

### Google Drive vs Outras Opções
- **Google Drive**: Simples, grátis, 15GB
- **Firebase Storage**: Integração nativa, pago após 1GB
- **GitHub Releases**: Gratuito, ideal para open source
- **Dropbox**: Similar ao Drive

---

## 🆘 Problemas Comuns

### ❌ "Erro ao verificar atualização"
- Verifique internet
- Confirme que publicou as alterações no Firebase
- Aguarde 1 minuto após publicar

### ❌ "Download não inicia"
- Link do Google Drive está correto?
- Permissão de compartilhamento está "Qualquer pessoa com o link"?
- Usou o formato `uc?export=download&id=...`?

### ❌ "Sempre diz que está atualizado"
- Versão no Remote Config é maior que no app?
- Publicou as alterações no Firebase?

---

## 💡 Dicas Profissionais

1. **Changelog Organizado**: Use emojis e quebras de linha no `release_notes`
2. **Versionamento Semântico**: `MAJOR.MINOR.PATCH` (ex: 1.0.0 → 1.0.1)
3. **Backup dos APKs**: Mantenha todas as versões no Drive
4. **Teste Antes**: Sempre teste em um dispositivo antes de publicar
5. **Comunique Usuários**: Avise sobre atualizações importantes

---

## 📚 Recursos Adicionais

- **Firebase Remote Config Docs**: https://firebase.google.com/docs/remote-config
- **Google Drive API**: Para automação futura
- **Versionamento**: https://semver.org/

---

**Pronto para usar! 🚀**

Qualquer dúvida, consulte este guia ou a documentação oficial do Firebase.
