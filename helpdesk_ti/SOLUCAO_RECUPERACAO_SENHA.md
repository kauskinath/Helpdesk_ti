# 🔐 Solução de Recuperação de Senha - HelpDesk TI

## 📋 Problema Atual

**Situação:**
- Usuários têm emails alias: `joao.silva@helpdesk.com`
- Esses emails NÃO existem como contas reais
- Firebase Auth envia email de recuperação para `@helpdesk.com`
- Email nunca é recebido = recuperação não funciona

---

## ✅ Solução Implementada (Híbrida)

### **Abordagem: Email Real Opcional + Reset Manual**

#### 1. Adicionar Campo Email Real (Opcional)

**No cadastro de usuário (admin):**
```dart
// Firestore: users/{userId}
{
  "email": "joao.silva@helpdesk.com",        // Login (alias)
  "emailRecuperacao": "joao@pichau.com.br",  // Email real (opcional)
  "nome": "João Silva",
  "setor": "TI",
  "role": "user"
}
```

**Benefícios:**
- ✅ Recuperação automática funciona se usuário tiver email
- ✅ Usuários sem email corporativo ainda podem usar o sistema
- ✅ Admin pode resetar senha manualmente
- ✅ Não quebra sistema existente

---

### 2. Fluxo de Recuperação de Senha

#### **Opção A: Usuário tem Email Real**

```
1. Usuário clica "Esqueci minha senha"
2. Digite: joao.silva@helpdesk.com
3. Sistema busca no Firestore se tem emailRecuperacao
4. SE TEM: Envia link para joao@pichau.com.br
5. Usuário recebe email real e redefine senha
6. ✅ Recuperação automática
```

#### **Opção B: Usuário NÃO tem Email Real**

```
1. Usuário clica "Esqueci minha senha"
2. Digite: joao.silva@helpdesk.com
3. Sistema busca no Firestore - NÃO tem emailRecuperacao
4. Mostra mensagem: "Entre em contato com o administrador TI"
5. Admin vai em "Gerenciar Usuários" > Resetar Senha
6. ✅ Reset manual pelo admin
```

---

### 3. Implementação Prática

#### **Passo 1: Modificar Cadastro de Usuário**

**Adicionar campo opcional no formulário:**

```dart
// UserRegistrationScreen
final _emailRecuperacaoController = TextEditingController();

TextField(
  controller: _emailRecuperacaoController,
  decoration: InputDecoration(
    labelText: 'Email de Recuperação (Opcional)',
    hintText: 'joao@pichau.com.br',
    helperText: 'Email real para recuperar senha',
    prefixIcon: Icon(Icons.email),
  ),
)
```

**Salvar no Firestore:**

```dart
await FirebaseFirestore.instance
  .collection('users')
  .doc(userCredential.user!.uid)
  .set({
    'email': email,  // joao.silva@helpdesk.com
    'emailRecuperacao': _emailRecuperacaoController.text.trim().isNotEmpty
        ? _emailRecuperacaoController.text.trim()
        : null,  // Email real ou null
    'nome': nomeCompleto,
    'setor': _setorSelecionado,
    'role': _tipoUsuario,
  });
```

---

#### **Passo 2: Modificar Recuperação de Senha**

**No LoginScreen, modificar `_resetPassword`:**

```dart
Future<void> _resetPassword(String emailAlias) async {
  try {
    // 1. Buscar usuário no Firestore pelo email alias
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: emailAlias)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Usuário não encontrado');
    }

    final userData = querySnapshot.docs.first.data();
    final emailRecuperacao = userData['emailRecuperacao'];

    // 2. Se tem email real, usa ele
    if (emailRecuperacao != null && emailRecuperacao.isNotEmpty) {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailRecuperacao,
      );
      
      _showSuccessMessage(
        'Email de recuperação enviado para $emailRecuperacao! '
        'Verifique sua caixa de entrada.',
      );
    } 
    // 3. Se NÃO tem email real, instrui contatar admin
    else {
      _showWarningMessage(
        'Seu usuário não possui email de recuperação cadastrado. '
        'Entre em contato com o administrador TI para resetar sua senha.',
      );
    }
  } catch (e) {
    _showErrorMessage('Erro: $e');
  }
}
```

---

#### **Passo 3: Adicionar Reset Manual para Admins**

**Nova tela: Admin > Gerenciar Usuários > Resetar Senha**

