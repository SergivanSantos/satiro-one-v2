// lib/features/os/providers/os_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ordem_servico.dart';
import '../models/ordem_servico_item.dart';

class OsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<OrdemServico> _ordens = [];
  List<OrdemServico> get ordens => _ordens;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ==================== LISTAGEM ====================

  Future<void> loadOrdens({String? obraId, String? tecnicoId, DateTime? data}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = _supabase.from('ordem_servico').select('*, ordem_servico_item(*)');

      if (obraId != null) query = query.eq('obra_id', obraId);
      if (tecnicoId != null) query = query.eq('tecnico_id', tecnicoId);
      if (data != null) query = query.eq('data', data.toIso8601String().split('T')[0]);

      final res = await query.order('data', ascending: false);

      _ordens = res.map<OrdemServico>((json) => OrdemServico.fromMap(json)).toList();

      debugPrint("✅ ${_ordens.length} ordens de serviço carregadas");
    } catch (e) {
      debugPrint("❌ Erro ao carregar ordens: $e");
      _ordens = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== CRIAR ORDEM ====================

  Future<String?> criarOrdem(OrdemServico ordem, List<String> servicosIds) async {
    try {
      final res = await _supabase
          .from('ordem_servico')
          .insert(ordem.toMap())
          .select()
          .single();

      final ordemId = res['id'];

      // Criar itens
      if (servicosIds.isNotEmpty) {
        final itens = servicosIds.map((servicoId) => {
          'ordem_servico_id': ordemId,
          'obra_servico_id': servicoId,
          'status': 'pendente',
        }).toList();

        await _supabase.from('ordem_servico_item').insert(itens);
      }

      await loadOrdens();
      return ordemId;
    } catch (e) {
      debugPrint("❌ Erro ao criar ordem: $e");
      return null;
    }
  }

  // ==================== ATUALIZAR STATUS ITEM ====================

  Future<bool> atualizarStatusItem(String itemId, String novoStatus, {String? observacoes}) async {
    try {
      await _supabase.from('ordem_servico_item').update({
        'status': novoStatus,
        if (observacoes != null) 'observacoes_tecnico': observacoes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);

      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar item: $e");
      return false;
    }
  }

  // ==================== CHECK-IN / CHECK-OUT ====================

  Future<bool> registrarCheckIn(String ordemId) async {
    try {
      await _supabase.from('ordem_servico').update({
        'check_in': DateTime.now().toIso8601String(),
        'status': 'em_andamento',
      }).eq('id', ordemId);
      return true;
    } catch (e) {
      debugPrint("❌ Erro no check-in: $e");
      return false;
    }
  }

  Future<bool> registrarCheckOut(String ordemId) async {
    try {
      await _supabase.from('ordem_servico').update({
        'check_out': DateTime.now().toIso8601String(),
        'status': 'concluida',
      }).eq('id', ordemId);
      return true;
    } catch (e) {
      debugPrint("❌ Erro no check-out: $e");
      return false;
    }
  }
}