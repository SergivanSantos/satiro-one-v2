// lib/providers/sac_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sac_call.dart';

class SacProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<SacCall> _allCalls = [];           // Todos os chamados (SAC e histórico)
  List<SacCall> _assignedCalls = [];      // Apenas atribuídos ao técnico atual (pendentes)
  bool _isLoading = false;
  String? _error;

  Timer? _pollingTimer;

  List<SacCall> get calls => _allCalls;
  List<SacCall> get assignedCalls => _assignedCalls;

  bool get isLoading => _isLoading;
  String? get error => _error;

  SacProvider() {
    print('SacProvider: Instância criada');
  }

  // Carrega TODOS os chamados (para tela SAC e histórico)
  Future<void> fetchCalls() async {
    print('SacProvider: Iniciando fetchCalls() - todos os chamados');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('sac_calls')
          .select('*, clients(name, obra), employees(name)')
          .order('opened_at', ascending: false);

      _allCalls = response.map((json) => SacCall.fromJson(json)).toList();
      print('SacProvider: Sucesso! ${_allCalls.length} chamados totais carregados');
    } catch (e) {
      print('SacProvider: Erro ao carregar todos os chamados: $e');
      _error = 'Erro ao carregar chamados: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Carrega apenas os chamados pendentes atribuídos ao técnico
  Future<void> fetchAssignedCalls(int employeeId) async {
    if (employeeId == 0) {
      print('SacProvider: employeeId 0 - ignorando fetchAssignedCalls');
      return;
    }

    print('SacProvider: Iniciando fetchAssignedCalls para employeeId $employeeId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('sac_calls')
          .select('*, clients(name, obra)')
          .eq('assigned_employee_id', employeeId)
          .inFilter('status', ['aberto', 'alocado', 'em_andamento'])
          .order('opened_at', ascending: false);

      _assignedCalls = response.map((json) => SacCall.fromJson(json)).toList();
      print('SacProvider: Sucesso! ${_assignedCalls.length} chamados pendentes para o técnico $employeeId');
    } catch (e) {
      print('SacProvider: Erro ao carregar chamados atribuídos: $e');
      _error = 'Erro ao carregar chamados atribuídos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== REALTIME CORRIGIDO (escuta TODAS as mudanças) ====================
  void listenToAssignedCalls(int employeeId, BuildContext context) {
    if (employeeId == 0) {
      print('SacProvider: employeeId 0 - realtime ignorado');
      return;
    }

    print('SacProvider: Iniciando REALTIME otimizado para employeeId $employeeId');

    _supabase
        .channel('assigned_calls_channel_$employeeId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sac_calls',
      callback: (payload) async {
        print('SacProvider: 🔥 REALTIME EVENTO RECEBIDO! Tipo: ${payload.eventType} | ID: ${payload.newRecord?['id'] ?? payload.oldRecord?['id'] ?? "N/A"}');

        // Sempre atualiza a lista do técnico (atribuição OU remoção)
        print('SacProvider: Chamando fetchAssignedCalls após realtime...');
        await fetchAssignedCalls(employeeId);
        print('SacProvider: fetchAssignedCalls finalizado após realtime');
      },
    )
        .subscribe((status, [error]) {
      print('SacProvider: Realtime status: $status');
      if (error != null) {
        print('SacProvider: ERRO NO REALTIME: $error');
      } else if (status == RealtimeSubscribeStatus.subscribed) {
        print('SacProvider: REALTIME CONECTADO COM SUCESSO');
      }
    });
  }

  // Para parar realtime e polling (chame no dispose da tela ou logout)
  void stopListening(int employeeId) {
    _supabase.channel('assigned_calls_channel_$employeeId').unsubscribe();
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('SacProvider: Realtime + polling parados para employee $employeeId');
  }

  // Adicionar chamado
  Future<void> addCall(SacCall call) async {
    print('SacProvider: Iniciando addCall');

    try {
      final json = call.toJson(forInsert: true);

      print('SacProvider: JSON enviado para insert: $json');

      final response = await _supabase
          .from('sac_calls')
          .insert(json)
          .select()
          .single();

      final newCall = SacCall.fromJson(response);

      _allCalls.insert(0, newCall);
      notifyListeners();

      print('SacProvider: Novo chamado criado - ID: ${newCall.id}');
    } catch (e) {
      print('SacProvider: Erro ao criar chamado: $e');
      _error = 'Erro ao criar chamado: $e';
      notifyListeners();
    }
  }

  // Atualizar chamado
  Future<void> updateCall(SacCall call) async {
    if (call.id == null) {
      print('SacProvider: updateCall ignorado - ID nulo');
      return;
    }

    print('SacProvider: Iniciando updateCall - ID: ${call.id}');

    try {
      await _supabase
          .from('sac_calls')
          .update(call.toJson())
          .eq('id', call.id!);

      final indexAll = _allCalls.indexWhere((c) => c.id == call.id);
      if (indexAll != -1) _allCalls[indexAll] = call;

      final indexAssigned = _assignedCalls.indexWhere((c) => c.id == call.id);
      if (indexAssigned != -1) _assignedCalls[indexAssigned] = call;

      notifyListeners();
      print('SacProvider: Chamado atualizado localmente - ID: ${call.id}');
    } catch (e) {
      print('SacProvider: Erro ao atualizar chamado: $e');
      _error = 'Erro ao atualizar chamado: $e';
      notifyListeners();
    }
  }

  // Excluir chamado
  Future<void> deleteCall(int id) async {
    print('SacProvider: Iniciando deleteCall - ID: $id');
    try {
      await _supabase.from('sac_calls').delete().eq('id', id);
      _allCalls.removeWhere((c) => c.id == id);
      _assignedCalls.removeWhere((c) => c.id == id);
      notifyListeners();
      print('SacProvider: Chamado excluído - ID: $id');
    } catch (e) {
      print('SacProvider: Erro ao excluir chamado: $e');
      _error = 'Erro ao excluir chamado: $e';
      notifyListeners();
    }
  }

  // Chamados de um cliente específico
  Future<List<SacCall>> fetchCallsForClient(int clientId) async {
    print('SacProvider: fetchCallsForClient para clientId $clientId');
    try {
      final response = await _supabase
          .from('sac_calls')
          .select()
          .eq('client_id', clientId)
          .order('opened_at', ascending: false);

      final calls = response.map((json) => SacCall.fromJson(json)).toList();
      print('SacProvider: ${calls.length} chamados encontrados para cliente $clientId');
      return calls;
    } catch (e) {
      print('SacProvider: Erro ao carregar chamados do cliente: $e');
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}