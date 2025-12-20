# 🚀 Comandos Úteis - HelpDesk TI

## 📱 Flutter/Dart

### Rodar o App
```powershell
# Android
flutter run

# Específico para device
flutter run -d <device-id>

# Release mode
flutter run --release
```

### Build
```powershell
# APK de debug
flutter build apk --debug

# APK de release
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### Dependências
```powershell
# Instalar/atualizar packages
flutter pub get

# Limpar cache
flutter clean
flutter pub get

# Ver dependências desatualizadas
flutter pub outdated
```

### Análise de Código
```powershell
# Verificar problemas
flutter analyze

# Formatar código
dart format .

# Ver tamanho do app
flutter build apk --analyze-size
```

---

## 🔥 Firebase

### Projetos
```powershell
# Listar projetos
firebase projects:list

# Ver projeto atual
firebase use

# Mudar projeto
firebase use <project-id>
```

### Deploy
```powershell
# Deploy completo
firebase deploy

# Apenas regras
firebase deploy --only firestore:rules

# Apenas índices
firebase deploy --only firestore:indexes

# Apenas functions (requer Blaze)
firebase deploy --only functions

# Apenas hosting
firebase deploy --only hosting
```

### Functions
```powershell
# Listar functions ativas
firebase functions:list

# Deletar function
firebase functions:delete <function-name>

# Ver logs
firebase functions:log

# Logs em tempo real
firebase functions:log --tail
```

### Firestore
```powershell
# Ver dados (console)
firebase firestore:get <collection>

# Deletar collection (cuidado!)
firebase firestore:delete <collection> --recursive

# Backup (requer Blaze)
gcloud firestore export gs://bucket-name
```

---

## 🧪 Testes

### Unit Tests
```powershell
# Rodar todos os testes
flutter test

# Teste específico
flutter test test/widget_test.dart

# Com coverage
flutter test --coverage
```

### Integration Tests
```powershell
# Rodar integration tests
flutter drive --target=test_driver/app.dart
```

---

## 🐛 Debug

### Logs
```powershell
# Ver logs do device
flutter logs

# Logs detalhados
flutter run --verbose
```

### Performance
```powershell
# Analisar performance
flutter run --profile

# DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Conectividade
```powershell
# Ver devices conectados
flutter devices

# Device info
flutter doctor -v
```

---

## 📊 Histórico de Chamados

### Testar a Nova Funcionalidade

1. **Abrir o app**
```powershell
flutter run
```

2. **Login como Admin**
- Email: admin@empresa.com
- Senha: (sua senha)

3. **Criar chamados de teste**
- Ir para "Meus Chamados" (se não for TI)
- Criar alguns chamados
- Atribuir para TI
- Alterar status para "Fechado"

4. **Testar histórico**
- Ir para 3ª aba (⏰ Histórico)
- Testar filtros: 7, 30, 90 dias, todos
- Clicar em cards para ver detalhes
- Verificar que mostra apenas Fechado/Rejeitado

5. **Testar como usuário comum**
- Logout
- Login com usuário normal
- Verificar histórico (deve ver apenas seus chamados)

---

## 🔧 Firebase Emulator (Opcional)

### Instalar
```powershell
firebase init emulators
```

### Rodar
```powershell
# Iniciar emuladores
firebase emulators:start

# Apenas Firestore
firebase emulators:start --only firestore

# Com dados de teste
firebase emulators:start --import=./emulator-data
```

### Vantagens
- Testar sem consumir quota
- Desenvolvimento offline
- Dados de teste isolados

---

## 📦 Git

### Commit das Mudanças
```powershell
# Ver status
git status

# Adicionar arquivos
git add .

# Commit
git commit -m "Simplificação para plano gratuito - histórico de chamados"

# Push
git push origin main
```

### Ver Mudanças
```powershell
# Ver diff
git diff

# Ver histórico
git log --oneline

# Ver arquivo específico
git diff lib/screens/historico_chamados_screen.dart
```

---

## 🎨 VSCode

### Atalhos Úteis
- `Ctrl+Shift+P`: Command Palette
- `Ctrl+P`: Quick Open (buscar arquivo)
- `Ctrl+Shift+F`: Find in Files
- `F12`: Go to Definition
- `Shift+F12`: Find All References
- `Ctrl+.`: Quick Fix

### Flutter Commands
```
> Flutter: Run
> Flutter: Hot Reload (r)
> Flutter: Hot Restart (R)
> Dart: Fix All
> Flutter: Clean
```

---

## 📝 Documentação Útil

### Arquivos do Projeto
```powershell
# Ver simplificação
cat SIMPLIFICACAO_PLANO_GRATUITO.md

# Ver guia de histórico
cat GUIA_HISTORICO_CHAMADOS.md

# Ver status final
cat STATUS_FINAL_SIMPLIFICACAO.md
```

### Links Úteis
- Flutter Docs: https://docs.flutter.dev/
- Firebase Console: https://console.firebase.google.com/
- Pub.dev (packages): https://pub.dev/
- Firebase Pricing: https://firebase.google.com/pricing

---

## 🚨 Troubleshooting

### App não compila
```powershell
flutter clean
flutter pub get
flutter run
```

### Firestore rules error
```powershell
# Re-deploy rules
firebase deploy --only firestore:rules

# Ver regras atuais no console
# https://console.firebase.google.com/project/helpdesk-ti-4bbf2/firestore/rules
```

### Índices faltando
```powershell
# Re-deploy indexes
firebase deploy --only firestore:indexes

# Firebase automaticamente sugere índices necessários nos logs
```

### Hot reload não funciona
```powershell
# Press R no terminal (Hot Restart)
# Ou fechar e rodar novamente
flutter run
```

---

## ✅ Checklist de Deploy

Antes de fazer deploy para produção:

- [ ] Testar em device real
- [ ] Testar com diferentes roles (admin, ti, user)
- [ ] Verificar performance (queries rápidas?)
- [ ] Testar offline (cache funciona?)
- [ ] Verificar Firebase rules (segurança OK?)
- [ ] Verificar índices (queries otimizadas?)
- [ ] Testar histórico com vários períodos
- [ ] Verificar que notificações funcionam (se aplicável)
- [ ] Build de release sem warnings
- [ ] Versionar no pubspec.yaml
- [ ] Commit das mudanças
- [ ] Tag de release no git

---

**💡 Dica**: Mantenha este arquivo aberto em uma aba para consultas rápidas!
