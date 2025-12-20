# 📋 Guia de Templates do Help Desk

## Visão Geral

Os templates foram criados para agilizar a abertura de chamados, fornecendo descrições pré-formatadas com campos que o usuário precisa preencher.

## Como Popular os Templates

### 1️⃣ Acesso Admin

1. Faça login com uma conta de **admin**
2. No app, clique no menu (⋮) no canto superior direito
3. Selecione **"📋 Gerenciar Templates"**

### 2️⃣ Criar Templates Padrão

Na tela de gerenciamento:

1. Clique em **"CRIAR TEMPLATES"**
2. Confirme a ação
3. Aguarde a criação dos 23 templates padrão

### 3️⃣ Verificar Templates Criados

Os templates estarão disponíveis imediatamente na tela de **"Selecionar Template"** quando o usuário criar um novo chamado.

## Templates Incluídos (23 no total)

### 🖥️ **Hardware (3 templates)**
- **Computador não liga** - Computador não inicia, sem resposta
- **Computador muito lento** - Performance ruim, travamentos
- **Teclado/Mouse com defeito** - Periféricos não funcionam

### 🌐 **Rede e Internet (3 templates)**
- **Sem acesso à internet** - Sem conexão de rede
- **Internet lenta** - Velocidade baixa de navegação
- **Ponto de rede não funciona** - Tomada RJ45 com problema

### 🖨️ **Impressoras (3 templates)**
- **Impressora não imprime** - Documentos não saem
- **Impressora com atolamento** - Papel atolado
- **Toner/Tinta acabando** - Suprimentos no fim

### 💻 **Software (3 templates)**
- **Instalação de software** - Solicitar novo programa
- **Programa não abre/trava** - Software com erro
- **Atualização do Windows travando** - Update não completa

### 📧 **Email e Comunicação (2 templates)**
- **Não consigo acessar email** - Login no email falhou
- **Email não envia/recebe** - Problemas de envio/recebimento

### 🔑 **Acessos e Senhas (3 templates)**
- **Esqueci minha senha** - Reset de senha
- **Criar novo usuário** - Onboarding de novo colaborador
- **Desativar usuário** - Offboarding de colaborador

### 📞 **Telefonia (2 templates)**
- **Ramal não funciona** - Telefone sem tom/ligação
- **Solicitar novo ramal** - Instalação de linha

### 🔧 **Outros (4 templates)**
- **Recuperação de arquivos** - Arquivos deletados/perdidos
- **Solicitar novo equipamento** - Compra de hardware
- **Manutenção preventiva** - Limpeza/revisão

## Estrutura dos Templates

Cada template contém:

```dart
{
  'titulo': '🖥️ Computador não liga',
  'descricaoModelo': 'Texto pré-formatado com campos [a preencher]',
  'setor': 'TI',
  'tipo': 'Chamado', // ou 'Solicitacao'
  'prioridade': 3,   // 1=Baixa, 2=Média, 3=Alta, 4=Crítica
  'tags': ['hardware', 'computador', 'urgente'],
  'ativo': true
}
```

### Campos nos Templates

Os templates usam **colchetes [ ]** para indicar onde o usuário deve preencher:

```text
Meu computador não está ligando. Já verifiquei se está conectado na tomada.

Detalhes:
- Local: [Informe seu setor/sala]
- Patrimônio: [Se souber o número]
- Observações adicionais: [Descreva outros sintomas]
```

## Como Funciona na Prática

### Fluxo do Usuário:

1. **Usuário** clica em **"+ Novo Chamado"**
2. Escolhe **"Usar Template"**
3. Vê lista de 23 templates organizados
4. Seleciona o template adequado (ex: "🖥️ Computador não liga")
5. Formulário já vem **pré-preenchido**:
   - ✅ Título
   - ✅ Descrição (com campos [a preencher])
   - ✅ Setor (se aplicável)
   - ✅ Tipo (Chamado ou Solicitação)
6. Usuário substitui os campos **[entre colchetes]**
7. Envia o chamado

### Exemplo Prático:

**Antes (template):**
```
Meu computador está muito lento, travando constantemente.

Sintomas:
- Demora para abrir programas: [Sim/Não]
- Tela congela: [Sim/Não]
- Local: [Setor/Sala]
```

**Depois (usuário preencheu):**
```
Meu computador está muito lento, travando constantemente.

Sintomas:
- Demora para abrir programas: Sim
- Tela congela: Sim
- Local: Financeiro/Sala 12
```

## Prioridades dos Templates

Os templates já vêm com prioridade pré-definida:

- **Prioridade 1 (Baixa)** 🟢
  - Toner acabando
  - Solicitar ramal
  - Solicitar equipamento
  - Manutenção preventiva

- **Prioridade 2 (Média)** 🟡
  - Maioria dos templates de hardware
  - Impressoras
  - Software
  - Usuários

