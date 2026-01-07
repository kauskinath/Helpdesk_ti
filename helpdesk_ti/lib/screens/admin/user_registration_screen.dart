import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helpdesk_ti/core/theme/design_system.dart';
import 'package:helpdesk_ti/shared/widgets/wallpaper_scaffold.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _senhaController = TextEditingController();

  String? _setorSelecionado;
  String _tipoUsuario = 'user';
  bool _isLoading = false;

  // Lista completa de setores (mesma do sistema)
  final Map<String, String> _setoresDisponiveis = {
    'almoxarifado': 'Almoxarifado',
    'atendimento': 'Atendimento',
    'cesar': 'Estoque G6',
    'comex': 'Comex',
    'compras': 'Compras',
    'desenvolvimento': 'Desenvolvimento',
    'dev': 'Dev',
    'devolucao': 'Devolução',
    'entrada': 'Entrada',
    'estoque': 'Estoque',
    'financeiro_fiscal': 'Financeiro Fiscal',
    'financeiro_giordani': 'Financeiro Contas',
    'financeiro_mayra': 'Financeiro Contábil',
    'galpao5': 'Estoque G5',
    'gerencia': 'Gerência',
    'impressao': 'Impressão',
    'javier': 'Estoque G9',
    'juridico': 'Jurídico',
    'logistica': 'Logística',
    'marketing': 'Marketing',
    'market_place': 'Market Place',
    'nota_fiscal': 'Nota Fiscal',
    'nota_pc': 'Nota Fiscal PC',
    'pichau_empresas': 'Pichau Empresas',
    'plp': 'PLP',
    'rh': 'RH',
    'rma_fornecedor': 'RMA Fornecedor',
    'rma_pc': 'RMA PC',
    'rma_pecas': 'RMA Peças',
    'rma_pichaugaming': 'RMA Pichau Gaming',
    'ti': 'TI',
    'vendas': 'Vendas PC',
  };

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  String _gerarEmail() {
    final nome = _nomeController.text.trim().toLowerCase();
    final sobrenome = _sobrenomeController.text.trim().toLowerCase();

    // Remove acentos e caracteres especiais
    final nomeClean = _removerAcentos(nome);
    final sobrenomeClean = _removerAcentos(sobrenome);

    return '$nomeClean.$sobrenomeClean@helpdesk.com';
  }

  String _removerAcentos(String texto) {
    // Mapeamento completo de caracteres acentuados
    const Map<String, String> mapa = {
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'Æ': 'AE',
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'æ': 'ae',
      'Ç': 'C',
      'ç': 'c',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'Ð': 'D',
      'ð': 'd',
      'Ñ': 'N',
      'ñ': 'n',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ø': 'O',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ø': 'o',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'Ý': 'Y',
      'ý': 'y',
      'ÿ': 'y',
      'Ÿ': 'Y',
      'Þ': 'TH',
      'þ': 'th',
      'ß': 'ss',
      'Š': 'S',
      'š': 's',
      'Ž': 'Z',
      'ž': 'z',
    };

    String resultado = texto;
    mapa.forEach((acentuado, semAcento) {
      resultado = resultado.replaceAll(acentuado, semAcento);
    });

    // Remove espaços e caracteres especiais (mantém apenas a-z e 0-9)
    resultado = resultado.replaceAll(RegExp(r'[^a-z0-9]'), '');

    return resultado;
  }

  /// Valida se o nome/sobrenome contém apenas letras e espaços
  bool _isValidName(String name) {
    // Remove espaços extras e verifica se está vazio
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    // Permite apenas letras (incluindo acentuadas), espaços, hífens e apóstrofos
    // Usa abordagem mais robusta: verifica se NÃO contém números ou caracteres especiais proibidos
    final invalidChars = RegExp(r'[0-9@#$%^&*()+=\[\]{}|\\<>/?!~`";:,.]');
    if (invalidChars.hasMatch(trimmed)) return false;

    // Verifica se contém pelo menos uma letra
    final hasLetter = RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(trimmed);
    return hasLetter;
  }

  /// Valida formato de email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida requisitos de senha forte
  String? _validarSenha(String? senha) {
    if (senha == null || senha.isEmpty) {
      return 'Por favor, informe a senha';
    }

    if (senha.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }

    // Verificar se tem pelo menos uma letra
    if (!senha.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Senha deve conter pelo menos uma letra';
    }

    // Verificar se tem pelo menos um número
    if (!senha.contains(RegExp(r'[0-9]'))) {
      return 'Senha deve conter pelo menos um número';
    }

    return null; // Senha válida
  }

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_setorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um setor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar nome e sobrenome antes de gerar email
    final nome = _nomeController.text.trim();
    final sobrenome = _sobrenomeController.text.trim();

    if (!_isValidName(nome)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome deve conter apenas letras e espaços'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidName(sobrenome)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sobrenome deve conter apenas letras e espaços'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _gerarEmail();
      final senha = _senhaController.text.trim();
      final nomeCompleto = '$nome $sobrenome';

      // Validar formato de email gerado
      if (!_isValidEmail(email)) {
        throw Exception(
          'Email gerado é inválido: $email. Verifique nome e sobrenome.',
        );
      }

      // ⚠️ IMPORTANTE: O Firebase faz login automático com o novo usuário
      // Por isso precisamos deslogar após criar o usuário

      // Criar usuário no Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);

      // Atualizar displayName
      await userCredential.user?.updateDisplayName(nomeCompleto);

      // Criar documento no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'nome': nomeCompleto,
            'setor': _setorSelecionado,
            'role': _tipoUsuario,
            'dataCriacao': FieldValue.serverTimestamp(),
            'ativo': true,
          });

      // ⚠️ IMPORTANTE: Deslogar o usuário recém-criado e relogar com admin
      await FirebaseAuth.instance.signOut();

      // Nota: O admin precisará fazer login novamente manualmente
      // Isso é por segurança - não armazenamos a senha do admin

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Usuário criado: $email\n'
              'Você foi deslogado e precisa fazer login novamente.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Navegar para tela de login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao criar usuário';

      if (e.code == 'email-already-in-use') {
        mensagem = 'Este email já está em uso';
      } else if (e.code == 'weak-password') {
        mensagem = 'Senha muito fraca (mínimo 6 caracteres)';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Email inválido';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cadastrar Novo Usuário',
          style: TextStyle(
            color: DS.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: DS.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Formato do Email',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nomeController.text.isNotEmpty &&
                              _sobrenomeController.text.isNotEmpty
                          ? '📧 Email gerado: ${_gerarEmail()}'
                          : '📧 Email será: nome.sobrenome@helpdesk.com',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nome
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(color: DS.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: const TextStyle(color: DS.textSecondary),
                  prefixIcon: const Icon(Icons.person, color: DS.textSecondary),
                  filled: true,
                  fillColor: DS.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.action, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome';
                  }
                  if (!_isValidName(value)) {
                    return 'Apenas letras, espaços e hífens';
                  }
                  if (value.trim().length < 2) {
                    return 'Nome muito curto';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Sobrenome
              TextFormField(
                controller: _sobrenomeController,
                style: const TextStyle(color: DS.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Sobrenome',
                  labelStyle: const TextStyle(color: DS.textSecondary),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: DS.textSecondary,
                  ),
                  filled: true,
                  fillColor: DS.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.action, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o sobrenome';
                  }
                  if (!_isValidName(value)) {
                    return 'Apenas letras, espaços e hífens';
                  }
                  if (value.trim().length < 2) {
                    return 'Sobrenome muito curto';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Setor
              DropdownButtonFormField<String>(
                value: _setorSelecionado,
                dropdownColor: DS.card,
                style: const TextStyle(color: DS.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Setor',
                  labelStyle: const TextStyle(color: DS.textSecondary),
                  prefixIcon: const Icon(
                    Icons.business,
                    color: DS.textSecondary,
                  ),
                  filled: true,
                  fillColor: DS.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.action, width: 2),
                  ),
                ),
                items: _setoresDisponiveis.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(color: DS.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _setorSelecionado = value);
                },
              ),
              const SizedBox(height: 16),

              // Senha
              TextFormField(
                controller: _senhaController,
                obscureText: true,
                style: const TextStyle(color: DS.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: const TextStyle(color: DS.textSecondary),
                  prefixIcon: const Icon(Icons.lock, color: DS.textSecondary),
                  filled: true,
                  fillColor: DS.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DS.action, width: 2),
                  ),
                  helperText: 'Mínimo 6 caracteres (letras + números)',
                  helperStyle: const TextStyle(color: DS.textTertiary),
                ),
                validator: _validarSenha,
              ),
              const SizedBox(height: 24),

              // Tipo de usuário
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DS.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DS.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Usuário',
                      style: TextStyle(
                        color: DS.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ignore: deprecated_member_use
                    RadioListTile<String>(
                      title: const Text(
                        'Usuário Comum',
                        style: TextStyle(color: DS.textPrimary),
                      ),
                      subtitle: const Text(
                        'Pode criar chamados e solicitações',
                        style: TextStyle(color: DS.textSecondary, fontSize: 12),
                      ),
                      value: 'user',
                      // ignore: deprecated_member_use
                      groupValue: _tipoUsuario,
                      activeColor: DS.action,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() => _tipoUsuario = value!);
                      },
                    ),
                    // ignore: deprecated_member_use
                    RadioListTile<String>(
                      title: const Text(
                        'Gerente',
                        style: TextStyle(color: DS.textPrimary),
                      ),
                      subtitle: const Text(
                        'Aprova solicitações e orçamentos',
                        style: TextStyle(color: DS.textSecondary, fontSize: 12),
                      ),
                      value: 'manager',
                      // ignore: deprecated_member_use
                      groupValue: _tipoUsuario,
                      activeColor: Colors.orange,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() => _tipoUsuario = value!);
                      },
                    ),
                    // ignore: deprecated_member_use
                    RadioListTile<String>(
                      title: const Text(
                        'Supervisor Manutenção',
                        style: TextStyle(color: DS.textPrimary),
                      ),
                      subtitle: const Text(
                        'Gerencia chamados de manutenção',
                        style: TextStyle(color: DS.textSecondary, fontSize: 12),
                      ),
                      value: 'admin_manutencao',
                      // ignore: deprecated_member_use
                      groupValue: _tipoUsuario,
                      activeColor: Colors.purple,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() => _tipoUsuario = value!);
                      },
                    ),
                    // ignore: deprecated_member_use
                    RadioListTile<String>(
                      title: const Text(
                        'Executor Manutenção',
                        style: TextStyle(color: DS.textPrimary),
                      ),
                      subtitle: const Text(
                        'Executa trabalhos de manutenção',
                        style: TextStyle(color: DS.textSecondary, fontSize: 12),
                      ),
                      value: 'executor',
                      // ignore: deprecated_member_use
                      groupValue: _tipoUsuario,
                      activeColor: Colors.teal,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() => _tipoUsuario = value!);
                      },
                    ),
                    // ignore: deprecated_member_use
                    RadioListTile<String>(
                      title: const Text(
                        'Administrador/TI',
                        style: TextStyle(color: DS.textPrimary),
                      ),
                      subtitle: const Text(
                        'Acesso total ao sistema',
                        style: TextStyle(color: DS.textSecondary, fontSize: 12),
                      ),
                      value: 'admin',
                      // ignore: deprecated_member_use
                      groupValue: _tipoUsuario,
                      activeColor: DS.action,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() => _tipoUsuario = value!);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botão cadastrar
              ElevatedButton(
                onPressed: _isLoading ? null : _cadastrarUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cadastrar Usuário',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
