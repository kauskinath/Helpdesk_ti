# ✅ CHECKLIST DE TESTES - MÓDULO MANUTENÇÃO

## 📋 Preparação
- [ ] Deploy Firestore concluído (rules + indexes)
- [ ] APK instalado no dispositivo de teste
- [ ] Criar usuários de teste para cada role no Firebase Console

---

## 👤 TESTE 1: USUÁRIO COMUM (role: user)

### Login e Navegação
- [ ] Login com credenciais de usuário comum
- [ ] Verificar se aparece interface com **2 TABS**: 💻 TI e 🔧 Manutenção
- [ ] Alternar entre as tabs e verificar conteúdo correto

### Criar Chamado SEM Orçamento
- [ ] Tab Manutenção → Botão FAB "Criar Chamado"
- [ ] Preencher: Título, Descrição
- [ ] **NÃO** ativar toggle "Adicionar Orçamento"
- [ ] Criar chamado e verificar sucesso
- [ ] Verificar status: `📝 Aberto`

### Criar Chamado COM Orçamento
- [ ] Tab Manutenção → Criar novo chamado
- [ ] Ativar toggle "Adicionar Orçamento"
- [ ] Upload PDF (máx 10MB)
- [ ] Adicionar link externo (opcional)
- [ ] Valor estimado: R$ 500,00
- [ ] Lista materiais: "Parafusos\nTinta branca\nPincel"
- [ ] Criar e verificar status: `📝 Aberto`

### Listar Chamados
- [ ] Ver lista de chamados criados
- [ ] Filtrar por status
- [ ] Buscar por texto
- [ ] Abrir detalhes de um chamado

---

## 🛠️ TESTE 2: ADMIN MANUTENÇÃO (role: admin_manutencao)

### Login e Acesso
- [ ] Login com credenciais de admin_manutencao
- [ ] Verificar redirecionamento direto para **Dashboard Admin Manutenção**
- [ ] Verificar que NÃO aparece módulo TI

### Validar Chamado SEM Orçamento
- [ ] Ver chamado aberto na lista
- [ ] Clicar em "Validar"
- [ ] Aprovar (verde) → Status deve ir para `✅ Liberado para Execução`
- [ ] Verificar notificação enviada ao criador

### Validar Chamado COM Orçamento
- [ ] Ver chamado com orçamento na lista
- [ ] Clicar em "Validar"
- [ ] Aprovar → Status deve ir para `⏳ Aguardando Aprovação Gerente`
- [ ] Verificar notificação enviada ao criador

### Criar Chamado como Admin (sem orçamento)
- [ ] Admin pode criar chamado SEM orçamento
- [ ] Verificar que pula validação → vai direto para `✅ Liberado para Execução`

### Atribuir Executor
- [ ] Chamado em status `✅ Liberado para Execução`
- [ ] Clicar em "Atribuir Executor"
- [ ] Selecionar executor da lista
- [ ] Confirmar atribuição
- [ ] Status deve mudar para `👷 Atribuído ao Executor`
- [ ] Verificar notificação enviada ao executor

---

## 👔 TESTE 3: GERENTE (role: manager)

### Login e Acesso
- [ ] Login com credenciais de gerente
- [ ] Verificar redirecionamento para **Dashboard Gerente**
- [ ] Verificar que só vê chamados em `⏳ Aguardando Aprovação Gerente`

### Aprovar Orçamento
- [ ] Ver chamado pendente com orçamento
- [ ] Clicar em "Analisar Orçamento"
- [ ] Ver valor destacado, PDF, link, materiais
- [ ] Clicar em "APROVAR" (botão verde)
- [ ] Status deve ir para `💰 Orçamento Aprovado`
- [ ] Verificar notificação enviada ao criador

### Rejeitar Orçamento
- [ ] Ver outro chamado pendente
- [ ] Clicar em "Analisar Orçamento"
- [ ] Preencher **motivo da rejeição** (mín 10 chars)
- [ ] Clicar em "REJEITAR" (botão vermelho)
- [ ] Status deve ir para `❌ Orçamento Rejeitado`
- [ ] Verificar notificação com motivo enviada ao criador

---

## 🔧 TESTE 4: EXECUTOR (role: executor)

### Login e Acesso
- [ ] Login com credenciais de executor
- [ ] Verificar redirecionamento para **Dashboard Executor**
- [ ] Verificar que só vê chamados atribuídos a ele

### Recusar Trabalho
- [ ] Ver chamado em status `👷 Atribuído ao Executor`
- [ ] Clicar em "RECUSAR"
- [ ] Preencher **motivo obrigatório** (mín 10 chars)
- [ ] Confirmar recusa
- [ ] Status deve ir para `🚫 Recusado pelo Executor`
- [ ] Verificar notificação enviada aos admins_manutencao

