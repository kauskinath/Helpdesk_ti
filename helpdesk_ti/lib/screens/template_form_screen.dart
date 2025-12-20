import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';
import 'package:helpdesk_ti/features/ti/models/chamado_template.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';
import 'package:helpdesk_ti/core/services/auth_service.dart';
import '../data/services/chamado_service.dart';
import 'package:helpdesk_ti/core/theme/theme_provider.dart';

/// Tela de formulário dinâmico baseado em template
class TemplateFormScreen extends StatefulWidget {
  final ChamadoTemplate template;

  const TemplateFormScreen({super.key, required this.template});

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Inicializar controllers e valores padrão
    if (widget.template.campos != null) {
      for (final campo in widget.template.campos!) {
        if (campo.type == FieldType.text ||
            campo.type == FieldType.multiline ||
            campo.type == FieldType.number) {
          _controllers[campo.id] = TextEditingController(
            text: campo.defaultValue,
          );
        }
        if (campo.defaultValue != null) {
          _fieldValues[campo.id] = campo.defaultValue;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _buildDescricaoFromFields() {
    final buffer = StringBuffer();
    buffer.writeln(widget.template.descricaoModelo);
    buffer.writeln('\n--- INFORMAÇÕES PREENCHIDAS ---\n');

    if (widget.template.campos != null) {
      for (final campo in widget.template.campos!) {
        final value = _fieldValues[campo.id];
        if (value != null && value.toString().isNotEmpty) {
          buffer.writeln('${campo.label}: $value');
        }
      }
    }

    return buffer.toString();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      final authService = context.read<AuthService>();
      final chamadoService = context.read<ChamadoService>();

      final descricao = _buildDescricaoFromFields();

      final chamado = Chamado(
        id: '',
        numero: 0,
        titulo: widget.template.titulo,
        descricao: descricao,
        tipo: widget.template.tipo,
        setor: widget.template.setor ?? 'TI',
        status: 'Aberto',
        prioridade: widget.template.prioridade,
        usuarioId: authService.firebaseUser!.uid,
        usuarioNome: authService.userName ?? 'Usuário',
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );

      await chamadoService.criarChamado(chamado);

      if (mounted) {
        Navigator.pop(context); // Voltar para lista de templates
        Navigator.pop(context); // Voltar para home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle),
                SizedBox(width: 8),
                Text('Chamado criado com sucesso!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao criar chamado: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            isDarkMode
                ? 'assets/images/wallpaper_dark.png'
                : 'assets/images/wallpaper_light.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.template.titulo),
          backgroundColor: Theme.of(
            context,
          ).appBarTheme.backgroundColor?.withValues(alpha: 0.95),
          elevation: 2,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de informações do template
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      AppColors.primaryLight.withValues(
                                        alpha: 0.1,
                                      ),
                                    ]
                                  : [Colors.blue.shade50, Colors.blue.shade100],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : Colors.blue.shade300,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? AppColors.primary.withValues(
                                              alpha: 0.3,
                                            )
                                          : Colors.blue.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.transparent
                                            : Colors.blue.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.description,
                                      size: 20,
                                      color: isDarkMode
                                          ? null
                                          : Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tipo de Chamado',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        Text(
                                          widget.template.tipo,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Título da seção
                        Text(
                          'Preencha os campos abaixo',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Campos marcados com * são obrigatórios',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        // Renderizar campos dinamicamente
                        if (widget.template.campos != null)
                          ...widget.template.campos!.map(
                            (campo) => _buildField(campo),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Este template não possui campos estruturados.\nUse a criação manual de chamados.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Botão de enviar
                if (widget.template.campos != null &&
                    widget.template.campos!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Criar Chamado',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TemplateField campo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              children: [
                TextSpan(text: campo.label),
                if (campo.required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Campo baseado no tipo
          _buildFieldWidget(campo),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(TemplateField campo) {
    switch (campo.type) {
      case FieldType.text:
      case FieldType.number:
        return _buildTextField(campo);
      case FieldType.multiline:
        return _buildMultilineField(campo);
      case FieldType.select:
        return _buildSelectField(campo);
      case FieldType.radio:
        return _buildRadioField(campo);
      case FieldType.checkbox:
        return _buildCheckboxField(campo);
    }
  }

  Widget _buildTextField(TemplateField campo) {
    return TextFormField(
      controller: _controllers[campo.id],
      keyboardType: campo.type == FieldType.number
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: campo.placeholder ?? 'Digite aqui...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: (value) {
        if (campo.required && (value == null || value.trim().isEmpty)) {
          return 'Este campo é obrigatório';
        }
        return null;
      },
      onSaved: (value) {
        _fieldValues[campo.id] = value;
      },
    );
  }

  Widget _buildMultilineField(TemplateField campo) {
    return TextFormField(
      controller: _controllers[campo.id],
      maxLines: 4,
      decoration: InputDecoration(
        hintText: campo.placeholder ?? 'Digite aqui...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: (value) {
        if (campo.required && (value == null || value.trim().isEmpty)) {
          return 'Este campo é obrigatório';
        }
        return null;
      },
      onSaved: (value) {
        _fieldValues[campo.id] = value;
      },
    );
  }

  Widget _buildSelectField(TemplateField campo) {
    return DropdownButtonFormField<String>(
      initialValue: _fieldValues[campo.id],
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      hint: Text(campo.placeholder ?? 'Selecione uma opção'),
      items: campo.options?.map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      validator: (value) {
        if (campo.required && (value == null || value.isEmpty)) {
          return 'Este campo é obrigatório';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _fieldValues[campo.id] = value;
        });
      },
      onSaved: (value) {
        _fieldValues[campo.id] = value;
      },
    );
  }

  Widget _buildRadioField(TemplateField campo) {
    return Column(
      children:
          campo.options?.map((option) {
            // ignore: deprecated_member_use
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              // ignore: deprecated_member_use
              groupValue: _fieldValues[campo.id],
              activeColor: AppColors.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                setState(() {
                  _fieldValues[campo.id] = value;
                });
              },
            );
          }).toList() ??
          [],
    );
  }

  Widget _buildCheckboxField(TemplateField campo) {
    // Para checkbox, armazenamos uma lista de valores selecionados
    final List<String> selectedValues = _fieldValues[campo.id] ?? [];

    return Column(
      children:
          campo.options?.map((option) {
            return CheckboxListTile(
              title: Text(option),
              value: selectedValues.contains(option),
              activeColor: AppColors.primary,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    selectedValues.add(option);
                  } else {
                    selectedValues.remove(option);
                  }
                  _fieldValues[campo.id] = selectedValues;
                });
              },
            );
          }).toList() ??
          [],
    );
  }
}





