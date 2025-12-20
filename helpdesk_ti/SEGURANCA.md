# 🔐 SEGURANÇA E PROTEÇÃO DO CÓDIGO

## ⚠️ IMPORTANTE - LEIA PRIMEIRO

Este documento contém informações críticas sobre a segurança e proteção do aplicativo **PICHAU TI**.

---

## 📋 Proteções Implementadas

### 1. ✅ Assinatura Digital (Keystore)

**O que é:**
- Certificado digital único que identifica você como desenvolvedor
- Garante autenticidade do aplicativo
- Impede que outros publiquem atualizações falsas

**Arquivos:**
- `pichau-ti-release-key.jks` - **NUNCA compartilhe este arquivo!**
- `key.properties` - Contém senhas - **NUNCA commite no Git!**

**Localização Segura:**
- ✅ Keystore: `C:\KeystoresPichau\pichau-ti-release-key.jks`
- ✅ Senhas: Use cofre de senhas (LastPass, 1Password, etc.)
- ✅ Backup: 3+ locais diferentes (nuvem privada, HD externo, pen drive)

**Se perder:**
- ❌ **NÃO será possível** atualizar o app na Play Store
- ❌ Terá que criar novo package name
- ❌ Perderá todos os downloads e avaliações existentes

### 2. ✅ Informações de Copyright

**Implementado em:**
- `AndroidManifest.xml` - Metadados do app
- `pubspec.yaml` - Descrição do projeto
- `main.dart` - Cabeçalho de copyright no código
- `build.gradle.kts` - Configurações de build

**Conteúdo:**
```
© 2024-2025 Pichau Informática Ltda. Todos os direitos reservados.
Desenvolvido por: Departamento de TI - Pichau Informática
```

### 3. ✅ Ofuscação de Código (ProGuard)

**O que faz:**
- Renomeia classes, métodos e variáveis: `UserService` → `a1`
- Remove código não utilizado
- Reduz tamanho do APK em ~30-40%
- Dificulta engenharia reversa

**Arquivos:**
- `android/app/proguard-rules.pro` - Regras de ofuscação
- Configurado em `build.gradle.kts`

**Habilitado apenas em builds de release:**
```bash
flutter build apk --release
flutter build appbundle --release
```

### 4. ✅ Package Name Único

**Antigo:** `com.example.helpdesk_ti` ❌  
**Novo:** `com.pichau.helpdesk_ti` ✅

- Identifica unicamente seu aplicativo
- Impede conflitos com outros apps
- Registrado na Play Store

---

## 🚨 CHECKLIST DE SEGURANÇA

### Antes de Commitar no Git

- [ ] `key.properties` está no `.gitignore`
- [ ] Nenhum arquivo `.jks` ou `.keystore` será commitado
- [ ] Senhas não estão hardcoded no código
- [ ] `google-services.json` não contém informações sensíveis expostas

### Antes de Fazer Build de Release

- [ ] Keystore gerado e backup feito
- [ ] `key.properties` configurado com senhas corretas
- [ ] Package name correto: `com.pichau.helpdesk_ti`
- [ ] Versão atualizada no `pubspec.yaml`

### Antes de Publicar

- [ ] APK/AAB testado em dispositivos reais
- [ ] Assinatura digital verificada com `keytool`
- [ ] Ofuscação funcionando (código ilegível ao descompilar)
- [ ] Informações de copyright visíveis no APK

---

## 🛠️ Ferramentas e Scripts

### 1. Gerar Keystore
```powershell
.\gerar-keystore.ps1
```
- Cria keystore interativamente
- Gera `key.properties` automaticamente
- Valida informações

### 2. Build de Release
```powershell
# APK apenas
.\build-release.ps1 -BuildType apk

# AAB para Play Store
.\build-release.ps1 -BuildType appbundle

# Ambos
.\build-release.ps1 -BuildType both
```

### 3. Verificar Assinatura
```powershell
# Ver certificado do APK
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk

# Ver informações do keystore
keytool -list -v -keystore C:\KeystoresPichau\pichau-ti-release-key.jks -alias pichau-ti-key
```

---

## 🔒 Melhores Práticas

### Senhas

1. **Keystore Password:**
   - Mínimo 12 caracteres
   - Letras maiúsculas, minúsculas, números e símbolos
   - Exemplo: `Pi#Ch4u_T1!2024@Sec`

2. **Armazenamento:**
   - ✅ Use cofre de senhas
   - ✅ Anote em papel em cofre físico
   - ❌ Não salve em arquivos de texto
   - ❌ Não envie por email/WhatsApp

### Backup do Keystore

**3-2-1 Rule:**
- **3** cópias do keystore
- **2** tipos de mídia diferentes (nuvem + HD físico)
- **1** cópia off-site (fora do local principal)

**Sugestões:**
1. Google Drive (pasta privada, criptografada)
2. HD externo em local seguro
3. Pen drive em cofre físico

### Controle de Acesso

**Quem deve ter acesso:**
- ✅ Desenvolvedor principal
- ✅ Gerente de TI (backup)
- ❌ Outros desenvolvedores (usar debug key para desenvolvimento)

**Compartilhamento:**
- ❌ NUNCA por email
- ❌ NUNCA por WhatsApp/Telegram
- ❌ NUNCA em repositório Git
- ✅ Pessoalmente ou via cofre de senhas compartilhado

---

## 🎯 Verificação de Proteção

### 1. Código Ofuscado

Descompile o APK e verifique:
```powershell
# Extrair APK
7z x build\app\outputs\flutter-apk\app-release.apk -oextracted

# Visualizar classes.dex (será ilegível se ofuscado corretamente)
```

Você deve ver nomes como: `a`, `b`, `c1`, `d2` ao invés de `UserService`, `LoginScreen`, etc.

### 2. Copyright Visível

```powershell
# Extrair AndroidManifest.xml e verificar metadados
aapt dump badging build\app\outputs\flutter-apk\app-release.apk | Select-String "copyright"
```

### 3. Assinatura Válida

```powershell
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
```

Deve mostrar:
- Owner: Pichau Informática
- Valid from: (data de criação) until: (2052+)

---

## 📞 Suporte

Para questões de segurança, entre em contato:
- **Email:** ti@pichau.com.br (exemplo)
- **Responsável:** Gerente de TI

---

## 📄 Documentação Adicional

- `GUIA_ASSINATURA_DIGITAL.md` - Guia completo passo a passo
- `android/app/proguard-rules.pro` - Regras de ofuscação
- `android/key.properties.example` - Exemplo de configuração

---

**© 2024-2025 Pichau Informática Ltda**  
**Todos os direitos reservados**  
**Uso interno - Confidencial**
