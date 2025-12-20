# 📝 Guia de Templates com Formulários Dinâmicos

## O Problema Resolvido

**Antes**: Templates apenas pré-preenchiam um texto com `[campos a preencher]`, forçando o usuário a:
- Ler tudo na caixa pequena de descrição
- Apagar manualmente cada `[item]`
- Mais trabalhoso que criar manualmente

**Agora**: Templates com campos estruturados renderizam um **formulário dinâmico inteligente** com:
- ✅ Campos específicos para cada informação
- ✅ Dropdowns, checkboxes, radio buttons
- ✅ Validação automática
- ✅ Interface limpa e rápida

## Como Funciona

### 1️⃣ **Estrutura de Campos**

Cada template pode ter uma lista de campos (`campos: []`) que define o formulário:

```dart
campos: [
  {
    'id': 'local',
    'label': 'Local',
    'type': 'text',
    'required': true,
    'placeholder': 'Ex: Sala 12, Andar 2'
  },
  {
    'id': 'problema',
    'label': 'Qual o problema?',
    'type': 'select',
    'required': true,
    'options': ['Não liga', 'Trava', 'Lento', 'Barulho estranho']
  }
]
```

### 2️⃣ **Tipos de Campos Disponíveis**

| Tipo | Uso | Exemplo |
|------|-----|---------|
| `text` | Texto curto | Nome, patrimônio, local |
| `multiline` | Texto longo | Descrição detalhada |
| `number` | Números | Ramal, quantidade |
| `select` | Dropdown (1 opção) | Status, tipo de problema |
| `radio` | Opções exclusivas | Sim/Não, urgência |
| `checkbox` | Múltiplas escolhas | Sintomas, acessos necessários |

## Exemplo Prático: Computador Não Liga

### ❌ **Método Antigo (Texto com [campos])**

```
Meu computador não está ligando.

Detalhes:
- Local: [Informe seu setor/sala]
- Patrimônio: [Se souber o número]
- Observações: [Descreva outros sintomas]
```

**Usuário precisava:**
1. Ler tudo
2. Deletar cada `[texto]`
3. Digitar em cada lugar
4. Risco de esquecer campos

---

### ✅ **Método Novo (Formulário Estruturado)**

**Campos definidos:**

```dart
'campos': [
  {
    'id': 'local',
    'label': 'Local do computador',
    'type': 'text',
    'required': true,
    'placeholder': 'Ex: Financeiro - Sala 12'
  },
  {
    'id': 'patrimonio',
    'label': 'Número de patrimônio',
    'type': 'text',
    'required': false,
    'placeholder': 'Ex: PC-1234'
  },
  {
    'id': 'conectado',
    'label': 'Está conectado na tomada?',
    'type': 'radio',
    'required': true,
    'options': ['Sim', 'Não', 'Não sei']
  },
  {
    'id': 'sintomas',
    'label': 'Sintomas adicionais',
    'type': 'checkbox',
    'required': false,
    'options': [
      'LED frontal aceso',
      'Ventilador funciona',
      'Faz barulho ao ligar',
      'Cheiro de queimado'
    ]
  },
  {
    'id': 'observacoes',
    'label': 'Observações adicionais',
    'type': 'multiline',
    'required': false,
    'placeholder': 'Descreva outros detalhes relevantes...'
  }
]
```

**Resultado para o usuário:**

```
┌─────────────────────────────────────┐
│ Local do computador *               │
│ [Financeiro - Sala 12_________]     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Número de patrimônio                │
│ [PC-1234______________________]     │
└─────────────────────────────────────┘

Está conectado na tomada? *
( ) Sim  (●) Não  ( ) Não sei

Sintomas adicionais:
☐ LED frontal aceso
☑ Ventilador funciona
☐ Faz barulho ao ligar
☐ Cheiro de queimado

┌─────────────────────────────────────┐
│ Observações adicionais              │
│ [Começou hoje de manhã________]     │
│ [____________________________]      │
│ [____________________________]      │
└─────────────────────────────────────┘

    [✓ Criar Chamado]
```

## Como Adicionar Campos aos Templates

### Método 1: Direto no Firestore (Manual)

1. Abra o **Firebase Console**
2. Vá em **Firestore Database**
3. Collection `templates` → Selecione um documento
4. Adicione um campo `campos` (tipo **array**)
5. Adicione objetos com a estrutura:

