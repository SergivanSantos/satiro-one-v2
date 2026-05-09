// lib/providers/employee_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  EmployeeProvider() {
    print('EmployeeProvider: Instância criada');
    // Delay para garantir inicialização do Supabase
    Future.delayed(const Duration(milliseconds: 200), () {
      print('EmployeeProvider: Iniciando setup do stream realtime...');
      _setupRealtimeStream();
    });
  }

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _setupRealtimeStream() {
    print('EmployeeProvider: Cancelando subscription anterior (se existir)');
    _subscription?.cancel();

    print('EmployeeProvider: Configurando stream na tabela employees...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = supabase
        .from('employees')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .listen(
          (List<Map<String, dynamic>> data) {
        print('EmployeeProvider: Stream recebeu dados! Quantidade: ${data.length}');
        for (var map in data) {
          print('   → Funcionário recebido: ${map['name']} (ID: ${map['id']})');
        }

        _employees = data.map((map) {
          try {
            return Employee.fromMap(map);
          } catch (e) {
            print('EmployeeProvider: Erro ao converter mapa para Employee: $e');
            print('   Mapa problemático: $map');
            rethrow;
          }
        }).toList();

        _isLoading = false;
        _errorMessage = null;
        print('EmployeeProvider: Lista atualizada com ${_employees.length} funcionários. Notificando listeners...');
        notifyListeners();
      },
      onError: (error) {
        print('EmployeeProvider: ERRO NO STREAM REALTIME: $error');
        _errorMessage = 'Erro na conexão realtime: $error';
        _isLoading = false;
        notifyListeners();
      },
      onDone: () {
        print('EmployeeProvider: Stream fechado (onDone)');
      },
    );

    print('EmployeeProvider: Stream configurado com sucesso');
  }

  void refresh() {
    print('EmployeeProvider: refresh() chamado manualmente');
    notifyListeners();
  }

  Future<void> saveEmployee(Employee employee) async {
    try {
      final map = employee.toMap();
      print('EmployeeProvider: Salvando funcionário: ${employee.name}');

      if (employee.id == null) {
        map.remove('id');
        print('   → INSERT no Supabase');
        await supabase.from('employees').insert(map);
        print('   → INSERT concluído com sucesso');
      } else {
        map.remove('id');
        print('   → UPDATE no Supabase (ID: ${employee.id})');
        await supabase.from('employees').update(map).eq('id', employee.id!);
        print('   → UPDATE concluído com sucesso');
      }
    } catch (e) {
      print('EmployeeProvider: ERRO ao salvar funcionário: $e');
      _errorMessage = 'Erro ao salvar funcionário: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setAfastamento(
      int employeeId, {
        required String motivo,
        DateTime? inicio,
        DateTime? fim,
        bool isDesligamento = false,
      }) async {
    try {
      print('EmployeeProvider: Registrando afastamento ($motivo) para ID $employeeId');
      final updateMap = {
        'status_afastamento': motivo,
        'data_inicio_afastamento': inicio?.toIso8601String(),
        'data_fim_afastamento': fim?.toIso8601String(),
        if (isDesligamento) 'is_active': false,
      };
      await supabase.from('employees').update(updateMap).eq('id', employeeId);
      print('   → Afastamento registrado com sucesso');
    } catch (e) {
      print('EmployeeProvider: Erro ao registrar afastamento: $e');
      _errorMessage = 'Erro ao registrar afastamento: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> retornarFuncionario(int employeeId) async {
    try {
      print('EmployeeProvider: Retornando funcionário ID $employeeId');
      await supabase.from('employees').update({
        'status_afastamento': null,
        'data_inicio_afastamento': null,
        'data_fim_afastamento': null,
        'is_active': true,
      }).eq('id', employeeId);
      print('   → Retorno concluído');
    } catch (e) {
      print('EmployeeProvider: Erro ao retornar funcionário: $e');
      _errorMessage = 'Erro ao retornar funcionário: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      print('EmployeeProvider: Excluindo funcionário ID $id');
      await supabase.from('employees').delete().eq('id', id);
      print('   → Exclusão concluída');
    } catch (e) {
      print('EmployeeProvider: Erro ao excluir: $e');
      _errorMessage = 'Erro ao excluir funcionário: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> desligarFuncionario(int employeeId, {required DateTime dataSaida, required String motivo}) async {
    try {
      await supabase.from('employees').update({
        'is_active': false,
        'data_saida': dataSaida.toIso8601String(),
        'motivo_saida': motivo,
        'status_afastamento': null,
        'data_inicio_afastamento': null,
        'data_fim_afastamento': null,
      }).eq('id', employeeId);
    } catch (e) {
      rethrow;
    }
  }
  void clearError() {
    print('EmployeeProvider: Limpando erro');
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print('EmployeeProvider: Disposing... Cancelando stream');
    _subscription?.cancel();
    super.dispose();
  }
}