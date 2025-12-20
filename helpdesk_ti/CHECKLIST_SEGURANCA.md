# ✅ CHECKLIST DE SEGURANÇA - PICHAU TI

## 🎯 Use este checklist antes de cada release!

---

## 📋 FASE 1: PRÉ-BUILD

### Configuração Inicial
- [ ] **Keystore gerado** (executar `.\gerar-keystore.ps1` apenas uma vez)
- [ ] **Backup do keystore** em 3+ locais diferentes
- [ ] **Senhas documentadas** em cofre seguro (LastPass, 1Password, etc.)
- [ ] **key.properties criado** em `android/key.properties`
- [ ] **key.properties no .gitignore** (verificar se está listado)

### Informações do App
- [ ] **Versão atualizada** no `pubspec.yaml` (formato: x.y.z+build)
- [ ] **Package name correto**: `com.pichau.helpdesk_ti`
- [ ] **Copyright atualizado** no código e documentação
- [ ] **Licença proprietária** revisada e atualizada

### Código
- [ ] **Análise Flutter** sem erros críticos (`flutter analyze`)
- [ ] **Testes passando** (se houver testes implementados)
- [ ] **Código commitado** no Git (branch atualizada)
- [ ] **Sem TODOs críticos** no código

---

## 🔨 FASE 2: BUILD

### Preparação
- [ ] **Terminal na pasta do projeto** (`cd helpdesk_ti`)
- [ ] **Flutter atualizado** (`flutter --version`)
- [ ] **Dependências atualizadas** (`flutter pub get`)
- [ ] **Build anterior limpo** (`flutter clean` ou automático no script)

### Execução do Build
Escolha uma opção:

**Opção A: APK para distribuição direta**
```powershell
.\build-release.ps1 -BuildType apk
```
- [ ] Build executado sem erros
- [ ] APK gerado em `build\app\outputs\flutter-apk\app-release.apk`
- [ ] Tamanho do APK anotado

**Opção B: AAB para Google Play Store**
```powershell
.\build-release.ps1 -BuildType appbundle
```
- [ ] Build executado sem erros
- [ ] AAB gerado em `build\app\outputs\bundle\release\app-release.aab`
- [ ] Tamanho do AAB anotado

**Opção C: Ambos**
```powershell
.\build-release.ps1 -BuildType both
```
- [ ] Ambos os builds executados sem erros
- [ ] APK e AAB gerados

---

## 🔍 FASE 3: VERIFICAÇÃO

### Assinatura Digital
```powershell
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
```
- [ ] **Owner** mostra: `Pichau Informática` (ou conforme configurado)
- [ ] **Issuer** mostra: informações corretas da empresa
- [ ] **Valid until** mostra: data no futuro (2050+)
- [ ] **Serial number** presente e único
- [ ] **SHA1 e SHA256** fingerprints presentes

### Ofuscação de Código
Para verificar se o código foi ofuscado:
```powershell
# Extrair APK
7z x build\app\outputs\flutter-apk\app-release.apk -oextracted

# Verificar classes.dex (opcional - requer ferramentas Android)
```
- [ ] Código está ofuscado (nomes como a1, b2, c3)
- [ ] Tamanho reduzido em ~30-40% comparado ao debug

### Metadados
```powershell
# Verificar informações do pacote
aapt dump badging build\app\outputs\flutter-apk\app-release.apk
```
- [ ] **package**: `com.pichau.helpdesk_ti`
- [ ] **versionName**: versão correta
- [ ] **application-label**: `PICHAU TI`

### Instalação e Testes
- [ ] APK instalado em dispositivo físico (não emulador)
- [ ] App abre sem crashes
- [ ] Login funciona
- [ ] Funcionalidades principais testadas:
  - [ ] Criar chamado
  - [ ] Listar chamados
  - [ ] Abrir detalhes
  - [ ] Notificações funcionando
  - [ ] Tema (claro/escuro) funciona
- [ ] Performance aceitável
- [ ] Sem vazamentos de memória aparentes

---

## 📤 FASE 4: DISTRIBUIÇÃO

### Para Distribuição Interna (APK)
- [ ] APK copiado para local seguro
- [ ] Nome do arquivo: `pichau-ti-v1.0.0-release.apk`
- [ ] Hash SHA256 calculado para verificação
- [ ] Link de download preparado (se necessário)
- [ ] Instruções de instalação preparadas

