import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client_phase_config.dart';

class ClientPhaseConfigProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ClientPhaseConfig> _phases = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClientPhaseConfig> get phases => _phases;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fases ativas ordenadas
  List<ClientPhaseConfig> get activePhases =>
      _phases.where((p) => p.isActive).toList()..sort((a, b) => a.phaseOrder.compareTo(b.phaseOrder));

  ClientPhaseConfigProvider() {
    loadPhases();
  }

  Future<void> loadPhases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('client_phases_config')
          .select()
          .order('phase_order', ascending: true);   // ← IMPORTANTE: ordem crescente

      _phases = response.map((json) => ClientPhaseConfig.fromJson(json)).toList();

      print('📋 [LOAD] Fases carregadas e ordenadas: ${_phases.length}');
      for (var p in _phases) {
        print('   → ${p.phaseName} (ordem ${p.phaseOrder})');
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar configuração de fases: $e';
      print(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== ADICIONAR NOVA FASE ====================
  Future<void> addPhase(ClientPhaseConfig phase) async {
    try {
      // Ordena a lista atual para calcular o maxOrder corretamente
      final sortedPhases = List<ClientPhaseConfig>.from(_phases)
        ..sort((a, b) => a.phaseOrder.compareTo(b.phaseOrder));

      final maxOrder = sortedPhases.isEmpty ? 0 : sortedPhases.last.phaseOrder;

      final map = {
        'phase_name': phase.phaseName,
        'phase_order': maxOrder + 1,        // ← Sempre no final
        'color': phase.color,
        'requires_checklist': phase.requiresChecklist,
        'is_active': phase.isActive,
      };

      await _supabase.from('client_phases_config').insert(map);

      print('✅ Nova fase "${phase.phaseName}" criada com ordem ${maxOrder + 1}');

      await loadPhases();   // Recarrega para atualizar a UI corretamente
    } catch (e) {
      _errorMessage = 'Erro ao adicionar fase: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ==================== REORDENAR FASES ====================
  Future<void> reorderPhases(List<ClientPhaseConfig> reordered) async {
    try {
      print('🔄 [REORDER] Iniciando reordenação de ${reordered.length} fases');

      for (int i = 0; i < reordered.length; i++) {
        final phase = reordered[i];
        final newOrder = i + 1;

        if (phase.id == null) {
          print('⚠️ Fase "${phase.phaseName}" sem ID válido, pulando...');
          continue;
        }

        print('   → "${phase.phaseName}" → nova ordem: $newOrder');

        await _supabase
            .from('client_phases_config')
            .update({'phase_order': newOrder})
            .eq('id', phase.id!);
      }

      await loadPhases();
      print('✅ [REORDER] Reordenação concluída com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao reordenar fases: $e';
      notifyListeners();
      print('❌ [REORDER] Erro: $e');
    }
  }

  Future<void> updatePhase(ClientPhaseConfig phase) async {
    if (phase.id == null) {
      print('⚠️ [UPDATE] ID da fase é null');
      return;
    }

    try {
      final map = {
        'phase_name': phase.phaseName,
        'phase_order': phase.phaseOrder,
        'color': phase.color,
        'requires_checklist': phase.requiresChecklist,
        'is_active': phase.isActive,
        'checklist_id': phase.checklistId,        // ← Forçando o salvamento
      };

      print('🔄 [UPDATE] Atualizando fase ID: ${phase.id} | checklist_id: ${phase.checklistId}');

      await _supabase
          .from('client_phases_config')
          .update(map)
          .eq('id', phase.id!);

      await loadPhases();
      print('✅ [UPDATE] Fase atualizada com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao atualizar fase: $e';
      notifyListeners();
      print('❌ [UPDATE] Erro: $e');
      rethrow;
    }
  }

  Future<void> deletePhase(int? id) async {
    if (id == null) {
      print('⚠️ Tentativa de deletar fase com ID null');
      return;
    }

    try {
      print('🗑️ [DELETE] Excluindo fase ID: $id');
      await _supabase.from('client_phases_config').delete().eq('id', id);
      await loadPhases();
      print('✅ [DELETE] Fase excluída com sucesso');
    } catch (e) {
      print('❌ [DELETE] Erro ao excluir fase: $e');
    }
  }



  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}