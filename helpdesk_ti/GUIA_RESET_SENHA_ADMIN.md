# 🔐 Sistema de Reset de Senha - Admin

## ✅ O que foi implementado

Admin pode resetar a senha de qualquer usuário diretamente na tela de Gerenciamento de Usuários.

### Como funciona:

1. **Admin acessa** "Gerenciar Usuários"
2. **Clica** no botão "Resetar Senha" ao lado do usuário
3. **Define** nova senha (mínimo 6 caracteres)
4. **Senha é atualizada** imediatamente no Firebase Auth
5. **Usuário pode logar** com a nova senha

---

## 📦 Instalação (Execute estes comandos)

### Passo 1: Instalar pacote Flutter
```powershell
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti
flutter pub get
```

### Passo 2: Deploy da Cloud Function
```powershell
cd C:\Users\User\Desktop\PROJETOS\helpdesk_ti\functions
firebase deploy --only functions:resetUserPassword
```

**Aguarde**: O deploy leva 1-2 minutos

---

## 🎯 Como usar

### 1. Resetar Senha de um Usuário

1. Faça login como **Admin**
2. Menu > **Gerenciar Usuários**
3. Encontre o usuário na lista
4. Clique no botão **laranja "Resetar Senha"**
5. Digite a nova senha (mínimo 6 caracteres)
6. Clique em **Confirmar**

### 2. Informar ao Usuário

Após resetar, informe ao usuário:
- ✅ "Sua senha foi alterada"
- ✅ "Nova senha: [a senha que você definiu]"
- ✅ "Use ela para fazer login"

---

## 🔒 Segurança

- ✅ Apenas **Admins** podem resetar senhas
- ✅ Validação de autenticação
- ✅ Validação de permissões
- ✅ Senha mínima de 6 caracteres
- ✅ Atualização direta no Firebase Auth
- ✅ Sem armazenamento de senha temporária

---

## 🧪 Testar

1. Crie um usuário de teste
2. Anote o email: `teste.usuario@helpdesk.com`
3. Senha inicial: `123456`
4. Faça login com essa conta
5. Saia (logout)
6. Entre como Admin
7. Resetar senha do usuário de teste para: `novaSenha123`
8. Saia (logout)
9. Tente login com `teste.usuario@helpdesk.com` e senha `123456` → ❌ Falha
10. Tente login com `teste.usuario@helpdesk.com` e senha `novaSenha123` → ✅ Sucesso!

---

## ❓ FAQ

**P: E se o usuário esquecer a senha?**
R: Entre em contato com você (Admin) que reseta manualmente

**P: Preciso resetar toda vez?**
R: Não, o usuário pode trocar a senha sozinho depois de logar

**P: Funciona offline?**
R: Não, precisa de internet para chamar a Cloud Function

**P: Posso resetar minha própria senha?**
R: Sim, mas é melhor usar "Esqueci minha senha" no login

**P: Tem limite de resets?**
R: Não, pode resetar quantas vezes quiser

**P: A senha expira?**
R: Não, a senha vale até o próximo reset

---

## 🚀 Próximos Passos

Depois de testar, você pode:

1. ✅ Remover a feature de "Esqueci senha" do LoginScreen (não funciona sem email real)
2. ✅ Adicionar log de resets de senha no Firestore (auditoria)
3. ✅ Enviar notificação ao usuário quando senha for resetada
4. ✅ Adicionar opção "Gerar senha aleatória" no diálogo

Quer que eu implemente alguma dessas melhorias?