```json
{
  "id": "local",
  "label": "Local",
  "type": "text",
  "required": true,
  "placeholder": "Ex: Sala 12"
}
```

### Método 2: Via Código (Seed Atualizado)

Edite `lib/utils/seed_templates.dart` e adicione `campos` aos templates:

```dart
{
  'titulo': '🖥️ Computador não liga',
  'descricaoModelo': 'Chamado sobre computador que não liga',
  'setor': 'TI',
  'tipo': 'Chamado',
  'prioridade': 3,
  'tags': ['hardware', 'computador', 'urgente'],
  'ativo': true,
  'dataCriacao': FieldValue.serverTimestamp(),
  'campos': [
    {
      'id': 'local',
      'label': 'Local do computador',
      'type': 'text',
      'required': true,
      'placeholder': 'Ex: Financeiro - Sala 12'
    },
    {
      'id': 'patrimonio',
      'label': 'Número de patrimônio',
      'type': 'text',
      'required': false,
      'placeholder': 'Ex: PC-1234'
    },
    {
      'id': 'conectado',
      'label': 'Está conectado na tomada?',
      'type': 'radio',
      'required': true,
      'options': ['Sim', 'Não', 'Não sei']
    },
    {
      'id': 'observacoes',
      'label': 'Observações',
      'type': 'multiline',
      'required': false,
      'placeholder': 'Descreva detalhes...'
    }
  ]
},
```

## Estrutura de um Campo

### Propriedades Obrigatórias

```dart
{
  'id': 'nome_unico',      // ID único do campo (sem espaços)
  'label': 'Texto visível', // O que o usuário vê
  'type': 'text',           // Tipo do campo (ver tipos acima)
}
```

### Propriedades Opcionais

```dart
{
  'required': true,                    // Obrigatório? (default: false)
  'placeholder': 'Texto de exemplo',   // Texto de ajuda
  'defaultValue': 'Valor inicial',     // Valor pré-preenchido
  'options': ['Op1', 'Op2', 'Op3']     // Para select, radio, checkbox
}
```

## Exemplos Completos por Tipo de Problema

### 🌐 **Sem Internet**

```dart
'campos': [
  {
    'id': 'tipo_conexao',
    'label': 'Tipo de conexão',
    'type': 'radio',
    'required': true,
    'options': ['Cabo de rede', 'WiFi']
  },
  {
    'id': 'local',
    'label': 'Local',
    'type': 'text',
    'required': true,
    'placeholder': 'Setor e sala'
  },
  {
    'id': 'outros_funcionam',
    'label': 'Outros computadores no setor funcionam?',
    'type': 'select',
    'required': true,
    'options': ['Sim', 'Não', 'Não sei', 'Sou o único computador']
  },
  {
    'id': 'icone_rede',
    'label': 'Ícone de rede na bandeja',
    'type': 'select',
    'options': ['X vermelho', 'Triângulo amarelo', 'Normal', 'Não aparece']
  }
]
```

### 🖨️ **Impressora Não Imprime**

```dart
'campos': [
  {
    'id': 'impressora',
    'label': 'Nome ou modelo da impressora',
    'type': 'text',
    'required': true,
    'placeholder': 'Ex: HP LaserJet Sala 10'
  },
  {
    'id': 'ligada',
    'label': 'A impressora está ligada?',
    'type': 'radio',
    'required': true,
    'options': ['Sim', 'Não']
  },
  {
    'id': 'mensagem_erro',
    'label': 'Mostra alguma mensagem de erro?',
    'type': 'multiline',
    'placeholder': 'Descreva a mensagem exibida...'
  },
  {
    'id': 'onde_trava',
    'label': 'Onde o documento trava?',
    'type': 'select',
    'options': [
      'Não sai da fila de impressão',
      'Fica "Processando"',
      'Sai da fila mas não imprime',
      'Não aparece na lista de impressoras'
    ]
  }
]
```

### 📧 **Email Não Envia/Recebe**