### Para Google Play Store (AAB)
- [ ] AAB testado com `bundletool` (opcional)
- [ ] Screenshots atualizados
- [ ] Descrição da loja atualizada
- [ ] Changelog preparado (novidades da versão)
- [ ] Play Console configurada
- [ ] Teste interno/fechado realizado

### Documentação
- [ ] Release notes criadas
- [ ] Changelog atualizado
- [ ] Documentação técnica atualizada
- [ ] Guias de usuário atualizados (se necessário)

---

## 🔐 FASE 5: SEGURANÇA PÓS-BUILD

### Backup
- [ ] **Keystore** backup verificado e acessível
- [ ] **Senhas** backup verificado e acessível
- [ ] **APK/AAB** backup em local seguro
- [ ] **Código fonte** commitado e pushado

### Git/Repositório
- [ ] **key.properties** NÃO foi commitado
- [ ] **Keystore (.jks)** NÃO foi commitado
- [ ] **Senhas** NÃO estão no código
- [ ] **.gitignore** atualizado e funcionando
- [ ] Commit com mensagem descritiva
- [ ] Tag criada: `git tag v1.0.0` (se aplicável)

### Auditoria
- [ ] Verificar histórico do Git por informações sensíveis
- [ ] Confirmar que APK antigo foi removido (se necessário)
- [ ] Documentar quem teve acesso ao keystore
- [ ] Registrar data e versão do build

---

## 📊 FASE 6: MÉTRICAS E MONITORAMENTO

### Antes do Lançamento
- [ ] Firebase Analytics configurado
- [ ] Crashlytics configurado (se houver)
- [ ] Logs de produção configurados
- [ ] Sistema de feedback preparado

### Após o Lançamento
- [ ] Monitorar crashes (primeiras 24h)
- [ ] Verificar reviews/feedback
- [ ] Acompanhar métricas de uso
- [ ] Preparar hotfix se necessário

---

## 🚨 CHECKLIST DE EMERGÊNCIA

### Se algo der errado:

**Build falha:**
- [ ] Verificar `key.properties` existe e está correto
- [ ] Verificar senhas no `key.properties`
- [ ] Executar `flutter clean && flutter pub get`
- [ ] Verificar versão do Flutter
- [ ] Consultar `GUIA_ASSINATURA_DIGITAL.md`

**APK não instala:**
- [ ] Desinstalar versão antiga
- [ ] Verificar assinatura digital
- [ ] Testar em dispositivo diferente
- [ ] Verificar Android mínimo (API 24+)

**Keystore perdido:**
- [ ] ⚠️ **CRÍTICO**: Verificar backups imediatamente
- [ ] Se backup disponível: restaurar
- [ ] Se sem backup: **impossível** atualizar app na Play Store
- [ ] Documentar incidente

---

## 📝 INFORMAÇÕES DO BUILD

Preencha após cada build:

```
Data do Build: ___/___/______
Versão: ___.___.___ (build ___)
Tipo: [ ] APK  [ ] AAB  [ ] Ambos
Build por: _____________________
Tamanho APK: _____ MB
Tamanho AAB: _____ MB
SHA256 APK: _____________________
Status: [ ] Sucesso  [ ] Falha
Notas: ___________________________
___________________________________
___________________________________
```

---

## ✅ APROVAÇÃO FINAL

Antes de liberar para produção:

- [ ] Todos os itens deste checklist foram verificados
- [ ] Testes passaram sem problemas críticos
- [ ] Backup do keystore confirmado
- [ ] Documentação atualizada
- [ ] Equipe de TI notificada
- [ ] Plano de rollback preparado (se necessário)

**Aprovado por:** _____________________  
**Data:** ___/___/______  
**Assinatura:** _____________________

---

## 📞 CONTATOS DE EMERGÊNCIA

| Papel | Nome | Contato |
|-------|------|---------|
| Desenvolvedor Principal | _________ | _________ |
| Gerente de TI | _________ | _________ |
| Backup - Acesso Keystore | _________ | _________ |
| Suporte Play Store | _________ | _________ |

---

## 📚 DOCUMENTAÇÃO DE REFERÊNCIA

1. **GUIA_ASSINATURA_DIGITAL.md** - Guia completo passo a passo
2. **SEGURANCA.md** - Melhores práticas de segurança
3. **RESUMO_PROTECAO.md** - Resumo executivo
4. **DIAGRAMA_SEGURANCA.md** - Diagrama visual
5. **LICENSE** - Licença proprietária

---

**© 2024-2025 Pichau Informática Ltda**  
**Documento Confidencial - Uso Interno**  
**Versão do Checklist:** 1.0  
**Última Atualização:** Dezembro/2024