```dart
// Botão "Resetar Senha" para cada usuário
Future<void> _resetarSenhaUsuario(String userId) async {
  final novaSenha = await _mostrarDialogoNovaSenha();
  
  if (novaSenha != null) {
    // Atualizar senha diretamente no Firebase Auth
    // (Requer Admin SDK ou Cloud Function)
    
    // OU criar senha temporária e forçar mudança no primeiro login
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
          'senhaTemporaria': novaSenha,
          'deveAlterarSenha': true,
        });
  }
}
```

---

## 🎯 Resultado Final

### **Para o Usuário:**

**Cenário 1: Tem email corporativo**
- ✅ Clica "Esqueci senha"
- ✅ Recebe email no Outlook/Gmail corporativo
- ✅ Clica no link e redefine
- ⏱️ **Tempo: 2 minutos**

**Cenário 2: NÃO tem email corporativo**
- ⚠️ Clica "Esqueci senha"
- 📞 Contata admin TI (WhatsApp/Ramal)
- ✅ Admin reseta senha em 30 segundos
- ⏱️ **Tempo: 5 minutos**

### **Para o Admin:**

**Opção 1: Cadastro com Email Real**
```
✅ Preenche formulário
✅ Adiciona email corporativo opcional
✅ Usuário pode recuperar sozinho
```

**Opção 2: Cadastro sem Email Real**
```
✅ Preenche formulário
⚠️ Não adiciona email
ℹ️ Admin precisará resetar se esquecer
```

---

## 🔄 Fluxograma Completo

```
┌─────────────────────────┐
│ Usuário Esqueceu Senha  │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Digite Email Alias      │
│ (joao.silva@help...)    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Buscar no Firestore     │
│ Campo: emailRecuperacao │
└───────────┬─────────────┘
            │
      ┌─────┴─────┐
      │           │
      ▼           ▼
┌─────────┐  ┌─────────┐
│ TEM     │  │ NÃO TEM │
│ Email   │  │ Email   │
└────┬────┘  └────┬────┘
     │            │
     ▼            ▼
┌─────────┐  ┌─────────┐
│ Envia   │  │ Mostra  │
│ Email   │  │ Aviso:  │
│ Real    │  │ Contate │
│         │  │ Admin   │
└────┬────┘  └────┬────┘
     │            │
     ▼            ▼
┌─────────┐  ┌─────────┐
│ ✅ OK   │  │ Admin   │
│         │  │ Reseta  │
│         │  │ Manual  │
└─────────┘  └─────────┘
```

---

## 📝 Checklist de Implementação

### **Fase 1: Básico (30 min)**
- [ ] Adicionar campo `emailRecuperacao` no cadastro
- [ ] Modificar tela de cadastro para incluir campo opcional
- [ ] Testar cadastro com e sem email real

### **Fase 2: Lógica (1h)**
- [ ] Modificar `_resetPassword` no LoginScreen
- [ ] Buscar email real no Firestore
- [ ] Implementar dois fluxos (com/sem email)
- [ ] Testar recuperação em ambos cenários

### **Fase 3: Admin Tools (1h)**
- [ ] Adicionar botão "Resetar Senha" em lista de usuários
- [ ] Criar diálogo para definir nova senha
- [ ] Implementar função de reset manual
- [ ] Testar reset pelo admin

### **Fase 4: Polimento (30 min)**
- [ ] Mensagens claras para o usuário
- [ ] Validação de email real no cadastro
- [ ] Documentação para admins
- [ ] Treinamento da equipe

---

## 🎓 Recomendações

1. **Email Corporativo**: Incentive cadastro com email real
2. **Padrão**: Use `@pichau.com.br` se disponível
3. **Alternativa**: Gmail/Outlook pessoal como fallback
4. **Admin**: Sempre pode resetar manualmente
5. **Auditoria**: Log de resets de senha

---

## ❓ FAQ

**P: E se mudar o email corporativo?**
R: Admin pode editar o campo `emailRecuperacao` na tela de gerenciar usuários

**P: Posso usar email pessoal?**
R: Sim, qualquer email real funciona (Gmail, Hotmail, etc.)

**P: E se não tiver nenhum email?**
R: Admin reseta manualmente em 30 segundos

**P: Precisa validar o email?**
R: Não obrigatório, mas recomendado enviar email de confirmação

**P: Funciona com todos os provedores?**
R: Sim, Firebase Auth envia para qualquer email válido

---

## 🚀 Próximos Passos

Quer que eu implemente essa solução agora? Vou:

1. ✅ Adicionar campo email real no cadastro
2. ✅ Modificar lógica de recuperação
3. ✅ Criar reset manual para admin
4. ✅ Testar todo o fluxo

**Basta confirmar e eu começo!** 💪
