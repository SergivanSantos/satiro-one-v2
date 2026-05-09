// lib/providers/checklist_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/checklist.dart';
import '../models/checklist_group.dart';
import '../models/checklist_subgroup.dart';
import '../models/checklist_item.dart';

class ChecklistProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Checklist> _checklists = [];
  bool _isLoading = false;
  String? _error;

  List<Checklist> get checklists => _checklists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== CARREGAMENTO ====================
  Future<void> loadChecklists() async {
    print('🔄 [ChecklistProvider] Iniciando loadChecklists()');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('checklists')
          .select('*, groups:checklist_groups(*, subgroups:checklist_subgroups(*, items:checklist_items(*)))')
          .order('order_index');

      _checklists = response.map<Checklist>((json) {
        final groupsJson = json['groups'] as List<dynamic>? ?? [];
        final groups = groupsJson.map((g) {
          final subgroupsJson = g['subgroups'] as List<dynamic>? ?? [];
          final subgroups = subgroupsJson.map((s) {
            final itemsJson = s['items'] as List<dynamic>? ?? [];
            final items = itemsJson.map((i) => ChecklistItem.fromJson(i)).toList();
            return ChecklistSubgroup.fromJson(s, items);
          }).toList();

          return ChecklistGroup.fromJson(g, subgroups);
        }).toList();

        return Checklist.fromJson(json, groups);
      }).toList();

      print('✅ [ChecklistProvider] ${_checklists.length} checklists carregados');
      for (var c in _checklists) {
        print('   Checklist: ${c.name} | Grupos: ${c.groups.length}');
        for (var g in c.groups) {
          print('      → Grupo: ${g.title} | Subgrupos: ${g.subgroups.length}');
        }
      }
    } catch (e, stack) {
      _error = 'Erro ao carregar checklists: $e';
      print('❌ [ChecklistProvider] Erro ao carregar: $e');
      print('Stack: $stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== CRIAÇÃO ====================
  // ==================== CRIAÇÃO (Novo Checklist) ====================
  Future<void> addChecklist(String checklistName, List<ChecklistGroup> groups) async {
    print('🔄 [ChecklistProvider] Criando novo checklist: $checklistName');

    try {
      // Cria o checklist pai
      final checklistResponse = await _supabase
          .from('checklists')
          .insert({
        'name': checklistName,
        'order_index': _checklists.length,
      })
          .select()
          .single();

      final checklistId = checklistResponse['id'] as int;

      await _saveGroupsAndChildren(checklistId, groups);

      print('✅ Checklist criado com sucesso!');
      await loadChecklists();
    } catch (e, stack) {
      print('❌ Erro ao criar checklist: $e');
      rethrow;
    }
  }

// ==================== ATUALIZAÇÃO (Editar Checklist) ====================
  Future<void> updateChecklist(
      int checklistId,
      String newName,
      List<ChecklistGroup> newGroups,
      ) async {
    print('🔄 [ChecklistProvider] Atualizando checklist ID: $checklistId');

    try {
      // 1. Atualiza apenas o nome do checklist
      await _supabase
          .from('checklists')
          .update({'name': newName})
          .eq('id', checklistId);

      // 2. Deleta toda a estrutura antiga (grupos + subgrupos + itens)
      await _supabase
          .from('checklist_groups')
          .delete()
          .eq('checklist_id', checklistId);

      // 3. Recria os grupos, subgrupos e itens
      await _saveGroupsAndChildren(checklistId, newGroups);

      print('✅ Checklist atualizado com sucesso!');
      await loadChecklists();
    } catch (e, stack) {
      print('❌ Erro ao atualizar checklist: $e');
      rethrow;
    }
  }

// ==================== MÉTODO PRIVADO REUTILIZÁVEL ====================
  Future<void> _saveGroupsAndChildren(int checklistId, List<ChecklistGroup> groups) async {
    for (int g = 0; g < groups.length; g++) {
      final group = groups[g];

      final groupResponse = await _supabase
          .from('checklist_groups')
          .insert({
        'checklist_id': checklistId,
        'title': group.title,
        'order_index': g,
      })
          .select()
          .single();

      final groupId = groupResponse['id'] as int;

      for (int i = 0; i < group.subgroups.length; i++) {
        final subgroup = group.subgroups[i];

        final subgroupResponse = await _supabase
            .from('checklist_subgroups')
            .insert({
          'group_id': groupId,
          'title': subgroup.title,
          'order_index': i,
        })
            .select()
            .single();

        final subgroupId = subgroupResponse['id'] as int;

        for (int j = 0; j < subgroup.items.length; j++) {
          final item = subgroup.items[j];

          await _supabase.from('checklist_items').insert({
            'subgroup_id': subgroupId,
            'title': item.title,
            'type': item.type,
            'is_required': item.isRequired,
            'order_index': j,
          });
        }
      }
    }
  }

  // No ChecklistProvider.dart
  // ==================== EXCLUSÃO ====================
  Future<void> deleteChecklist(int checklistId) async {
    print('🗑️ [ChecklistProvider] Excluindo checklist ID: $checklistId');

    try {
      // Deleta primeiro os grupos (filhos)
      await _supabase
          .from('checklist_groups')
          .delete()
          .eq('checklist_id', checklistId);

      // Depois deleta o checklist pai
      await _supabase
          .from('checklists')
          .delete()
          .eq('id', checklistId);

      print('✅ Checklist excluído com sucesso');
      await loadChecklists(); // Recarrega a lista
    } catch (e, stack) {
      print('❌ Erro ao excluir checklist: $e');
      print(stack);
      rethrow;
    }
  }

  // ==================== EXECUÇÃO ====================
  Future<int?> getOrStartExecution(int phaseConfigId, int clientId) async {
    print('🔄 [ChecklistProvider] getOrStartExecution - Fase: $phaseConfigId | Cliente: $clientId');

    try {
      final existing = await _supabase
          .from('checklist_executions')
          .select('id, status')
          .eq('phase_config_id', phaseConfigId)
          .eq('client_id', clientId)
          .maybeSingle();

      if (existing != null) {
        print('✅ Execução existente encontrada: ${existing['id']}');
        return existing['id'] as int;
      }

      final response = await _supabase
          .from('checklist_executions')
          .insert({
        'phase_config_id': phaseConfigId,
        'client_id': clientId,
        'status': 'pendente',
        'executed_at': DateTime.now().toIso8601String(),
        'is_completed': false,
      })
          .select()
          .single();

      print('✅ Nova execução criada com ID: ${response['id']}');
      return response['id'] as int;
    } catch (e) {
      print('❌ Erro ao iniciar execução: $e');
      return null;
    }
  }

  // ==================== SALVAR EXECUÇÃO COMPLETA ====================
  // Dentro da classe ChecklistProvider

  // lib/providers/checklist_provider.dart
  // lib/providers/checklist_provider.dart
  Future<int?> saveExecution({
    required int phaseConfigId,
    required int clientId,
    required int? employeeId,
    required Map<String, Map<String, List<Map<String, dynamic>>>> executionData,
    required Map<String, bool> naGroups,
    required String? responsibleName,
    required String? responsibleContact,
  }) async {
    try {
      print('🔄 Salvando execução completa...');

      // Calcular status automaticamente
      bool hasAnyNao = false;
      executionData.forEach((_, subgroups) {
        subgroups.forEach((_, items) {
          for (var item in items) {
            if ((item['status'] as String).toLowerCase() == 'nao') {
              hasAnyNao = true;
            }
          }
        });
      });

      final status = hasAnyNao ? 'pendente' : 'concluido';
      final isCompleted = !hasAnyNao;

      // 1. Primeiro tentamos atualizar se já existir
      final existing = await _supabase
          .from('checklist_executions')
          .select('id')
          .eq('phase_config_id', phaseConfigId)
          .eq('client_id', clientId)
          .maybeSingle();

      int executionId;

      if (existing != null) {
        // Atualiza execução existente
        await _supabase
            .from('checklist_executions')
            .update({
          'executed_by_id': employeeId,
          'status': status,
          'is_completed': isCompleted,
          'executed_at': DateTime.now().toIso8601String(),
          'responsible_name': responsibleName,
          'responsible_contact': responsibleContact,
        })
            .eq('id', existing['id']);

        executionId = existing['id'] as int;
        print('🔄 Execução existente atualizada (ID: $executionId)');
      } else {
        // Insere nova execução
        final response = await _supabase
            .from('checklist_executions')
            .insert({
          'phase_config_id': phaseConfigId,
          'client_id': clientId,
          'executed_by_id': employeeId,
          'status': status,
          'is_completed': isCompleted,
          'executed_at': DateTime.now().toIso8601String(),
          'responsible_name': responsibleName,
          'responsible_contact': responsibleContact,
        })
            .select()
            .single();

        executionId = response['id'] as int;
        print('✅ Nova execução criada (ID: $executionId)');
      }

      // 2. Deletar itens antigos
      await _supabase
          .from('checklist_execution_items')
          .delete()
          .eq('execution_id', executionId);

      // 3. Inserir novos itens
      List<Map<String, dynamic>> itemsToInsert = [];

      for (var groupEntry in executionData.entries) {
        final isGroupNA = naGroups[groupEntry.key] ?? false;

        for (var subEntry in groupEntry.value.entries) {
          for (var item in subEntry.value) {
            itemsToInsert.add({
              'execution_id': executionId,
              'checklist_item_id': item['id'],
              'status': item['status'],
              'observation': item['observation'] ?? '',
              'photos': item['photos'] ?? [],
              'is_group_na': isGroupNA,
            });
          }
        }
      }

      if (itemsToInsert.isNotEmpty) {
        await _supabase.from('checklist_execution_items').insert(itemsToInsert);
      }

      print('✅ Execução salva com sucesso! ID: $executionId | Status: $status');
      return executionId;

    } catch (e, stack) {
      print('❌ Erro ao salvar execução: $e');
      print('Stack: $stack');
      rethrow;
    }
  }


  void clearError() {
    _error = null;
    notifyListeners();
  }
}