# 📋 PLANO DE CORREÇÕES - VERSÃO WEB HELPDESK TI

## Data: 02/01/2026
## Status: Em Andamento

---

## 🎯 RESUMO EXECUTIVO

Este documento detalha todas as correções e melhorias necessárias para a versão web do Helpdesk TI hospedada no Firebase Hosting.

---

## ✅ CORREÇÕES CONCLUÍDAS

### 1. Logo do Pombo
- [x] Substituído ícone genérico pelo `pombo_logo.png` na sidebar
- [x] Login já usa o logo corretamente

### 2. Warnings e Erros Dart
- [x] Removidos imports não usados
- [x] Removidas variáveis não usadas
- [x] Corrigidos deprecated members (`value` → `initialValue`)
- [x] Adicionados `const` onde necessário

### 3. Configuração Firebase
- [x] Adicionada configuração de hosting no `firebase.json`
- [x] Criado script `deploy-web.ps1`
- [x] Criado guia `GUIA_DEPLOY_WEB.md`

---

## 🔧 CORREÇÕES PENDENTES

### PRIORIDADE ALTA

#### 1. Header - Botão de Notificações (web_layout.dart)
**Problema:** Botão de notificações mostra badge fixo "3" e não faz nada
**Solução:** Integrar com sistema de notificações ou mostrar lista de notificações

#### 2. Criação de Chamados via Web
**Problema:** Não há botão/funcionalidade para criar novos chamados na web
**Solução:** Adicionar botão "Novo Chamado" na tela de chamados

#### 3. Edição de Usuários (web_usuarios_screen.dart)
**Problema:** Visualização funciona, mas edição de role não está implementada
**Solução:** Implementar dialog de edição de usuário

#### 4. Exportar Relatórios (web_relatorios_screen.dart)
**Problema:** Botão "Exportar PDF" mostra apenas snackbar
**Solução:** Implementar exportação real ou remover botão

### PRIORIDADE MÉDIA

#### 5. Configurações (web_configuracoes_screen.dart)
**Problema:** Botão "Salvar Alterações" não persiste dados
**Solução:** Salvar configurações no Firestore ou SharedPreferences

#### 6. Filtros de Relatórios
**Problema:** Filtro de período não afeta dados corretamente
**Solução:** Verificar lógica de filtro por data

#### 7. Paginação de Chamados
**Problema:** Paginação pode não estar funcionando corretamente
**Solução:** Testar e corrigir lógica de paginação

### PRIORIDADE BAIXA

#### 8. Responsividade
**Problema:** Layout pode quebrar em telas muito pequenas
**Solução:** Adicionar breakpoints para tablets menores

#### 9. Tema Claro vs Escuro
**Problema:** Algumas cores podem não estar adaptadas corretamente
**Solução:** Revisar todas as cores em ambos os modos

#### 10. Loading States
**Problema:** Alguns estados de carregamento podem estar faltando
**Solução:** Adicionar indicadores de loading consistentes

---

## 📊 COMPARAÇÃO APP vs WEB

| Funcionalidade | App Mobile | Web | Status |
|----------------|------------|-----|--------|
| Login/Logout | ✅ | ✅ | OK |
| Dashboard | ✅ | ✅ | OK |
| Ver Chamados TI | ✅ | ✅ | OK |
| Ver Chamados Manutenção | ✅ | ✅ | OK |
| Criar Chamado TI | ✅ | ❌ | FALTA |
| Criar Chamado Manutenção | ✅ | ❌ | FALTA |
| Editar Chamado | ✅ | ✅ | OK |
| Comentários | ✅ | ✅ | OK |
| Alterar Status | ✅ | ✅ | OK |
| Gerenciar Usuários | ✅ | ⚠️ | PARCIAL |
| Editar Role Usuário | ✅ | ❌ | FALTA |
| Relatórios | ✅ | ⚠️ | PARCIAL |
| Exportar PDF | ✅ | ❌ | FALTA |
| Configurações | ✅ | ⚠️ | PARCIAL |
| Notificações | ✅ | ❌ | FALTA |
| Tema Claro/Escuro | ✅ | ✅ | OK |
| Templates | ✅ | ❌ | FALTA |
| Histórico Chamados | ✅ | ❌ | FALTA |

---

## 🚀 PRÓXIMOS PASSOS

1. **Implementar Criar Chamado na Web**
   - Adicionar botão "Novo Chamado" 
   - Criar dialog/modal de criação
   - Integrar com FirestoreService

2. **Implementar Edição de Usuários**
   - Adicionar botão de edição na tabela
   - Criar dialog de edição
   - Permitir alterar role, nome, etc.

3. **Corrigir Notificações**
   - Buscar notificações reais do Firestore
   - Mostrar dropdown com lista
   - Marcar como lidas

4. **Build e Deploy Final**
   ```powershell
   flutter build web --release -t lib/main_web.dart
   firebase deploy --only hosting
   ```

---

## 📁 ARQUIVOS PRINCIPAIS DA VERSÃO WEB

```
lib/web/
├── layouts/
│   └── web_layout.dart           # Layout principal com sidebar
├── screens/
│   ├── web_login_screen.dart     # Tela de login
│   ├── web_dashboard_screen.dart # Dashboard
│   ├── web_chamados_screen.dart  # Gerenciamento de chamados
│   ├── web_usuarios_screen.dart  # Gerenciamento de usuários
│   ├── web_relatorios_screen.dart # Relatórios
│   ├── web_configuracoes_screen.dart # Configurações
│   ├── web_user_home_screen.dart # Home do usuário comum
│   └── web_manutencao_detail_screen.dart # Detalhes manutenção
└── widgets/
    ├── chamado_detail_dialog.dart # Dialog detalhes chamado
    ├── chamado_edit_dialog.dart   # Dialog edição chamado
    ├── recent_tickets_table.dart  # Tabela de chamados recentes
    ├── stat_card_web.dart         # Card de estatísticas
    └── web_page_header.dart       # Header de página
```

---

**Última atualização:** 02/01/2026
