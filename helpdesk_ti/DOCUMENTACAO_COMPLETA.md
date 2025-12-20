# 📚 DOCUMENTAÇÃO COMPLETA - Sistema HelpDesk TI

> **Versão:** 1.0.0  
> **Última Atualização:** 25/11/2025  
> **Status:** ✅ Produção

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Início Rápido](#início-rápido)
3. [Arquitetura](#arquitetura)
4. [Funcionalidades](#funcionalidades)
5. [Configuração Firebase](#configuração-firebase)
6. [Notificações Push](#notificações-push)
7. [Permissões e Roles](#permissões-e-roles)
8. [Guia de Desenvolvimento](#guia-de-desenvolvimento)
9. [FAQ e Troubleshooting](#faq-e-troubleshooting)

---

## 🎯 Visão Geral

Sistema de gerenciamento de chamados técnicos desenvolvido em Flutter com Firebase, permitindo que usuários criem solicitações e chamados de serviço, e que a equipe de TI gerencie o atendimento.

### Tecnologias Principais

- **Flutter** 3.x
- **Firebase**:
  - Authentication
  - Firestore Database
  - Cloud Storage
  - Cloud Messaging (FCM)
- **Provider** (Gerenciamento de estado)
- **flutter_local_notifications** (Notificações locais)

### Principais Características

✅ Autenticação com Firebase Auth  
✅ Criação de chamados (Serviço e Solicitação)  
✅ Sistema de aprovação de solicitações  
✅ Fila técnica para equipe TI  
✅ Notificações push em tempo real  
✅ Comentários e atualizações em chamados  
✅ Sistema de avaliação de atendimento  
✅ Templates de chamados  
✅ Upload de anexos (imagens)  
✅ Priorização de chamados  

---

## 🚀 Início Rápido

### Pré-requisitos

```powershell
# Verificar instalações
flutter --version  # Flutter 3.x
java -version      # Java 17+
```

### Instalação

```powershell
# 1. Clonar repositório
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti

# 2. Instalar dependências
flutter pub get

# 3. Compilar APK
flutter build apk --release

# 4. Instalar no dispositivo
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Criar Primeiro Usuário

**Via Firebase Console:**

1. Acesse Firebase Console → Authentication
2. Adicione usuário com email/senha
3. Vá em Firestore → Collection `users`
4. Crie documento com ID igual ao UID do usuário:

```javascript
{
  nome: "Admin Sistema",
  email: "admin@helpdesk.com",
  role: "admin",  // ou "user", "manager"
  criadoEm: Timestamp.now(),
  fcmTokens: {}
}
```

---

## 🏗️ Arquitetura

### Estrutura de Pastas

```
lib/
├── core/                    # Configurações e utilitários
│   ├── app_colors.dart     # Paleta de cores
│   └── permissions/        # Sistema de permissões
├── data/                    # Camada de dados
│   ├── auth_service.dart   # Autenticação
│   ├── firestore_service.dart  # Fachada principal
│   └── services/           # Serviços especializados
│       ├── chamado_service.dart
│       ├── solicitacao_service.dart
│       ├── avaliacao_service.dart
│       └── template_service.dart
├── models/                  # Modelos de dados
│   ├── chamado.dart
│   ├── solicitacao.dart
│   ├── avaliacao.dart
│   ├── comentario.dart
│   └── chamado_template.dart
├── screens/                 # Telas
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── new_ticket_screen.dart
│   ├── ticket_details_screen.dart
│   ├── tabs/               # Abas da home
│   └── chamado/            # Telas de chamados
├── services/                # Serviços externos
│   └── notification_service.dart  # FCM e notificações
└── widgets/                 # Componentes reutilizáveis
    ├── ticket_card.dart
    ├── solicitacao_card.dart
    └── chamado/
        └── timeline_widget.dart
```

### Padrão Arquitetural

**Serviços → Fachada → Telas**

```
┌─────────────┐
│   Screens   │
└──────┬──────┘
       │ Provider
┌──────▼──────────────┐
│ FirestoreService    │ (Fachada)
└──────┬──────────────┘
       │ Delega
┌──────▼──────────────┐
│ Serviços Específicos│
│ - ChamadoService    │
│ - SolicitacaoService│
│ - AvaliacaoService  │
│ - TemplateService   │
└─────────────────────┘
```

---

## ⚙️ Funcionalidades

### Para Usuários Comuns (role: 'user')

#### 1. Criar Chamados
- **Serviço**: Chamado técnico direto (vai para fila TI)
- **Solicitação**: Requer aprovação do gerente antes de virar chamado

#### 2. Visualizar Chamados
- Aba "Meus Chamados"
- Clicar para ver detalhes completos
- Acompanhar status em tempo real

#### 3. Comentar em Chamados
- Adicionar comentários e atualizações
- Ver histórico completo de interações
- Timeline com identificação de autor

#### 4. Avaliar Atendimento
- Avaliar chamados fechados com estrelas (1-5)
- Adicionar comentário opcional
- Feedback para melhoria do serviço

### Para Gerentes (role: 'manager')

Todas as permissões de usuário comum, mais:

#### 5. Aprovar/Rejeitar Solicitações
- Aba "Aprovar Solicitações"
- Ver detalhes antes de decidir
- Motivo de rejeição obrigatório

#### 6. Visualizar Histórico
- Ver todas as solicitações (pendentes, aprovadas, rejeitadas)

### Para Administradores/TI (role: 'admin')

Todas as permissões anteriores, mais:

#### 7. Fila Técnica
- Ver todos os chamados do sistema
- Aceitar chamados para trabalhar
- Atualizar status (Aberto → Em Andamento → Fechado)
- Rejeitar chamados com motivo

#### 8. Gerenciar Prioridade
- Alterar prioridade de chamados (1-4)
- 1=Baixa, 2=Média, 3=Alta, 4=Crítica

#### 9. Ferramentas Admin
- Limpar todos os chamados (desenvolvimento)
- Ver estatísticas
- Debug e logs

---

## 🔥 Configuração Firebase

### Coleções do Firestore

#### `users`
```javascript
{
  nome: string,
  email: string,
  role: "user" | "manager" | "admin",
  criadoEm: Timestamp,
  fcmTokens: {
    [tokenId]: Timestamp  // Timestamp quando foi registrado
  }
}
```

#### `tickets` (Chamados)
```javascript
{
  numero: int,              // Número sequencial (#0001)
  titulo: string,
  descricao: string,
  setor: string,
  tipo: "Solicitação" | "Serviço",
  status: "Aberto" | "Em Andamento" | "Fechado" | "Rejeitado",
  usuarioId: string,        // UID do criador
  usuarioNome: string,
  adminId: string?,         // UID do TI responsável
  adminNome: string?,
  linkOuEspecificacao: string?,
  anexos: string[],         // URLs do Storage
  custoEstimado: double?,
  dataCriacao: Timestamp,
  dataAtualizacao: Timestamp?,
  dataFechamento: Timestamp?,
  motivoRejeicao: string?,
  prioridade: int          // 1-4
}
```

#### `comentarios`
```javascript
{
  chamadoId: string,
  autorId: string,
  autorNome: string,
  autorRole: "user" | "admin",
  mensagem: string,
  dataHora: Timestamp,
  tipo: "comentario" | "atualizacao" | "mudanca_status"
}
```

#### `solicitacoes`
```javascript
{
  titulo: string,
  descricao: string,
  itemSolicitado: string,
  justificativa: string,
  custoEstimado: double?,
  setor: string,
  usuarioId: string,
  usuarioNome: string,
  managerId: string?,
  managerNome: string?,
  status: "Pendente" | "Aprovado" | "Rejeitado",
  dataCriacao: Timestamp,
  dataAtualizacao: Timestamp?,
  motivoRejeicao: string?,
  prioridade: int
}
```

#### `avaliacoes`
```javascript
{
  chamadoId: string,
  usuarioId: string,
  usuarioNome: string,
  adminId: string?,
  adminNome: string?,
  nota: int,               // 1-5 estrelas
  descricao: string,       // "Péssimo", "Ruim", "Regular", "Bom", "Excelente"
  comentario: string?,
  dataCriacao: Timestamp
}
```

#### `notifications`
```javascript
{
  userId: string,
  userName: string?,
  title: string,
  body: string,
  data: object,
  read: boolean,
  timestamp: Timestamp
}
```

#### `templates`
```javascript
{
  titulo: string,
  descricao: string,
  categoria: string,
  tags: string[],
  prioridadePadrao: int,
  ativo: boolean,
  criadoEm: Timestamp
}
```

### Índices Necessários

No Firestore Console, criar os seguintes índices compostos:

1. **tickets**: `usuarioId` (ASC) + `dataCriacao` (DESC)
2. **comentarios**: `chamadoId` (ASC) + `dataHora` (ASC)
3. **notifications**: `userId` (ASC) + `read` (ASC) + `timestamp` (DESC)

---

## 🔔 Notificações Push

### Solução Implementada: Firestore + Notificações Locais

O sistema utiliza uma solução **100% gratuita** sem necessidade de servidor HTTP ou Cloud Functions:

#### Como Funciona

1. **Salvar FCM Token**
   - Ao fazer login, o app salva o token FCM no Firestore
   - Documento `users/{uid}` → campo `fcmTokens`

2. **Enviar Notificação**
   - Criar documento na coleção `notifications`:
   ```javascript
   {
     userId: "destinatarioUID",
     title: "Novo Chamado",
     body: "João criou um chamado",
     data: { tipo: "novo_chamado", chamadoId: "..." },
     read: false,
     timestamp: Timestamp.now()
   }
   ```

3. **Receber Notificação**
   - App mantém listener no Firestore:
     ```dart
     .collection('notifications')
     .where('userId', isEqualTo: myUid)
     .where('read', isEqualTo: false)
     .snapshots()
     ```
   - Quando novo documento é detectado, exibe notificação local

4. **Marcar como Lida**
   - Após exibir, atualiza `read: true`

### Configuração Android

**AndroidManifest.xml:**
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="helpdesk_channel" />
```

**android/app/build.gradle:**
```gradle
android {
    defaultConfig {
        compileSdk = 34
        minSdk = 21
        
        compileOptions {
            coreLibraryDesugaringEnabled true
        }
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

### Eventos que Geram Notificações

- ✅ Novo chamado criado → Notifica admins/TI
- ✅ Chamado aceito → Notifica usuário
- ✅ Status alterado → Notifica usuário
- ✅ Novo comentário → Notifica envolvidos
- ✅ Solicitação aprovada/rejeitada → Notifica usuário

---

## 👥 Permissões e Roles

### Hierarquia

```
admin > manager > user
```

### Tabela de Permissões

| Funcionalidade | user | manager | admin |
|---|:---:|:---:|:---:|
| Criar chamado de serviço | ✅ | ✅ | ✅ |
| Criar solicitação | ✅ | ✅ | ✅ |
| Ver meus chamados | ✅ | ✅ | ✅ |
| Comentar em meus chamados | ✅ | ✅ | ✅ |
| Avaliar atendimento | ✅ | ✅ | ✅ |
| Aprovar/rejeitar solicitações | ❌ | ✅ | ✅ |
| Ver fila técnica | ❌ | ❌ | ✅ |
| Aceitar/rejeitar chamados | ❌ | ❌ | ✅ |
| Alterar status | ❌ | ❌ | ✅ |
| Alterar prioridade | ❌ | ❌ | ✅ |
| Ferramentas debug | ❌ | ❌ | ✅ |

### Implementação

**Arquivo:** `lib/core/permissions/user_permissions.dart`

```dart
class UserPermissions {
  final String role;
  
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || isAdmin;
  bool get isUser => role == 'user' || isManager;
  
  bool get canViewFilaTecnica => isAdmin;
  bool get canAprovarSolicitacoes => isManager;
  // ...
}
```

---

## 💻 Guia de Desenvolvimento

### Adicionar Nova Funcionalidade

#### 1. Criar Modelo (se necessário)
```dart
// lib/models/nova_entidade.dart
class NovaEntidade {
  final String id;
  final String nome;
  
  NovaEntidade({required this.id, required this.nome});
  
  factory NovaEntidade.fromMap(Map<String, dynamic> map, String id) {
    return NovaEntidade(
      id: id,
      nome: map['nome'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {'nome': nome};
  }
}
```

#### 2. Criar Serviço
```dart
// lib/data/services/nova_entidade_service.dart
class NovaEntidadeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<String> criar(NovaEntidade entidade) async {
    final doc = await _firestore.collection('novas_entidades')
        .add(entidade.toMap());
    return doc.id;
  }
  
  Stream<List<NovaEntidade>> getStream() {
    return _firestore.collection('novas_entidades')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NovaEntidade.fromMap(doc.data(), doc.id))
            .toList());
  }
}
```

#### 3. Adicionar na Fachada
```dart
// lib/data/firestore_service.dart
class FirestoreService {
  final NovaEntidadeService _novaEntidadeService = NovaEntidadeService();
  
  Future<String> criarNovaEntidade(NovaEntidade entidade) =>
      _novaEntidadeService.criar(entidade);
      
  Stream<List<NovaEntidade>> getNovasEntidadesStream() =>
      _novaEntidadeService.getStream();
}
```

#### 4. Criar Tela
```dart
// lib/screens/nova_entidade_screen.dart
class NovaEntidadeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    
    return StreamBuilder<List<NovaEntidade>>(
      stream: firestoreService.getNovasEntidadesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        return ListView(
          children: snapshot.data!.map((e) => 
            ListTile(title: Text(e.nome))
          ).toList(),
        );
      },
    );
  }
}
```

### Boas Práticas

#### ✅ FAZER

- Usar Provider para injeção de dependências
- Validar dados antes de salvar no Firestore
- Adicionar try-catch em operações assíncronas
- Usar `mounted` antes de chamar `setState`
- Documentar funções públicas
- Usar const sempre que possível

#### ❌ NÃO FAZER

- Acessar Firestore diretamente das telas
- Deixar prints de debug excessivos em produção
- Usar `!` (bang operator) sem verificação
- Fazer múltiplas queries quando uma serve
- Esquecer de fazer dispose de controllers

### Debug

#### Ver Logs em Tempo Real
```powershell
flutter logs | Select-String "🔥|✅|❌|📱|🎫"
```

#### Logs Importantes
- `🔥` = Início de operação
- `✅` = Sucesso
- `❌` = Erro
- `📱` = Stream/Listener
- `🎫` = Chamado/Ticket

---

## ❓ FAQ e Troubleshooting

### Chamados não aparecem para usuário

**Problema:** Usuário cria chamado mas não aparece na lista

**Causa:** Campo `usuarioId` com email ao invés de UID

**Solução:** Verificar que está usando `authService.firebaseUser?.uid`

---

### Notificações não funcionam

**Problema:** App não recebe notificações

**Diagnóstico:**
1. Verificar se token FCM foi salvo: Firestore → `users/{uid}/fcmTokens`
2. Verificar se listener está rodando: ver logs `📱 Notificação em foreground`
3. Verificar permissões Android

**Solução:** Reinstalar app e fazer login novamente

---

### Erro "requires an index"

**Problema:** Query do Firestore falha pedindo índice

**Solução:** 
1. Copiar link do erro no console
2. Colar no navegador
3. Firebase cria índice automaticamente
4. Aguardar 2-5 minutos

---

### Build falha no Android

**Problema:** `Execution failed for task ':app:minifyReleaseWithR8'`

**Solução:**
```powershell
flutter clean
cd android
./gradlew clean
cd ..
flutter build apk --release
```

---

### App trava ao abrir tela

**Problema:** App congela em tela específica

**Diagnóstico:** Ver logs para identificar erro

**Soluções comuns:**
- Verificar se todos os campos obrigatórios existem no Firestore
- Verificar se StreamBuilder tem tratamento de erro
- Adicionar loading state

---

## 📝 Changelog

### Versão 1.0.0 (25/11/2025)

✅ Sistema de notificações funcionando com Firestore  
✅ Usuários comuns podem ver detalhes e comentar em chamados  
✅ Tratamento robusto de erros em streams  
✅ Proteção contra overflow em cards  
✅ Logs de debug organizados  
✅ Documentação consolidada  

### Melhorias Planejadas

- [ ] Recuperação de senha
- [ ] Filtros avançados na fila técnica
- [ ] Relatórios e dashboards
- [ ] Suporte a vídeos nos anexos
- [ ] Chat em tempo real
- [ ] Notificações por email

---

## 🤝 Contribuindo

Para contribuir com o projeto:

1. Mantenha o padrão de código existente
2. Adicione testes quando possível
3. Documente funções públicas
4. Atualize este arquivo se necessário

---

## 📧 Contato e Suporte

Para dúvidas ou suporte:
- Documentação: Este arquivo
- Debug: Ver seção FAQ

---

**Desenvolvido com ❤️ usando Flutter e Firebase**