### Iniciar Execução
- [ ] Ver chamado em status `👷 Atribuído ao Executor`
- [ ] Clicar em "INICIAR"
- [ ] Status deve mudar para `⚙️ Em Execução`
- [ ] Data início deve ser registrada

### Finalizar com Foto
- [ ] Chamado em status `⚙️ Em Execução`
- [ ] Clicar em "CONTINUAR EXECUÇÃO"
- [ ] **Tentar finalizar SEM foto** → Deve mostrar erro
- [ ] Tirar foto com câmera OU selecionar da galeria
- [ ] Ver preview da foto
- [ ] Clicar em "FINALIZAR TRABALHO"
- [ ] Status deve ir para `✅ Finalizado`
- [ ] Foto deve ser enviada ao Storage
- [ ] Data fim deve ser registrada

### Solicitar Materiais (Executor cria chamado)
- [ ] Clicar no FAB "Solicitar Materiais"
- [ ] Preencher título e descrição
- [ ] **Seção Orçamento é OBRIGATÓRIA**
- [ ] Upload PDF, link, valor, **materiais obrigatórios**
- [ ] Criar chamado
- [ ] Ver mensagem: "Será automaticamente atribuído após materiais"
- [ ] Verificar que chamado tem `autoAtribuicao = true`

---

## 🔒 TESTE 5: ADMIN TI (role: admin) - BLOQUEIO

### Tentar Acessar Manutenção
- [ ] Login com credenciais de admin TI
- [ ] Tentar navegar para `/manutencao`
- [ ] Verificar tela de erro: "🚫 Acesso Restrito"
- [ ] Mensagem: "Administradores de TI não têm acesso ao módulo de Manutenção"
- [ ] Botão "Voltar" funciona

---

## 🔄 TESTE 6: FLUXO COMPLETO COM ORÇAMENTO

### Sequência: User → Admin → Gerente → Compra → Executor → Finalizado
1. [ ] **User** cria chamado COM orçamento → `📝 Aberto`
2. [ ] **Admin Manutenção** valida e aprova → `⏳ Aguardando Aprovação Gerente`
3. [ ] **Gerente** aprova orçamento → `💰 Orçamento Aprovado`
4. [ ] **Admin Manutenção** atualiza compra → `🛒 Em Compra`
5. [ ] **Admin Manutenção** confirma chegada → `📦 Aguardando Materiais`
6. [ ] **Admin Manutenção** libera para execução → `✅ Liberado para Execução`
7. [ ] **Admin Manutenção** atribui executor → `👷 Atribuído ao Executor`
8. [ ] **Executor** inicia trabalho → `⚙️ Em Execução`
9. [ ] **Executor** finaliza com foto → `✅ Finalizado`

### Validações de Cada Etapa
- [ ] Notificações enviadas corretamente em cada mudança
- [ ] Status atualizado em tempo real
- [ ] Histórico preservado (datas, responsáveis)
- [ ] PDF e foto armazenados corretamente no Storage

---

## 🔄 TESTE 7: FLUXO COMPLETO SEM ORÇAMENTO

### Sequência: User → Admin → Executor → Finalizado
1. [ ] **User** cria chamado SEM orçamento → `📝 Aberto`
2. [ ] **Admin Manutenção** valida e aprova → `✅ Liberado para Execução` (pula gerente)
3. [ ] **Admin Manutenção** atribui executor → `👷 Atribuído ao Executor`
4. [ ] **Executor** inicia trabalho → `⚙️ Em Execução`
5. [ ] **Executor** finaliza com foto → `✅ Finalizado`

---

## 🔄 TESTE 8: FLUXO ADMIN SELF (sem validação)

### Sequência: Admin cria → Executor → Finalizado
1. [ ] **Admin Manutenção** cria chamado SEM orçamento
2. [ ] Verificar que vai direto para `✅ Liberado para Execução` (pula validação)
3. [ ] **Admin** atribui executor → `👷 Atribuído ao Executor`
4. [ ] **Executor** executa e finaliza → `✅ Finalizado`

---

## 🔄 TESTE 9: FLUXO EXECUTOR SELF (auto-atribuição)

### Sequência: Executor cria → Gerente → Auto-atribuição → Finalizado
1. [ ] **Executor** solicita materiais (cria com orçamento)
2. [ ] **Admin** valida → `⏳ Aguardando Aprovação Gerente`
3. [ ] **Gerente** aprova → `💰 Orçamento Aprovado`
4. [ ] **Admin** atualiza compra e libera → `✅ Liberado para Execução`
5. [ ] **Sistema** auto-atribui ao executor criador → `👷 Atribuído ao Executor`
6. [ ] **Executor** executa e finaliza → `✅ Finalizado`

---

