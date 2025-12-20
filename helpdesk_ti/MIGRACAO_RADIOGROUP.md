# 📋 Guia de Migração: RadioListTile → RadioGroup

## 🎯 **Contexto**

A partir do **Flutter 3.35** (deprecated em 3.32), as propriedades `groupValue` e `onChanged` dos widgets `Radio` e `RadioListTile` foram depreciadas em favor do novo widget `RadioGroup`.

**Motivo**: Atender aos requisitos APG (ARIA Practices Guide) para navegação por teclado e propriedades semânticas em grupos de botões de rádio.

---

## 🔍 **Arquivos Afetados no Projeto**

### 1️⃣ `user_registration_screen.dart` (4 warnings)
- **Linhas 491-494**: RadioListTile "Usuário Comum"
- **Linhas 510-513**: RadioListTile "Administrador/TI"

### 2️⃣ `template_form_screen.dart` (2 warnings)
- **Linhas 549-551**: RadioListTile dinâmico em loop

---

## 📚 **Como Funciona a Nova API**

### ❌ **ANTES (Deprecated)**
```dart
RadioListTile<String>(
  title: const Text('Opção 1'),
  value: 'opcao1',
  groupValue: _tipoUsuario,  // ❌ Deprecated
  onChanged: (value) {        // ❌ Deprecated
    setState(() => _tipoUsuario = value!);
  },
)
```

### ✅ **DEPOIS (Correto)**
```dart
RadioGroup<String>(
  groupValue: _tipoUsuario,  // ✅ Centralizado no grupo
  onChanged: (value) {        // ✅ Centralizado no grupo
    setState(() => _tipoUsuario = value);
  },
  child: Column(
    children: [
      RadioListTile<String>(
        title: const Text('Opção 1'),
        value: 'opcao1',
        // Sem groupValue e onChanged!
      ),
    ],
  ),
)
```

---

## 🛠️ **Migração Passo a Passo**

### **Caso 1: user_registration_screen.dart**

#### **Código Atual (com warnings):**
```dart
// Linha 459 - Dentro do Container
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Tipo de Usuário',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 12),
    RadioListTile<String>(
      title: const Text(
        'Usuário Comum',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Pode criar chamados e solicitações',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
      value: 'user',
      groupValue: _tipoUsuario,  // ⚠️ Warning
      activeColor: Colors.blue,
      onChanged: (value) {        // ⚠️ Warning
        setState(() => _tipoUsuario = value!);
      },
    ),
    RadioListTile<String>(
      title: const Text(
        'Administrador/TI',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Acesso total ao sistema',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
      value: 'admin',
      groupValue: _tipoUsuario,  // ⚠️ Warning
      activeColor: Colors.blue,
      onChanged: (value) {        // ⚠️ Warning
        setState(() => _tipoUsuario = value!);
      },
    ),
  ],
),
```

#### **Código Migrado (sem warnings):**
```dart
// Linha 459 - Dentro do Container
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Tipo de Usuário',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 12),
    RadioGroup<String>(                    // ✅ Wrapper adicionado
      groupValue: _tipoUsuario,            // ✅ Movido para o grupo
      onChanged: (value) {                 // ✅ Movido para o grupo
        setState(() => _tipoUsuario = value);
      },
      child: Column(                       // ✅ Envolve os RadioListTile
        children: [
          RadioListTile<String>(
            title: const Text(
              'Usuário Comum',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Pode criar chamados e solicitações',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            value: 'user',
            activeColor: Colors.blue,
            // ✅ Sem groupValue e onChanged
          ),
          RadioListTile<String>(
            title: const Text(
              'Administrador/TI',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Acesso total ao sistema',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            value: 'admin',
            activeColor: Colors.blue,
            // ✅ Sem groupValue e onChanged
          ),
        ],
      ),
    ),
  ],
),
```

---

### **Caso 2: template_form_screen.dart**

