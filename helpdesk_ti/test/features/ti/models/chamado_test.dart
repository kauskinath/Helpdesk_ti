import 'package:flutter_test/flutter_test.dart';
import 'package:helpdesk_ti/features/ti/models/chamado.dart';

void main() {
  group('Chamado Model', () {
    test('fromMap cria Chamado com todos os campos', () {
      final map = {
        'numero': 1,
        'titulo': 'Teste de Chamado',
        'descricao': 'Descrição do teste',
        'setor': 'TI',
        'tipo': 'Serviço',
        'status': 'Aberto',
        'usuarioId': 'user123',
        'usuarioNome': 'João Silva',
        'adminId': 'admin456',
        'adminNome': 'Admin TI',
        'prioridade': 3,
        'anexos': ['url1', 'url2'],
        'numeroComentarios': 5,
        'temAnexos': true,
        'foiArquivado': false,
      };

      final chamado = Chamado.fromMap(map, 'doc123');

      expect(chamado.id, equals('doc123'));
      expect(chamado.numero, equals(1));
      expect(chamado.titulo, equals('Teste de Chamado'));
      expect(chamado.descricao, equals('Descrição do teste'));
      expect(chamado.setor, equals('TI'));
      expect(chamado.tipo, equals('Serviço'));
      expect(chamado.status, equals('Aberto'));
      expect(chamado.usuarioId, equals('user123'));
      expect(chamado.usuarioNome, equals('João Silva'));
      expect(chamado.adminId, equals('admin456'));
      expect(chamado.adminNome, equals('Admin TI'));
      expect(chamado.prioridade, equals(3));
      expect(chamado.anexos.length, equals(2));
      expect(chamado.numeroComentarios, equals(5));
      expect(chamado.temAnexos, isTrue);
      expect(chamado.foiArquivado, isFalse);
    });

    test('fromMap usa valores padrão para campos ausentes', () {
      final map = <String, dynamic>{};

      final chamado = Chamado.fromMap(map, 'doc456');

      expect(chamado.id, equals('doc456'));
      expect(chamado.numero, isNull);
      expect(chamado.titulo, equals(''));
      expect(chamado.descricao, equals(''));
      expect(chamado.setor, equals('Não especificado'));
      expect(chamado.tipo, equals('Solicitação'));
      expect(chamado.status, equals('Aberto'));
      expect(chamado.prioridade, equals(2)); // Média por padrão
      expect(chamado.anexos, isEmpty);
      expect(chamado.numeroComentarios, equals(0));
      expect(chamado.temAnexos, isFalse);
      expect(chamado.foiArquivado, isFalse);
    });

    test('numeroFormatado retorna formato correto com número', () {
      final chamado = Chamado(
        id: 'doc123',
        numero: 42,
        titulo: 'Teste',
        descricao: 'Desc',
        setor: 'TI',
        tipo: 'Serviço',
        status: 'Aberto',
        usuarioId: 'user1',
        usuarioNome: 'User',
        dataCriacao: DateTime.now(),
      );

      expect(chamado.numeroFormatado, equals('#0042'));
    });

    test('numeroFormatado usa ID quando número é null', () {
      final chamado = Chamado(
        id: 'abcdefgh123456',
        titulo: 'Teste',
        descricao: 'Desc',
        setor: 'TI',
        tipo: 'Serviço',
        status: 'Aberto',
        usuarioId: 'user1',
        usuarioNome: 'User',
        dataCriacao: DateTime.now(),
      );

      expect(chamado.numeroFormatado, equals('#abcdefgh'));
    });

    test('toMap converte Chamado para Map corretamente', () {
      final dataCriacao = DateTime(2024, 1, 15, 10, 30);
      final chamado = Chamado(
        id: 'doc123',
        numero: 1,
        titulo: 'Teste',
        descricao: 'Descrição',
        setor: 'TI',
        tipo: 'Serviço',
        status: 'Aberto',
        usuarioId: 'user1',
        usuarioNome: 'User Nome',
        prioridade: 2,
        dataCriacao: dataCriacao,
        anexos: ['url1'],
        tags: ['urgente'],
      );

      final map = chamado.toMap();

      expect(map['numero'], equals(1));
      expect(map['titulo'], equals('Teste'));
      expect(map['descricao'], equals('Descrição'));
      expect(map['setor'], equals('TI'));
      expect(map['tipo'], equals('Serviço'));
      expect(map['status'], equals('Aberto'));
      expect(map['usuarioId'], equals('user1'));
      expect(map['usuarioNome'], equals('User Nome'));
      expect(map['prioridade'], equals(2));
      expect(map['anexos'], equals(['url1']));
      expect(map['tags'], equals(['urgente']));
    });
  });
}
