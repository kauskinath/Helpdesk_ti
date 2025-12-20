# 🔄 MAPEAMENTO DE IMPORTS - REFATORAÇÃO

## Arquivos Movidos e Novos Paths

### **CORE (Tema, Services, Utils, Constants)**

```dart
// ANTES → DEPOIS

// Tema
'lib/core/app_theme.dart' → 'package:helpdesk_ti/core/theme/app_theme.dart'
'lib/core/app_colors.dart' → 'package:helpdesk_ti/core/theme/app_colors.dart'
'lib/providers/theme_provider.dart' → 'package:helpdesk_ti/core/theme/theme_provider.dart'

// Services
'lib/data/auth_service.dart' → 'package:helpdesk_ti/core/services/auth_service.dart'
'lib/services/notification_service.dart' → 'package:helpdesk_ti/core/services/notification_service.dart'
'lib/services/navigation_service.dart' → 'package:helpdesk_ti/core/services/navigation_service.dart'
'lib/core/permissions_service.dart' → 'package:helpdesk_ti/core/services/permissions_service.dart'

// Utils
'lib/utils/date_formatter.dart' → 'package:helpdesk_ti/core/utils/date_formatter.dart'
'lib/utils/snackbar_helper.dart' → 'package:helpdesk_ti/core/utils/snackbar_helper.dart'
```

### **FEATURES (TI Models)**

```dart
// Models TI
'lib/models/chamado.dart' → 'package:helpdesk_ti/features/ti/models/chamado.dart'
'lib/models/comentario.dart' → 'package:helpdesk_ti/features/ti/models/comentario.dart'
'lib/models/avaliacao.dart' → 'package:helpdesk_ti/features/ti/models/avaliacao.dart'
'lib/models/solicitacao.dart' → 'package:helpdesk_ti/features/ti/models/solicitacao.dart'
'lib/models/chamado_template.dart' → 'package:helpdesk_ti/features/ti/models/chamado_template.dart'
```

### **FEATURES (Manutenção)**

```dart
// Manutenção (modulos → features)
'lib/modulos/manutencao/' → 'package:helpdesk_ti/features/manutencao/'
```

### **SHARED (Novos componentes base)**

```dart
// Novos widgets compartilhados
'package:helpdesk_ti/shared/widgets/base_dashboard_layout.dart' (NOVO)
'package:helpdesk_ti/shared/widgets/base_chamado_card.dart' (NOVO)
'package:helpdesk_ti/shared/mixins/filterable_mixin.dart' (NOVO)
```

---

## ⚠️ ARQUIVOS QUE PRECISAM SER ATUALIZADOS

### **Prioridade ALTA (Quebram compilação)**

1. **lib/main.dart** - Importa theme_provider, auth_service
2. **lib/screens/home_screen.dart** - Importa auth, theme, models
3. **lib/screens/user_home_screen.dart** - Importa auth, theme
4. **lib/screens/manutencao_router_screen.dart** - Importa auth
5. **lib/features/manutencao/** - Todos os arquivos importam auth_service
6. **Todos os screens TI** - Importam models, auth, theme

### **Estratégia de Atualização**

**OPÇÃO 1: Manual (Controlado)**
- Atualizar main.dart primeiro
- Testar compilação
- Atualizar screens principais
- Testar novamente
- Atualizar restante

**OPÇÃO 2: Script PowerShell (Rápido)**
```powershell
# Substituir imports em massa
Get-ChildItem -Path lib -Filter *.dart -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Atualizar imports theme
    $content = $content -replace "import '../core/app_theme.dart'", "import 'package:helpdesk_ti/core/theme/app_theme.dart'"
    $content = $content -replace "import '../../core/app_theme.dart'", "import 'package:helpdesk_ti/core/theme/app_theme.dart'"
    
    # ... mais substituições
    
    Set-Content $_.FullName -Value $content
}
```

---

## 📋 PRÓXIMOS PASSOS

1. **Decisão:** Manual ou Script?
2. **Backup:** Commit antes de refatorar
3. **Executar:** Atualizar imports
4. **Validar:** `flutter analyze`
5. **Testar:** `flutter run`

**Status:** Aguardando decisão do usuário 🚀
