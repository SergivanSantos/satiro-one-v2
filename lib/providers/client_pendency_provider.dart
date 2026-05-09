// lib/providers/client_pendency_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client_pendency.dart';

class ClientPendencyProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<int, List<ClientPendency>> _pendenciesByClient = {};

  bool _isLoading = false;
  String? _error;

  List<ClientPendency> get allPendencies => _pendenciesByClient.values.expand((list) => list).toList();

  List<ClientPendency> pendenciesForClient(int clientId) => _pendenciesByClient[clientId] ?? [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPendencyForClient(int clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('client_pendencies')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      final newList = response.map((json) => ClientPendency.fromJson(json)).toList();
      _pendenciesByClient[clientId] = newList;
    } catch (e) {
      _error = 'Erro ao carregar pendências do cliente $clientId: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPendency(int clientId, String description, String priority, int createdBy) async {
    try {
      final response = await _supabase
          .from('client_pendencies')
          .insert({
        'client_id': clientId,
        'description': description,
        'priority': priority,
        'created_by': createdBy,
      })
          .select()
          .single();

      final newPendency = ClientPendency.fromJson(response);

      _pendenciesByClient.putIfAbsent(clientId, () => []).insert(0, newPendency);
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar pendência: $e');
    }
  }

  /// NOVO MÉTODO: Atualiza a prioridade da pendência
  Future<void> updatePendencyPriority(int pendencyId, String newPriority) async {
    try {
      await _supabase
          .from('client_pendencies')
          .update({'priority': newPriority})
          .eq('id', pendencyId);

      // Atualiza localmente em todos os mapas
      for (var entry in _pendenciesByClient.entries) {
        final list = entry.value;
        final index = list.indexWhere((p) => p.id == pendencyId);
        if (index != -1) {
          list[index] = ClientPendency(
            id: list[index].id,
            clientId: list[index].clientId,
            description: list[index].description,
            priority: newPriority,
            status: list[index].status,
            createdAt: list[index].createdAt,
            createdBy: list[index].createdBy,
            resolvedAt: list[index].resolvedAt,
            resolvedBy: list[index].resolvedBy,
            updatedAt: DateTime.now(),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      print('Erro ao atualizar prioridade: $e');
      throw Exception('Falha ao atualizar prioridade');
    }
  }

  Future<void> deletePendency(int pendencyId) async {
    try {
      await _supabase.from('client_pendencies').delete().eq('id', pendencyId);

      for (var list in _pendenciesByClient.values) {
        list.removeWhere((p) => p.id == pendencyId);
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Erro ao excluir pendência: $e');
    }
  }

  Future<void> resolvePendency(int pendencyId, int resolvedBy) async {
    try {
      await _supabase
          .from('client_pendencies')
          .update({
        'status': 'resolvida',
        'resolved_at': DateTime.now().toIso8601String(),
        'resolved_by': resolvedBy,
      })
          .eq('id', pendencyId);

      for (var entry in _pendenciesByClient.entries) {
        final list = entry.value;
        final index = list.indexWhere((p) => p.id == pendencyId);
        if (index != -1) {
          list[index] = ClientPendency(
            id: list[index].id,
            clientId: list[index].clientId,
            description: list[index].description,
            priority: list[index].priority,
            status: 'resolvida',
            createdAt: list[index].createdAt,
            createdBy: list[index].createdBy,
            resolvedAt: DateTime.now(),
            resolvedBy: resolvedBy,
            updatedAt: DateTime.now(),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      print('Erro ao resolver pendência: $e');
    }
  }

  Future<void> updatePendencyDescription(int pendencyId, String newDescription) async {
    try {
      await _supabase
          .from('client_pendencies')
          .update({'description': newDescription})
          .eq('id', pendencyId);

      for (var entry in _pendenciesByClient.entries) {
        final list = entry.value;
        final index = list.indexWhere((p) => p.id == pendencyId);
        if (index != -1) {
          list[index] = ClientPendency(
            id: list[index].id,
            clientId: list[index].clientId,
            description: newDescription,
            priority: list[index].priority,
            status: list[index].status,
            createdAt: list[index].createdAt,
            createdBy: list[index].createdBy,
            resolvedAt: list[index].resolvedAt,
            resolvedBy: list[index].resolvedBy,
            updatedAt: DateTime.now(),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      print('Erro ao atualizar descrição: $e');
      throw Exception('Falha ao atualizar descrição');
    }
  }

  void clearPendencies() {
    _pendenciesByClient.clear();
    notifyListeners();
  }
}