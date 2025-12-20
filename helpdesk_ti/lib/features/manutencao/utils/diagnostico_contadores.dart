import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de diagnóstico para verificar os contadores no Firestore
/// 
/// Execute este método em algum lugar do app (ex: botão de teste no dashboard Admin)
/// para verificar se os contadores estão configurados corretamente
Future<void> diagnosticarContadores() async {
  final firestore = FirebaseFirestore.instance;
  
  print('\n🔍 ========== DIAGNÓSTICO DE CONTADORES ==========\n');
  
  try {
    // Verificar contador de TI (chamados)
    print('📊 Verificando contador TI (chamados)...');
    final tiDoc = await firestore.collection('counters').doc('chamados').get();
    
    if (tiDoc.exists) {
      print('✅ Contador TI existe!');
      print('   Último número: ${tiDoc.data()?['ultimoNumero'] ?? 'CAMPO NÃO ENCONTRADO'}');
    } else {
      print('❌ Contador TI NÃO existe!');
      print('   Solução: Criar documento counters/chamados com campo ultimoNumero: 0');
    }
    
    print('');
    
    // Verificar contador de Manutenção
    print('🔧 Verificando contador Manutenção...');
    final manutencaoDoc = await firestore.collection('counters').doc('manutencao').get();
    
    if (manutencaoDoc.exists) {
      print('✅ Contador Manutenção existe!');
      print('   Último número: ${manutencaoDoc.data()?['ultimoNumero'] ?? 'CAMPO NÃO ENCONTRADO'}');
    } else {
      print('❌ Contador Manutenção NÃO existe!');
      print('   Solução: Criar documento counters/manutencao com campo ultimoNumero: 0');
    }
    
    print('');
    
    // Verificar chamados existentes
    print('📋 Verificando chamados de manutenção...');
    final chamadosSnapshot = await firestore
        .collection('chamados')
        .where('tipo', isEqualTo: 'MANUTENCAO')
        .limit(5)
        .get();
    
    print('   Total de chamados encontrados: ${chamadosSnapshot.docs.length}');
    
    if (chamadosSnapshot.docs.isEmpty) {
      print('   ⚠️ Nenhum chamado de manutenção criado ainda');
    } else {
      for (var doc in chamadosSnapshot.docs) {
        final data = doc.data();
        final numero = data['numero'];
        final titulo = data['titulo'] ?? 'Sem título';
        
        if (numero != null) {
          print('   ✅ Chamado ${doc.id}: #${numero.toString().padLeft(4, '0')} - $titulo');
        } else {
          print('   ❌ Chamado ${doc.id}: SEM NÚMERO - $titulo');
        }
      }
    }
    
    print('');
    print('📊 ========== FIM DO DIAGNÓSTICO ==========\n');
    
    // Resumo
    print('📝 RESUMO:');
    if (!tiDoc.exists) {
      print('   ⚠️ Criar: counters/chamados com ultimoNumero: 0');
    }
    if (!manutencaoDoc.exists) {
      print('   ⚠️ Criar: counters/manutencao com ultimoNumero: 0');
    }
    if (tiDoc.exists && manutencaoDoc.exists) {
      print('   ✅ Todos os contadores estão configurados!');
      if (chamadosSnapshot.docs.any((doc) => doc.data()['numero'] == null)) {
        print('   ⚠️ Alguns chamados existentes não têm número');
        print('   💡 Novos chamados terão numeração automática');
      }
    }
    
  } catch (e) {
    print('❌ Erro no diagnóstico: $e');
    print('   Verifique as permissões do Firestore');
  }
}

/// Método para CRIAR os contadores automaticamente (use apenas UMA vez)
/// 
/// ATENÇÃO: Execute apenas se os contadores não existirem!
Future<void> criarContadoresAutomaticamente() async {
  final firestore = FirebaseFirestore.instance;
  
  print('\n🔧 ========== CRIANDO CONTADORES ==========\n');
  
  try {
    // Criar contador TI
    print('📊 Criando contador TI (chamados)...');
    await firestore.collection('counters').doc('chamados').set({
      'ultimoNumero': 0,
    });
    print('✅ Contador TI criado!');
    
    // Criar contador Manutenção
    print('🔧 Criando contador Manutenção...');
    await firestore.collection('counters').doc('manutencao').set({
      'ultimoNumero': 0,
    });
    print('✅ Contador Manutenção criado!');
    
    print('\n✅ ========== CONTADORES CRIADOS COM SUCESSO! ==========\n');
    print('💡 Execute diagnosticarContadores() para verificar');
    
  } catch (e) {
    print('❌ Erro ao criar contadores: $e');
    print('   Possíveis causas:');
    print('   1. Regras do Firestore não permitem escrita');
    print('   2. Usuário não tem permissão de admin');
    print('   3. Conexão com Firebase não está configurada');
  }
}
