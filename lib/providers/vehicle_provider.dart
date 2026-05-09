// lib/providers/vehicle_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

import '../models/vehicle.dart';
import '../providers/employee_provider.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final SupabaseClient _supabase = Supabase.instance.client;

  VehicleProvider() {
    developer.log('VehicleProvider: Instância criada');
  }

  // ==================== CARREGAR VEÍCULOS ====================
  Future<void> fetchVehicles(BuildContext context) async {
    developer.log('VehicleProvider: fetchVehicles chamado');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final isSuper = employeeProvider.isSuper;
      final currentBranchId = employeeProvider.currentEmployee?.branchId;

      developer.log('VehicleProvider: isSuper = $isSuper | branchId atual = $currentBranchId');

      var query = _supabase
          .from('vehicles')
          .select('*, branch:branches(name)')
          .eq('ativo', true);

      if (!isSuper && currentBranchId != null && currentBranchId.isNotEmpty) {
        query = query.eq('branch_id', currentBranchId);
        developer.log('VehicleProvider: Usuário normal → filtrando pela filial $currentBranchId');
      } else {
        developer.log('VehicleProvider: Super user → carregando TODOS os veículos');
      }

      final response = await query.order('placa', ascending: true);

      _vehicles = response.map((json) => Vehicle.fromJson(json)).toList();

      developer.log('VehicleProvider: ${_vehicles.length} veículos carregados com sucesso');
    } catch (e) {
      developer.log('VehicleProvider: ERRO ao carregar veículos: $e');
      _errorMessage = 'Erro ao carregar veículos: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== ATUALIZAR VEÍCULO (AGORA ENVIA TODOS OS CAMPOS DO MODELO) ====================
  Future<void> updateVehicle(BuildContext context, Vehicle vehicle) async {
    if (vehicle.id == null) {
      developer.log('ERRO: ID do veículo é null');
      return;
    }

    try {
      final updateData = {
        'placa': vehicle.placa?.toUpperCase(),
        'modelo': vehicle.modelo,
        'ano': vehicle.ano,
        'cor': vehicle.cor,
        'odometro_inicial': vehicle.odometroInicial,
        'odometro_devolucao': vehicle.odometroDevolucao,
        'capacidade': vehicle.capacidade,
        'observacoes': vehicle.observacoes,
        'status': vehicle.status,
        'id_tecnico': vehicle.idTecnico,
        'branch_id': vehicle.branchId,
        'ativo': true,
        // Campos de franquia (agora incluídos corretamente)
        'km_contratado_mensal': vehicle.kmContratadoMensal,
        'km_inicial_mes_atual': vehicle.kmInicialMesAtual,
        'mes_ano_referencia': vehicle.mesAnoReferencia,
        'data_retirada': vehicle.dataRetirada?.toUtc().toIso8601String(),
        'data_devolucao': vehicle.dataDevolucao?.toUtc().toIso8601String(),
      };

      developer.log('VehicleProvider: Enviando update para ID ${vehicle.id} com dados: $updateData');

      await _supabase.from('vehicles').update(updateData).eq('id', vehicle.id!);

      developer.log('VehicleProvider: Veículo ${vehicle.id} atualizado com sucesso');
      await fetchVehicles(context);
    } catch (e) {
      developer.log('VehicleProvider: ERRO ao atualizar veículo: $e');
      rethrow;
    }
  }


  // ==================== ADICIONAR VEÍCULO (SEM ENVIAR O ID) ====================
  Future<int> addVehicle(BuildContext context, Vehicle vehicle) async {
    try {
      // Cria o mapa de inserção SEM o campo 'id' (o banco gera sozinho)
      final insertData = vehicle.toJson()
        ..remove('id')  // Garante que 'id' não vá no insert
        ..['ativo'] = true;

      developer.log('VehicleProvider: Enviando insert com dados (sem id): $insertData');

      // Insere e retorna o ID gerado automaticamente
      final response = await _supabase
          .from('vehicles')
          .insert(insertData)
          .select('id')
          .single();

      final newId = response['id'] as int;
      developer.log('VehicleProvider: Veículo adicionado com ID $newId');

      // Recarrega a lista para atualizar a UI
      await fetchVehicles(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo adicionado com sucesso!'), backgroundColor: Colors.green),
      );

      return newId;
    } catch (e) {
      developer.log('VehicleProvider: ERRO ao adicionar veículo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar veículo: $e'), backgroundColor: Colors.red),
      );
      rethrow;
    }
  }

  // ==================== ATRIBUIR VEÍCULO ====================
  Future<void> assignVehicleToTechnician({
    required BuildContext context,
    required int vehicleId,
    required int technicianId,
    required int odometro,
  }) async {
    try {
      await _supabase.from('vehicles').update({
        'id_tecnico': technicianId,
        'data_retirada': DateTime.now().toUtc().toIso8601String(),
        'odometro_inicial': odometro,
        'status': 'em_uso',
      }).eq('id', vehicleId);

      await fetchVehicles(context);
    } catch (e) {
      developer.log('Erro ao atribuir veículo: $e');
      rethrow;
    }
  }

  // ==================== DEVOLVER VEÍCULO ====================
  Future<void> returnVehicle(BuildContext context, int vehicleId, int odometroDevolucao) async {
    try {
      await _supabase.from('vehicles').update({
        'id_tecnico': null,
        'data_devolucao': DateTime.now().toUtc().toIso8601String(),
        'odometro_devolucao': odometroDevolucao,
        'status': 'disponivel',
      }).eq('id', vehicleId);

      await fetchVehicles(context);
    } catch (e) {
      developer.log('Erro ao devolver veículo: $e');
      rethrow;
    }
  }

  // ==================== EXCLUIR VEÍCULO ====================
  Future<void> deleteVehicle(BuildContext context, int id) async {
    try {
      await _supabase.from('vehicles').update({'ativo': false}).eq('id', id);
      await fetchVehicles(context);
    } catch (e) {
      developer.log('Erro ao desativar veículo: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    developer.log('VehicleProvider: Disposing...');
    super.dispose();
  }
}