- **Prioridade 3 (Alta)** 🟠
  - Computador não liga
  - Sem internet
  - Email não acessa
  - Esqueci senha
  - Recuperação de arquivos

- **Prioridade 4 (Crítica)** 🔴
  - Nenhum template padrão (usuário pode alterar)

## Tipos de Template

### Chamado (Problema/Incidente)
Algo que **NÃO está funcionando** e precisa de **correção urgente**.

Exemplos:
- ❌ Computador não liga
- ❌ Impressora não imprime
- ❌ Sem acesso à internet

### Solicitação (Requisição/Serviço)
Pedido de algo **novo** ou **melhoria**, não é urgente.

Exemplos:
- ➕ Instalar software
- ➕ Criar usuário
- ➕ Solicitar equipamento

## Gerenciamento de Templates

### Limpar Todos os Templates

⚠️ **CUIDADO:** Esta ação é **IRREVERSÍVEL**!

1. Vá em **"📋 Gerenciar Templates"**
2. Clique em **"LIMPAR TUDO"**
3. Confirme a ação
4. Todos os templates serão **deletados** do Firestore

### Recriar Templates

Se deletou por engano ou quer resetar:

1. Clique em **"CRIAR TEMPLATES"** novamente
2. Os 23 templates padrão serão recriados

## Arquitetura Técnica

### Modelo de Dados (ChamadoTemplate)

```dart
class ChamadoTemplate {
  final String id;
  final String titulo;
  final String descricaoModelo;
  final String? setor;
  final String tipo;
  final int prioridade;
  final List<String> tags;
  final bool ativo;
  final DateTime dataCriacao;
}
```

### Firestore Collection

```
Firestore
└── templates/
    ├── {id1}
    │   ├── titulo: "🖥️ Computador não liga"
    │   ├── descricaoModelo: "..."
    │   ├── setor: "TI"
    │   ├── tipo: "Chamado"
    │   ├── prioridade: 3
    │   ├── tags: ["hardware", "computador"]
    │   ├── ativo: true
    │   └── dataCriacao: Timestamp
    └── ...
```

### Seed Script

Localização: `lib/utils/seed_templates.dart`

```dart
// Criar templates
await TemplateSeed.seedTemplates();

// Limpar templates
await TemplateSeed.clearAllTemplates();
```

## Personalização

### Adicionar Novos Templates

1. Edite `lib/utils/seed_templates.dart`
2. Adicione um novo objeto no array `templates`:

```dart
{
  'titulo': '🆕 Seu Novo Template',
  'descricaoModelo': 'Descrição com [campos] para preencher',
  'setor': 'TI',
  'tipo': 'Chamado',
  'prioridade': 2,
  'tags': ['tag1', 'tag2'],
  'ativo': true,
  'dataCriacao': FieldValue.serverTimestamp(),
},
```

3. Execute **"LIMPAR TUDO"** no app
4. Execute **"CRIAR TEMPLATES"** para incluir o novo

### Desativar Templates

No Firestore, altere o campo `ativo` para `false`:

```javascript
// No Firebase Console
templates/{id}.ativo = false
```

Templates inativos não aparecem na lista de seleção.

## Tags Disponíveis

Use para filtros futuros:

```dart
'hardware', 'software', 'rede', 'internet', 
'impressora', 'email', 'telefone', 'ramal',
'usuario', 'acesso', 'senha', 'instalacao',
'manutencao', 'urgente', 'preventiva',
'computador', 'perifericos', 'dados', 'recuperacao'
```

## Benefícios dos Templates

✅ **Padronização** - Todos os chamados seguem o mesmo formato
✅ **Agilidade** - Usuário não precisa digitar tudo do zero
✅ **Completude** - Templates garantem que informações importantes não sejam esquecidas
✅ **Clareza** - TI recebe chamados com detalhes necessários
✅ **Métricas** - Tags permitem análise futura de tipos de chamados

## Troubleshooting

### Templates não aparecem na lista

1. Verifique se executou **"CRIAR TEMPLATES"**
2. Confirme que `ativo: true` no Firestore
3. Verifique conexão com Firebase
4. Veja logs no console: `🎧 DEBUG: Listener de templates...`

### Erro ao criar templates

1. Verifique permissões do Firestore Rules
2. Usuário precisa ser **admin**
3. Confira conexão com internet
4. Veja logs de erro no console

### Templates vazios

Se os campos não pré-preenchem:

1. Verifique `lib/widgets/new_ticket_form.dart`
2. Confirme que `widget.template` não é null
3. Veja se `initState()` está executando

## Próximos Passos

🔜 **Filtro por tags** - Buscar templates por categoria
🔜 **Favoritos** - Usuários marcam templates mais usados
🔜 **Analytics** - Quais templates são mais utilizados
🔜 **Editor Web** - Criar/editar templates pelo painel admin

---

**Criado por:** Sistema Help Desk TI  
**Última atualização:** 28/11/2025  
**Versão:** 1.0
