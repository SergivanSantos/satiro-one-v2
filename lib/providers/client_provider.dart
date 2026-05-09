// lib/providers/client_provider.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/client_phase_config.dart';
import '../providers/employee_provider.dart';
import 'client_phase_config_provider.dart';

class ClientProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Client> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ClientProvider() {
    // Não chamamos fetch aqui para evitar context inválido
  }

  Future<void> fetchClients([BuildContext? context]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    print('🔄 [ClientProvider] Iniciando fetchClients...');

    try {
      final employee = context != null
          ? Provider.of<EmployeeProvider>(context, listen: false).currentEmployee
          : null;

      final nonSuperRoles = ['admin', 'rh', 'supervisor', 'vendas', 'tecnico'];

      String? branchFilter;
      if (employee != null && nonSuperRoles.contains(employee.role?.toLowerCase() ?? '')) {
        branchFilter = employee.branchId;
        print('📍 [ClientProvider] Filtrando por filial: $branchFilter');
      }

      // Query com join das fases
      print('📡 [ClientProvider] Executando query com join de phases...');
      final response = await _supabase
          .from('clients')
          .select('*, phases:client_phases(*)')
          .order('name');

      _clients = (response as List<dynamic>)
          .map((json) => Client.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [ClientProvider] ${_clients.length} clientes carregados com sucesso');

      // Log detalhado dos primeiros 3 clientes (para não poluir o console)
      for (var client in _clients.take(3)) {
        final currentPhaseId = client.currentPhaseId;
        final phasesCount = client.phases.length;
        print('   → Cliente "${client.name}" | current_phase_id: $currentPhaseId | fases vinculadas: $phasesCount');
      }

    } catch (e, stack) {
      _errorMessage = 'Erro ao carregar clientes: $e';
      print('❌ [ClientProvider] Erro ao carregar clientes: $e');
      print(stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    notifyListeners(); // Força rebuild dos listeners

  }

  Future<int?> addClient(Client client) async {
    try {
      print('🔄 [ClientProvider] Adicionando novo cliente: ${client.name}');

      final response = await _supabase
          .from('clients')
          .insert(client.toJson(excludeId: true))
          .select()
          .single();

      final newClient = Client.fromJson(response);
      _clients.add(newClient);

      print('✅ [ClientProvider] Novo cliente criado - ID: ${newClient.id}');
      _errorMessage = null;

      return newClient.id;
    } catch (e) {
      print('❌ [ClientProvider] Erro ao adicionar cliente: $e');
      _errorMessage = 'Erro ao adicionar cliente: $e';
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateClient(Client client) async {
    if (client.id == null) {
      print('⚠️ [ClientProvider] updateClient ignorado: ID nulo');
      return;
    }

    try {
      print('🔄 [ClientProvider] Atualizando cliente ID: ${client.id} - Nome: ${client.name}');

      final updateMap = client.toJson();
      updateMap.remove('id');

      print('📤 [ClientProvider] Dados enviados para update: $updateMap');

      await _supabase
          .from('clients')
          .update(updateMap)
          .eq('id', client.id!);

      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        print('✅ [ClientProvider] Cliente atualizado na lista local');
      }

      print('✅ [ClientProvider] Update concluído com sucesso para cliente ${client.id}');
      _errorMessage = null;
    } catch (e) {
      print('❌ [ClientProvider] Erro ao atualizar cliente: $e');
      _errorMessage = 'Erro ao atualizar cliente: $e';
    }
    notifyListeners();
  }

  Future<void> deleteClient(int id) async {
    try {
      print('🗑️ [ClientProvider] Excluindo cliente ID: $id');
      await _supabase.from('clients').delete().eq('id', id);
      _clients.removeWhere((c) => c.id == id);
      print('✅ [ClientProvider] Cliente excluído - ID: $id');
      _errorMessage = null;
    } catch (e) {
      print('❌ [ClientProvider] Erro ao excluir cliente: $e');
      _errorMessage = 'Erro ao excluir cliente: $e';
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ====================== VINCULAR FASES AO CLIENTE ======================
  // ====================== VINCULAR FASES AO CLIENTE (LIMPA ANTES) ======================
  Future<void> vincularFasesAoCliente(int clientId, List<int> phaseConfigIds, List<ClientPhaseConfig> phaseConfigs) async {
    try {
      print('🔄 [VINCULAR FASES] Iniciando para cliente $clientId com ${phaseConfigIds.length} fases');

      // 1. Remove todas as fases antigas deste cliente
      await _supabase.from('client_phases').delete().eq('client_id', clientId);
      print('🗑️ [VINCULAR FASES] Fases antigas removidas');

      if (phaseConfigIds.isEmpty) {
        print('⚠️ [VINCULAR FASES] Nenhuma fase para vincular');
        return;
      }

      final inserts = <Map<String, dynamic>>[];

      for (int i = 0; i < phaseConfigIds.length; i++) {
        final phaseId = phaseConfigIds[i];
        final config = phaseConfigs.firstWhereOrNull((p) => p.id == phaseId);
        if (config == null) continue;

        inserts.add({
          'client_id': clientId,
          'phase_config_id': phaseId,
          'phase_order': config.phaseOrder,
          'status': 'pendente',
          'start_date': DateTime.now().toIso8601String(),
        });
      }

      if (inserts.isEmpty) return;

      await _supabase.from('client_phases').insert(inserts);

      print('✅ [VINCULAR FASES] ${inserts.length} fases vinculadas com sucesso ao cliente $clientId');
    } catch (e) {
      print('❌ [VINCULAR FASES] Erro: $e');
    }
  }

  // ====================== DEFINIR FASE ATUAL ======================
  Future<void> setCurrentPhase(int clientId, int phaseConfigId) async {
    try {
      print('🔄 [SET CURRENT PHASE] Iniciando: clientId=$clientId, phaseConfigId=$phaseConfigId');

      // 1. Atualiza o current_phase_id na tabela clients
      await _supabase
          .from('clients')
          .update({'current_phase_id': phaseConfigId})
          .eq('id', clientId);

      print('✅ [SET CURRENT PHASE] current_phase_id atualizado na tabela clients');

      // 2. Atualiza o status da fase específica
      await _supabase
          .from('client_phases')
          .update({
        'status': 'em_andamento',
        'start_date': DateTime.now().toIso8601String(),
      })
          .eq('client_id', clientId)
          .eq('phase_config_id', phaseConfigId);

      // 3. Coloca as outras fases como 'pendente'
      await _supabase
          .from('client_phases')
          .update({'status': 'pendente'})
          .eq('client_id', clientId)
          .neq('phase_config_id', phaseConfigId);

      print('✅ [SET CURRENT PHASE] Status das fases atualizado com sucesso');

      // Recarrega os clientes
      await fetchClients(null);
    } catch (e) {
      print('❌ [SET CURRENT PHASE] Erro: $e');
    }
  }




}