#### **Código Atual (com warnings):**
```dart
// Linha 535 - Widget _buildRadioField
Widget _buildRadioField(TemplateCampo campo) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children:
          campo.options?.map((option) {
            return RadioListTile<String>(
              title: Text(
                option,
                style: const TextStyle(color: Colors.white),
              ),
              value: option,
              groupValue: _fieldValues[campo.id],  // ⚠️ Warning
              activeColor: AppColors.primary,
              onChanged: (value) {                 // ⚠️ Warning
                setState(() {
                  _fieldValues[campo.id] = value;
                });
              },
            );
          }).toList() ??
          [],
    ),
  );
}
```

#### **Código Migrado (sem warnings):**
```dart
// Linha 535 - Widget _buildRadioField
Widget _buildRadioField(TemplateCampo campo) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: RadioGroup<String>(               // ✅ Wrapper adicionado
      groupValue: _fieldValues[campo.id],    // ✅ Movido para o grupo
      onChanged: (value) {                   // ✅ Movido para o grupo
        setState(() {
          _fieldValues[campo.id] = value;
        });
      },
      child: Column(                         // ✅ Envolve os RadioListTile
        children:
            campo.options?.map((option) {
              return RadioListTile<String>(
                title: Text(
                  option,
                  style: const TextStyle(color: Colors.white),
                ),
                value: option,
                activeColor: AppColors.primary,
                // ✅ Sem groupValue e onChanged
              );
            }).toList() ??
            [],
      ),
    ),
  );
}
```

---

## 🎯 **Checklist de Migração**

- [ ] **Importar o widget** (já disponível em `package:flutter/material.dart`)
- [ ] **Envolver os RadioListTile** com `RadioGroup<T>`
- [ ] **Mover `groupValue`** para o `RadioGroup`
- [ ] **Mover `onChanged`** para o `RadioGroup`
- [ ] **Remover `groupValue`** dos `RadioListTile` individuais
- [ ] **Remover `onChanged`** dos `RadioListTile` individuais
- [ ] **Testar a funcionalidade** de seleção
- [ ] **Verificar acessibilidade** com leitores de tela

---

## 📝 **Notas Importantes**

1. **Compatibilidade**: Requer **Flutter 3.35+**
2. **Breaking Change**: Deprecated em 3.32, removido em versões futuras
3. **Benefícios**:
   - ✅ Melhor acessibilidade (APG compliant)
   - ✅ Navegação por teclado aprimorada
   - ✅ Código mais limpo e centralizado
   - ✅ Menos repetição de código

4. **Rádios Desabilitados**:
```dart
RadioListTile<String>(
  value: 'opcao',
  enabled: false,  // ✅ Use 'enabled' ao invés de onChanged: null
)
```

---

## 🔗 **Referências**

- [Documentação Oficial - Radio API Redesign](https://docs.flutter.dev/release/breaking-changes/radio-api-redesign)
- [API RadioGroup](https://api.flutter.dev/flutter/widgets/RadioGroup-class.html)
- [API RadioListTile](https://api.flutter.dev/flutter/material/RadioListTile-class.html)
- [APG - ARIA Practices Guide](https://www.w3.org/WAI/ARIA/apg/patterns/radio)
- [Issue #113562](https://github.com/flutter/flutter/issues/113562)
- [PR #168161](https://github.com/flutter/flutter/pull/168161)

---

## ⏱️ **Timeline da Implementação**

| Etapa | Estimativa |
|-------|-----------|
| Migração `user_registration_screen.dart` | 15 minutos |
| Migração `template_form_screen.dart` | 15 minutos |
| Testes de funcionalidade | 10 minutos |
| Testes de acessibilidade | 10 minutos |
| **Total** | **~50 minutos** |

---

## 🚀 **Quando Aplicar?**

✅ **Recomendado**: Em sprint dedicado de refatoração de código
✅ **Momento ideal**: Antes de atualizar para Flutter 3.36+ (quando a API antiga será removida)
✅ **Prioridade**: Baixa (funcionalidade atual estável, apenas warnings)

---

**Última atualização**: 28/11/2024
**Versão do Flutter testada**: 3.38.1
