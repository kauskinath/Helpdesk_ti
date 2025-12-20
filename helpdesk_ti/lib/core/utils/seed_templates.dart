import 'package:cloud_firestore/cloud_firestore.dart';

/// Seed de templates padrão para o Help Desk
/// 
/// Este arquivo cria 23 templates pré-configurados organizados por categoria:
/// - Hardware (3), Rede (3), Impressoras (3), Software (3)
/// - Email (2), Acessos (3), Telefonia (2), Outros (4)
class TemplateSeed {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cria todos os 23 templates padrão no Firestore
  static Future<void> seedTemplates() async {
    final templates = _getAllTemplates();
    
    for (final templateData in templates) {
      await _firestore.collection('templates').add(templateData);
    }
    
    print('✅ ${templates.length} templates criados com sucesso!');
  }

  /// Remove todos os templates do Firestore
  static Future<void> clearAllTemplates() async {
    final snapshot = await _firestore.collection('templates').get();
    
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    
    print('✅ ${snapshot.docs.length} templates removidos!');
  }

  /// Retorna lista com todos os templates pré-configurados
  static List<Map<String, dynamic>> _getAllTemplates() {
    return [
      // ========== HARDWARE (3) ==========
      {
        'titulo': '🖥️ Computador não liga',
        'descricaoModelo': '''Meu computador não está ligando. Já verifiquei se está conectado na tomada.

Detalhes:
- Local: [Informe seu setor/sala]
- Patrimônio: [Se souber o número]
- Observações adicionais: [Descreva outros sintomas]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 3,
        'tags': ['hardware', 'computador', 'urgente'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🐌 Computador muito lento',
        'descricaoModelo': '''Meu computador está muito lento, travando constantemente.

Sintomas:
- Demora para abrir programas: [Sim/Não]
- Tela congela: [Sim/Não]
- Local: [Setor/Sala]
- Patrimônio: [Número]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['hardware', 'performance', 'lentidao'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '⌨️ Teclado/Mouse com defeito',
        'descricaoModelo': '''Teclado ou mouse não está funcionando corretamente.

Detalhes:
- Equipamento com problema: [Teclado/Mouse/Ambos]
- Tipo de problema: [Teclas não funcionam/Cursor travado/Outro]
- Local: [Setor/Sala]
- Patrimônio: [Número]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['hardware', 'periferico', 'teclado', 'mouse'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },

      // ========== REDE E INTERNET (3) ==========
      {
        'titulo': '🌐 Sem acesso à internet',
        'descricaoModelo': '''Estou sem acesso à internet no meu computador.

Informações:
- Tipo de conexão: [Wi-Fi/Cabo de rede]
- Ícone de rede mostra: [X vermelho/Exclamação amarela/Outro]
- Local: [Setor/Sala]
- Outros equipamentos funcionam: [Sim/Não]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 3,
        'tags': ['rede', 'internet', 'urgente'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🐢 Internet lenta',
        'descricaoModelo': '''A internet está muito lenta para trabalhar.

Detalhes:
- Velocidade antes: [Normal/Boa/Ruim]
- Desde quando: [Hoje/Ontem/Há dias]
- Local: [Setor/Sala]
- Outros usuários com problema: [Sim/Não]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['rede', 'internet', 'lentidao'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🔌 Ponto de rede não funciona',
        'descricaoModelo': '''O ponto de rede (tomada RJ45) não está funcionando.

Informações:
- Local exato: [Setor/Sala/Mesa]
- Já testei outro cabo: [Sim/Não]
- LED do ponto de rede: [Aceso/Apagado/Piscando]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['rede', 'infraestrutura', 'cabeamento'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },

      // ========== IMPRESSORAS (3) ==========
      {
        'titulo': '🖨️ Impressora não imprime',
        'descricaoModelo': '''A impressora não está imprimindo os documentos.

Detalhes:
- Nome/Modelo da impressora: [Ex: HP LaserJet Financeiro]
- Mensagem de erro: [Se houver]
- Local: [Setor/Sala]
- Luzes da impressora: [Verde/Vermelha/Piscando]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['impressora', 'hardware'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '📄 Impressora com atolamento',
        'descricaoModelo': '''A impressora está com papel atolado.

Informações:
- Impressora: [Nome/Modelo]
- Tentei remover: [Sim/Não]
- Onde o papel está preso: [Gaveta/Fusor/Saída]
- Local: [Setor/Sala]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['impressora', 'atolamento'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🖋️ Toner/Tinta acabando',
        'descricaoModelo': '''O toner ou tinta da impressora está acabando.

Detalhes:
- Impressora: [Nome/Modelo]
- Tipo: [Toner preto/Colorido/Tinta]
- Local: [Setor/Sala]
- Urgência: [Acabou/Acabando]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 1,
        'tags': ['impressora', 'suprimentos', 'toner'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },

      // ========== SOFTWARE (3) ==========
      {
        'titulo': '💿 Instalação de software',
        'descricaoModelo': '''Preciso instalar um software no meu computador.

Informações:
- Nome do software: [Ex: Adobe Reader, Chrome]
- Para que será usado: [Descrição breve]
- Precisa de licença: [Sim/Não/Não sei]
- Local: [Setor/Sala]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 2,
        'tags': ['software', 'instalacao'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '❌ Programa não abre/trava',
        'descricaoModelo': '''Um programa não está abrindo ou está travando.

Detalhes:
- Nome do programa: [Ex: Excel, Word, Sistema X]
- Mensagem de erro: [Se houver]
- Desde quando: [Hoje/Ontem/Há dias]
- Já tentou reiniciar: [Sim/Não]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['software', 'erro', 'travamento'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🔄 Atualização do Windows travando',
        'descricaoModelo': '''A atualização do Windows não está completando.

Informações:
- Mensagem na tela: [Descreva]
- Percentual onde trava: [Ex: 35%]
- Há quanto tempo está assim: [Minutos/Horas]
- Local: [Setor/Sala]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['software', 'windows', 'atualizacao'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },

      // ========== EMAIL (2) ==========
      {
        'titulo': '📧 Não consigo acessar email',
        'descricaoModelo': '''Não estou conseguindo acessar meu email.

Detalhes:
- Onde está tentando: [Outlook/Webmail/Celular]
- Mensagem de erro: [Se houver]
- Esqueceu a senha: [Sim/Não]
- Já funcionou antes: [Sim/Não]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 3,
        'tags': ['email', 'acesso', 'urgente'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '✉️ Email não envia/recebe',
        'descricaoModelo': '''Meu email não está enviando ou recebendo mensagens.

Informações:
- Problema: [Não envia/Não recebe/Ambos]
- Mensagem de erro: [Se houver]
- Desde quando: [Hoje/Ontem/Há dias]
- Consegue ver emails antigos: [Sim/Não]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 3,
        'tags': ['email', 'envio', 'recebimento'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },

      // ========== ACESSOS E SENHAS (3) ==========
      {
        'titulo': '🔐 Esqueci minha senha',
        'descricaoModelo': '''Esqueci minha senha e preciso resetar.

Informações:
- Sistema: [Windows/Email/Sistema específico]
- Seu nome completo: [Nome]
- Seu cargo: [Cargo]
- Ramal/Telefone: [Contato]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 3,
        'tags': ['acesso', 'senha', 'reset', 'urgente'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '➕ Criar novo usuário',
        'descricaoModelo': '''Preciso criar acesso para novo colaborador.

Dados do colaborador:
- Nome completo: [Nome]
- Cargo: [Cargo]
- Setor: [Setor]
- Data de início: [DD/MM/AAAA]
- Acessos necessários: [Email/Sistemas/Outros]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 2,
        'tags': ['acesso', 'usuario', 'onboarding'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🚫 Desativar usuário',
        'descricaoModelo': '''Preciso desativar acesso de colaborador.

Dados:
- Nome do colaborador: [Nome completo]
- Cargo: [Cargo]
- Último dia de trabalho: [DD/MM/AAAA]
- Motivo: [Desligamento/Férias/Licença]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 2,
        'tags': ['acesso', 'usuario', 'offboarding'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },

      // ========== TELEFONIA (2) ==========
      {
        'titulo': '📞 Ramal não funciona',
        'descricaoModelo': '''Meu ramal de telefone não está funcionando.

Detalhes:
- Número do ramal: [Número]
- Problema: [Sem tom/Não toca/Não completa ligação]
- Local: [Setor/Sala]
- Desde quando: [Hoje/Ontem/Há dias]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 2,
        'tags': ['telefonia', 'ramal'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '☎️ Solicitar novo ramal',
        'descricaoModelo': '''Preciso instalar um novo ramal.

Informações:
- Local para instalação: [Setor/Sala/Mesa]
- Quem vai usar: [Nome/Cargo]
- Urgência: [Urgente/Normal]
- Já tem ponto telefônico: [Sim/Não/Não sei]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 1,
        'tags': ['telefonia', 'ramal', 'instalacao'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },

      // ========== OUTROS (4) ==========
      {
        'titulo': '💾 Recuperação de arquivos',
        'descricaoModelo': '''Preciso recuperar arquivos deletados ou perdidos.

Detalhes:
- Tipo de arquivo: [Documentos/Fotos/Planilhas]
- Nome aproximado: [Se lembrar]
- Quando foi perdido: [Data aproximada]
- Local original: [Pasta/Servidor]''',
        'setor': 'TI',
        'tipo': 'Chamado',
        'prioridade': 3,
        'tags': ['dados', 'recuperacao', 'backup', 'urgente'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🛒 Solicitar novo equipamento',
        'descricaoModelo': '''Preciso solicitar compra de equipamento.

Informações:
- Equipamento: [Computador/Notebook/Monitor/Outro]
- Justificativa: [Por que precisa]
- Urgência: [Urgente/Normal]
- Para quem: [Nome/Setor]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 1,
        'tags': ['equipamento', 'compra', 'hardware'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '🔧 Manutenção preventiva',
        'descricaoModelo': '''Solicito manutenção preventiva do equipamento.

Detalhes:
- Equipamento: [Computador/Notebook/Impressora]
- Patrimônio: [Número]
- Local: [Setor/Sala]
- Última manutenção: [Quando/Nunca]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 1,
        'tags': ['manutencao', 'preventiva'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
      {
        'titulo': '❓ Dúvida sobre sistema',
        'descricaoModelo': '''Tenho uma dúvida sobre como usar um sistema.

Detalhes:
- Sistema: [Nome do sistema]
- Dúvida: [Descreva sua dúvida]
- Para que precisa: [Objetivo]
- Urgência: [Urgente/Normal]''',
        'setor': 'TI',
        'tipo': 'Solicitacao',
        'prioridade': 1,
        'tags': ['suporte', 'duvida', 'treinamento'],
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      },
    ];
  }
}
