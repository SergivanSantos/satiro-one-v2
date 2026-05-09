// lib/providers/travel_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TravelProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> get requests => _requests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadRequests() async {
    print('🔄 [LOAD] Iniciando carregamento de solicitações...');
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('travel_requests')
          .select('*, client:clients(name), vehicle:vehicles(placa, modelo)')
          .order('created_at', ascending: false);

      _requests = List<Map<String, dynamic>>.from(data);
      print('✅ [LOAD] ${_requests.length} solicitações carregadas com sucesso');
      print('📋 IDs carregados: ${_requests.map((r) => r['id']).toList()}');
    } catch (e, stack) {
      print('❌ [LOAD] Erro ao carregar solicitações: $e');
      print('🔍 Stack trace: $stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    print('🔍 [GET-BY-ID] Buscando solicitação ID: $id');
    try {
      final data = await _supabase
          .from('travel_requests')
          .select('*, client:clients(name), vehicle:vehicles(placa, modelo)')
          .eq('id', int.parse(id))
          .single();

      print('✅ [GET-BY-ID] Solicitação ID $id carregada com sucesso');
      return data;
    } catch (e, stack) {
      print('❌ [GET-BY-ID] Erro ao buscar solicitação $id: $e');
      print('🔍 Stack trace: $stack');
      return null;
    }
  }

  Future<String?> create(Map<String, dynamic> data) async {
    print('➕ [CREATE] Iniciando criação');
    print('📤 Dados enviados: $data');
    try {
      final response = await _supabase.from('travel_requests').insert(data).select().single();
      await loadRequests();
      print('✅ [CREATE] Nova solicitação criada com ID: ${response['id']}');
      return response['id'].toString();
    } catch (e, stack) {
      print('❌ [CREATE] Erro ao criar: $e');
      print('🔍 Stack trace: $stack');
      return null;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    print('🖊️ [UPDATE] Atualizando ID: $id');
    print('📤 Dados: $data');
    try {
      await _supabase.from('travel_requests').update(data).eq('id', int.parse(id));
      await loadRequests();
      print('✅ [UPDATE] ID $id atualizada com sucesso');
      return true;
    } catch (e, stack) {
      print('❌ [UPDATE] Erro: $e');
      print('🔍 Stack trace: $stack');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    print('🗑️ [DELETE] Iniciando exclusão ID: $id');
    final intBefore = _requests.length;

    try {
      await _supabase.from('travel_requests').delete().eq('id', int.parse(id));
      print('✅ [DELETE] Exclusão realizada no Supabase ID: $id');

      _requests.removeWhere((req) => req['id'].toString() == id);

      final intAfter = _requests.length;
      final removedCount = intBefore - intAfter;

      print('✅ [DELETE] Removido do cache. Removidos: $removedCount | Restante: $intAfter');

      notifyListeners();
      await loadRequests();

      return true;
    } catch (e, stack) {
      print('❌ [DELETE] Erro ao excluir ID $id: $e');
      print('🔍 Stack trace: $stack');
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    print('🔄 [UPDATE-STATUS] ID: $id → $status');
    try {
      await _supabase.from('travel_requests').update({'status': status}).eq('id', int.parse(id));
      await loadRequests();
      print('✅ [UPDATE-STATUS] Status alterado');
      return true;
    } catch (e, stack) {
      print('❌ [UPDATE-STATUS] Erro: $e');
      print('🔍 Stack trace: $stack');
      return false;
    }
  }
}