```dart
'campos': [
  {
    'id': 'seu_email',
    'label': 'Seu email',
    'type': 'text',
    'required': true,
    'placeholder': 'nome@empresa.com'
  },
  {
    'id': 'problemas',
    'label': 'Qual o problema?',
    'type': 'checkbox',
    'required': true,
    'options': [
      'Não consigo enviar emails',
      'Não estou recebendo emails',
      'Emails ficam na caixa de saída',
      'Mensagem de erro ao enviar'
    ]
  },
  {
    'id': 'mensagem_erro',
    'label': 'Mensagem de erro (se houver)',
    'type': 'multiline',
    'placeholder': 'Copie a mensagem de erro aqui...'
  },
  {
    'id': 'acesso',
    'label': 'Como você acessa o email?',
    'type': 'radio',
    'required': true,
    'options': ['Outlook (desktop)', 'Webmail (navegador)', 'Celular']
  }
]
```

### 💻 **Instalação de Software**

```dart
'campos': [
  {
    'id': 'software',
    'label': 'Nome do software',
    'type': 'text',
    'required': true,
    'placeholder': 'Ex: Adobe Acrobat, AutoCAD'
  },
  {
    'id': 'versao',
    'label': 'Versão específica (se souber)',
    'type': 'text',
    'placeholder': 'Ex: 2024, versão 10.5'
  },
  {
    'id': 'motivo',
    'label': 'Motivo da necessidade',
    'type': 'multiline',
    'required': true,
    'placeholder': 'Descreva por que precisa deste software...'
  },
  {
    'id': 'urgencia',
    'label': 'Urgência',
    'type': 'select',
    'required': true,
    'options': ['Urgente (hoje)', 'Alta (esta semana)', 'Normal (sem pressa)']
  },
  {
    'id': 'ja_usou',
    'label': 'Já utilizou este software antes?',
    'type': 'radio',
    'options': ['Sim', 'Não, preciso de treinamento']
  }
]
```

## Vantagens do Sistema

### Para o Usuário:
✅ **5x mais rápido** que preencher texto manualmente
✅ **Impossível esquecer campos** - validação automática
✅ **Interface limpa** - cada campo em sua caixa
✅ **Opções predefinidas** - sem erros de digitação
✅ **Mobile-friendly** - funciona perfeitamente no celular

### Para o TI:
✅ **Informações estruturadas** - sempre no mesmo formato
✅ **Dados completos** - campos obrigatórios garantidos
✅ **Fácil de filtrar** - informações organizadas
✅ **Menos idas e vindas** - tudo informado de primeira
✅ **Análise facilitada** - padrão consistente

## Migração Gradual

Você **NÃO precisa** converter todos os templates de uma vez:

1. **Templates SEM `campos`** → Usam formulário tradicional (texto livre)
2. **Templates COM `campos`** → Usam formulário dinâmico estruturado

Ambos funcionam simultaneamente! Converta conforme necessidade.

## Exemplo de Conversão

### Template Antigo (Só Texto)

```dart
{
  'titulo': '🖥️ Computador não liga',
  'descricaoModelo': 'Meu computador não liga.\n\nLocal: [digite]\nPatrimônio: [digite]',
  'tipo': 'Chamado',
  // ...
}
```

### Template Novo (Com Campos)

```dart
{
  'titulo': '🖥️ Computador não liga',
  'descricaoModelo': 'Computador com problema de inicialização',
  'tipo': 'Chamado',
  // ...
  'campos': [
    {'id': 'local', 'label': 'Local', 'type': 'text', 'required': true},
    {'id': 'patrimonio', 'label': 'Patrimônio', 'type': 'text'},
  ]
}
```

## Fluxo Completo

```
Usuário clica "Novo Chamado"
         ↓
Escolhe "Usar Template"
         ↓
Ve lista de templates
         ↓
Seleciona "🖥️ Computador não liga"
         ↓
Sistema verifica: template.campos != null?
         ↓
   SIM                    NÃO
    ↓                      ↓
Abre TemplateForm    Abre NewTicketForm
(formulário dinâmico) (texto tradicional)
    ↓                      ↓
Preenche campos      Edita texto
    ↓                      ↓
Valida automaticamente    Manual
    ↓                      ↓
  [Criar Chamado]    [Criar Chamado]
```

## Próximos Passos

1. ✅ Sistema criado e funcionando
2. 🔄 **Converta 2-3 templates mais usados** primeiro
3. 📊 Colete feedback dos usuários
4. 🚀 Converta resto dos templates aos poucos
5. 📈 Analise métricas de velocidade de criação

---

**Resultado Final**: Templates que realmente **economizam tempo** ao invés de serem apenas "pré-fills" de texto! 🎉
