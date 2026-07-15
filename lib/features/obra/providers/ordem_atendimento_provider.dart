// lib/features/obra/providers/ordem_atendimento_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ordem_atendimento.dart';

class OrdemAtendimentoProvider extends ChangeNotifier {
  List<OrdemAtendimento> atendimentos = [];
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  // Carregar atendimentos de uma Ordem de Serviço
  Future<void> carregarAtendimentosDaOrdem(String ordemServicoId) async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await supabase
          .from('ordem_atendimento')
          .select()
          .eq('ordem_servico_id', ordemServicoId)
          .order('created_at', ascending: false);

      atendimentos = res.map<OrdemAtendimento>((a) => OrdemAtendimento.fromMap(a)).toList();
      debugPrint("✅ ${atendimentos.length} atendimentos carregados para OS $ordemServicoId");
    } catch (e) {
      debugPrint("❌ Erro ao carregar atendimentos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Salvar ou atualizar atendimento
  Future<bool> salvarAtendimento(OrdemAtendimento atendimento) async {
    try {
      if (atendimento.id.isEmpty || atendimento.id == 'novo') {
        await supabase.from('ordem_atendimento').insert(atendimento.toMap());
        debugPrint("✅ Novo atendimento criado");
      } else {
        await supabase
            .from('ordem_atendimento')
            .update(atendimento.toMap())
            .eq('id', atendimento.id);
        debugPrint("✅ Atendimento atualizado");
      }
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar atendimento: $e");
      return false;
    }
  }

  // Check-in rápido
  Future<bool> registrarCheckin({
    required String ordemServicoId,
    required String? servicoId,
    required int tecnicoId,
  }) async {
    final novo = OrdemAtendimento(
      id: '',
      ordemServicoId: ordemServicoId,
      servicoId: servicoId,
      tecnicoId: tecnicoId,
      dataCheckin: DateTime.now(),
      status: 'em_andamento',
    );
    return await salvarAtendimento(novo);
  }
}