## 🚨 TESTE 10: VALIDAÇÕES E EDGE CASES

### Campos Obrigatórios
- [ ] Título: mín 3, máx 100 caracteres
- [ ] Descrição: mín 10, máx 1000 caracteres
- [ ] Motivo recusa: mín 10 caracteres
- [ ] Motivo rejeição orçamento: obrigatório se rejeitar
- [ ] Foto comprovante: obrigatória para finalizar
- [ ] Lista materiais: obrigatória para executor criar

### Limites de Arquivo
- [ ] PDF orçamento: máx 10MB
- [ ] Foto comprovante: compressão para 1920x1080, 85% quality
- [ ] Extensões PDF: .pdf, .doc, .docx
- [ ] Extensões foto: .jpg, .jpeg, .png

### Filtros e Busca
- [ ] Filtro por status funciona
- [ ] Busca por texto (título/descrição) funciona
- [ ] Badge de filtro ativo aparece
- [ ] Botão limpar filtro funciona

### Empty States
- [ ] "Nenhum orçamento pendente" (Gerente)
- [ ] "Nenhum trabalho atribuído" (Executor)
- [ ] "Nenhum resultado encontrado" (busca vazia)

### Formatação de Data
- [ ] "<60min" → "Xmin atrás"
- [ ] "<24h" → "Xh atrás"
- [ ] "1 dia" → "ontem"
- [ ] "<7 dias" → "Xd atrás"
- [ ] ">7 dias" → "DD/MM/YYYY"

---

## 📊 TESTE 11: PERFORMANCE E SEGURANÇA

### Firestore Rules
- [ ] Admin TI não consegue ler chamados MANUTENCAO
- [ ] Admin Manutenção não consegue ler chamados TI
- [ ] Gerente só vê chamados em `aguardandoAprovacaoGerente`
- [ ] Executor só vê chamados onde `execucao.executorId == uid`
- [ ] User só vê seus próprios chamados

### Índices Compostos
- [ ] Query `tipo + dataAbertura` (geral)
- [ ] Query `tipo + status + dataAbertura` (Admin)
- [ ] Query `tipo + execucao.executorId + dataAbertura` (Executor)
- [ ] Query `tipo + criadorId + dataAbertura` (User)

### Notificações Push
- [ ] Notificação de atribuição chega ao executor
- [ ] Notificação de recusa chega aos admins
- [ ] Notificação de validação chega ao criador
- [ ] Notificação de aprovação/rejeição chega ao criador
- [ ] Tocar na notificação abre o chamado correto

---

## 🎨 TESTE 12: UI/UX

### Cores por Status
- [ ] Cada status tem cor correta (15 cores diferentes)
- [ ] Cards com borda colorida baseada no status
- [ ] Badge de status legível (emoji + texto branco)

### Navegação
- [ ] AppBar com botão voltar funciona
- [ ] Tabs deslizam corretamente (user)
- [ ] FAB posicionado corretamente
- [ ] Dialogs de confirmação aparecem
- [ ] Loading states aparecem durante operações

### Responsividade
- [ ] Interface adapta a diferentes tamanhos de tela
- [ ] Textos não cortam
- [ ] Imagens não distorcem
- [ ] Botões são clicáveis

---

## ✅ CRITÉRIOS DE SUCESSO

### Funcionalidade
- ✅ Todos os 4 fluxos completos funcionam
- ✅ Todas as validações impedem ações inválidas
- ✅ Notificações chegam corretamente
- ✅ Fotos e PDFs são salvos no Storage

### Segurança
- ✅ Admin TI bloqueado de manutenção
- ✅ Gerente só vê orçamentos pendentes
- ✅ Executor só vê trabalhos atribuídos
- ✅ Rules aplicadas corretamente

### Performance
- ✅ Queries otimizadas com índices
- ✅ Imagens comprimidas automaticamente
- ✅ Streams atualizam em tempo real
- ✅ Sem lags ou travamentos

### UX
- ✅ Interface intuitiva
- ✅ Mensagens claras de erro/sucesso
- ✅ Confirmações antes de ações críticas
- ✅ Estados vazios informativos

---

## 🐛 BUGS ENCONTRADOS

### Bug #1
- **Descrição**: 
- **Passos para reproduzir**: 
- **Severidade**: Alta / Média / Baixa
- **Status**: Pendente / Corrigido

### Bug #2
- **Descrição**: 
- **Passos para reproduzir**: 
- **Severidade**: 
- **Status**: 

---

## 📝 OBSERVAÇÕES

- 
- 
- 

---

**Data dos Testes**: ___/___/2025  
**Testador**: _________________  
**Dispositivo**: _________________  
**Versão APK**: _________________  
**Status Final**: ⏳ Em Andamento / ✅ Aprovado / ❌ Reprovado
