# 🔐 Guia de Assinatura Digital e Proteção do App

## 📋 Sumário
1. [Gerar Keystore (Assinatura Digital)](#1-gerar-keystore)
2. [Configurar Build para Release](#2-configurar-build)
3. [Informações de Copyright](#3-copyright)
4. [Ofuscação de Código](#4-ofuscação)
5. [Build Final](#5-build-final)

---

## 1. 🔑 Gerar Keystore (Assinatura Digital)

### O que é Keystore?
É um arquivo que contém sua chave privada para assinar o aplicativo. **NUNCA compartilhe este arquivo!**

### Passo 1: Gerar o Keystore

Execute no PowerShell (na pasta do projeto):

```powershell
cd android

# Gerar keystore (substitua as informações pelos seus dados)
keytool -genkey -v -keystore pichau-ti-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pichau-ti-key
```

**Informações que serão solicitadas:**
```
Enter keystore password: [crie uma senha forte - ANOTE!]
Re-enter new password: [repita a senha]
What is your first and last name?: Pichau Informática
What is the name of your organizational unit?: Departamento de TI
What is the name of your organization?: Pichau Informática Ltda
What is the name of your City or Locality?: [Sua Cidade]
What is the name of your State or Province?: [Seu Estado]
What is the two-letter country code for this unit?: BR
Is CN=Pichau Informática, OU=Departamento de TI, O=Pichau Informática Ltda, L=[Cidade], ST=[Estado], C=BR correct?: yes

Enter key password for <pichau-ti-key>: [pode ser a mesma senha ou outra - ANOTE!]
```

### Passo 2: Mover o Keystore para local seguro

```powershell
# Criar pasta segura (se não existir)
New-Item -ItemType Directory -Force -Path "C:\KeystoresPichau"

# Mover keystore
Move-Item "pichau-ti-release-key.jks" "C:\KeystoresPichau\pichau-ti-release-key.jks"

# IMPORTANTE: Fazer backup deste arquivo em local seguro!
# Sugestões: pen drive, nuvem privada, cofre de senhas
```

### Passo 3: Criar arquivo de propriedades

Crie o arquivo `android/key.properties` com suas credenciais:

```properties
storePassword=SUA_SENHA_DO_KEYSTORE
keyPassword=SUA_SENHA_DA_KEY
keyAlias=pichau-ti-key
storeFile=C:/KeystoresPichau/pichau-ti-release-key.jks
```

**⚠️ IMPORTANTE:** Adicione `key.properties` ao `.gitignore` para não subir para o GitHub!

---

## 2. ⚙️ Configurar Build para Release

As configurações já foram aplicadas automaticamente em:
- `android/app/build.gradle.kts`
- `android/app/proguard-rules.pro`

O build agora:
- ✅ Usa sua assinatura digital
- ✅ Minimiza o código (reduz tamanho)
- ✅ Ofusca o código (dificulta cópia)
- ✅ Inclui informações de copyright

---

## 3. 📝 Informações de Copyright

### Já configurado no AndroidManifest.xml:
```xml
<application
    android:label="PICHAU TI"
    android:description="Sistema Interno de Suporte Técnico - Pichau Informática"
    ...>
    
    <meta-data
        android:name="app.copyright"
        android:value="© 2024-2025 Pichau Informática Ltda. Todos os direitos reservados." />
    <meta-data
        android:name="app.developer"
        android:value="Pichau Informática - Departamento de TI" />
    <meta-data
        android:name="app.version"
        android:value="1.0.0" />
</application>
```

### Já configurado no pubspec.yaml:
```yaml
name: helpdesk_ti
description: "© 2024-2025 Pichau Informática Ltda - Sistema Interno de Suporte Técnico"
version: 1.0.0+2002
```

---

## 4. 🔒 Ofuscação de Código

### O que faz?
- **Renomeia** classes, métodos e variáveis para nomes sem sentido (a1, b2, c3...)
- **Remove** código não utilizado
- **Otimiza** o bytecode
- **Dificulta** engenharia reversa

### Já configurado:
- ✅ ProGuard habilitado no build release
- ✅ Regras específicas para Firebase, Flutter, etc.
- ✅ Mantém classes necessárias intactas

---

## 5. 🚀 Build Final

### Gerar APK assinado:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

O APK estará em: `build/app/outputs/flutter-apk/app-release.apk`

### Gerar AAB para Google Play Store:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

O AAB estará em: `build/app/outputs/bundle/release/app-release.aab`

---

## 🛡️ Proteções Implementadas

### 1. Assinatura Digital
- ✅ Keystore único e privado
- ✅ Validade de 27 anos (10.000 dias)
- ✅ Algoritmo RSA 2048 bits (seguro)
- ✅ Identifica você como desenvolvedor

### 2. Informações de Copyright
- ✅ Nome da empresa nos metadados
- ✅ Copyright no manifest
- ✅ Informações do desenvolvedor
- ✅ Versão rastreável

### 3. Ofuscação de Código
- ✅ Código ofuscado (difícil de ler)
- ✅ Remoção de código morto
- ✅ Otimização de tamanho
- ✅ Proteção contra cópia

### 4. Package Name Único
- ✅ `com.pichau.helpdesk_ti` (único e identificável)

---

## 🔐 Segurança do Keystore

### ⚠️ NUNCA:
- ❌ Compartilhe o arquivo `.jks`
- ❌ Suba o `key.properties` para o GitHub
- ❌ Compartilhe as senhas
- ❌ Perca o backup do keystore

### ✅ SEMPRE:
- ✅ Mantenha backup em 3+ locais diferentes
- ✅ Use senhas fortes (12+ caracteres)
- ✅ Documente as senhas em cofre seguro
- ✅ Restrinja acesso ao arquivo

### Se perder o Keystore:
- ⚠️ **NÃO SERÁ POSSÍVEL** atualizar o app na Play Store
- ⚠️ Terá que criar novo package name
- ⚠️ Perderá todos os usuários que instalaram a versão anterior

---

## 📱 Verificar Assinatura

### Ver informações do APK assinado:

```powershell
# Extrair certificado
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# Ver informações do keystore
keytool -list -v -keystore C:\KeystoresPichau\pichau-ti-release-key.jks -alias pichau-ti-key
```

Você verá:
- **Owner:** Pichau Informática
- **Issuer:** Pichau Informática
- **Serial number:** Único
- **Valid from:** Data atual até 2052
- **Fingerprints:** SHA1, SHA256 (únicos)

---

## 🎯 Próximos Passos

1. **Gere o Keystore** seguindo o Passo 1
2. **Crie o key.properties** com suas senhas
3. **Faça backup** do keystore em 3 lugares
4. **Teste o build** com `flutter build apk --release`
5. **Verifique a assinatura** com keytool
6. **Documente as senhas** em local seguro

---

## 📞 Suporte

Se tiver dúvidas sobre:
- Geração do keystore
- Configuração das senhas
- Problemas no build
- Verificação da assinatura

Entre em contato com o time de desenvolvimento.

---

**Data:** Dezembro/2024  
**Versão do Guia:** 1.0  
**App:** PICHAU TI - Sistema de Suporte Técnico
