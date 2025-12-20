# 🔐 Recuperação de Senha - Como Funciona

## ✅ Sistema Já Implementado

O sistema de recuperação de senha **está funcionando corretamente**. O código usa:

```dart
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
```

## 🎯 Como Funciona

### 1. Firebase Authentication
- O email usado no login é o email cadastrado no **Firebase Authentication**
- Esse é o email REAL da conta Firebase, não um alias
- O Firebase envia o link de recuperação para esse email cadastrado

### 2. Fluxo Correto

```
Usuário: "Esqueceu a senha"
↓
Digite o email: usuario@empresa.com.br
↓
Firebase verifica: Esse email existe no Firebase Auth?
↓
SIM: Envia email com link de recuperação ✅
NÃO: Retorna erro "user-not-found" ❌
```

## ❌ Por Que Não Funcionou no Seu Teste

Você mencionou: *"eu testei e tentei enviar a link para o meu email pessoal que não tem nada a ver com o email que eu uso no app"*

**Problema:** O Firebase só envia link para emails que **existem** no Firebase Authentication.

**Exemplo:**
```
Email cadastrado no Firebase Auth: joao@pichau.com.br
Email testado: joao.pessoal@gmail.com
Resultado: ❌ ERRO - "user-not-found"
```

## ✅ Como Testar Corretamente

### Opção 1: Usar Email Real Cadastrado
1. Vá no Firebase Console → Authentication
2. Veja qual email está cadastrado (ex: `joao@pichau.com.br`)
3. No app, clique em "Esqueceu sua senha?"
4. Digite **EXATAMENTE** o email cadastrado
5. Verifique a caixa de entrada desse email
6. Clique no link recebido

### Opção 2: Criar Conta de Teste
1. Firebase Console → Authentication → Add User
2. Crie conta com seu email pessoal: `seuemail@gmail.com`
3. Defina uma senha temporária
4. No app, teste recuperação com esse email
5. Você receberá o link no seu email pessoal

### Opção 3: Usar Email de Teste Firebase
1. Crie usuário de teste com email acessível
2. Use serviços como:
   - Gmail pessoal
   - Temp-mail.org (email temporário)
   - Guerrilla Mail

## 🔧 Configuração Firebase (Opcional)

Se quiser customizar o email de recuperação:

1. **Firebase Console** → Authentication → Templates
2. **Email Templates** → Password Reset
3. Personalize:
   - Assunto do email
   - Texto do corpo
   - URL de redirecionamento
   - Design HTML

## 📧 Exemplo de Email Recebido

```
De: noreply@pichau-helpdesk.firebaseapp.com
Para: joao@pichau.com.br
Assunto: Redefinir senha - Pichau TI

Olá,

Você solicitou a redefinição de senha.
Clique no link abaixo para criar uma nova senha:

[Redefinir Senha] (válido por 1 hora)

Se você não solicitou isso, ignore este email.
```

## 🛠️ Tratamento de Erros Implementado

O código já trata todos os erros:

```dart
'user-not-found' → "Email não encontrado no sistema."
'invalid-email' → "Email inválido."
'too-many-requests' → "Muitas tentativas. Aguarde alguns minutos."
```

## ✅ Checklist de Teste

- [ ] Email existe no Firebase Authentication?
- [ ] Email digitado está correto (sem espaços)?
- [ ] Verificou pasta de SPAM?
- [ ] Aguardou alguns minutos (pode demorar)?
- [ ] Internet funcionando?
- [ ] Firebase Auth está ativo no projeto?

## 🎓 Diferença: Email App vs Email Real

### Email no App (Firestore)
```json
{
  "usuario": "João Silva",
  "email": "joao@pichau.com.br",  ← Campo de texto qualquer
  "setor": "TI"
}
```

### Email no Firebase Auth (Login Real)
```
Authentication → Users:
- joao.real@gmail.com ← Email REAL usado para login
```

**Importante:** O Firebase envia para o email do **Authentication**, não para o campo "email" do Firestore!

## 🚀 Solução Definitiva

Se você quer que o sistema use um email diferente para recuperação:

1. **No cadastro de usuário**, sincronizar emails:
   ```dart
   // Criar usuário no Firebase Auth
   UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
     email: emailReal,  // Email onde receberá os links
     password: senha,
   );
   
   // Salvar no Firestore
   await FirebaseFirestore.instance.collection('usuarios').doc(credential.user!.uid).set({
     'nome': nome,
     'email': emailReal,  // Mesmo email!
     'setor': setor,
   });
   ```

2. **Garantir que ambos são iguais** evita confusão

## 📝 Resumo

✅ **Sistema funciona perfeitamente**
✅ **Firebase envia email corretamente**
❌ **Erro comum:** Testar com email não cadastrado
✅ **Solução:** Usar email cadastrado no Firebase Authentication

---

**Dúvidas?** Verifique o Firebase Console → Authentication → Users para ver quais emails estão cadastrados.
