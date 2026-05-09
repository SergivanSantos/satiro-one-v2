// lib/providers/employee_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  Employee? _currentEmployee;
  bool _isLoading = true;
  String? _errorMessage;

  // Proteção contra loop de logout
  bool _isLoggingOut = false;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  EmployeeProvider() {
    print('EmployeeProvider: Instância criada');
    Future.delayed(const Duration(milliseconds: 100), () {
      _setupRealtimeStream();
      loadCurrentEmployee(); // Carrega silenciosamente
    });
  }

  List<Employee> get employees => _employees;
  Employee? get currentEmployee => _currentEmployee;
  bool get isSuper => _currentEmployee?.role?.toLowerCase().startsWith('super_') ?? false;
  bool get isAdmin => _currentEmployee != null && (_currentEmployee!.role?.toLowerCase().contains('admin') ?? false);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _setupRealtimeStream() {
    _subscription?.cancel();

    _subscription = supabase
        .from('employees')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .listen((data) {
      print('EmployeeProvider: Stream recebeu ${data.length} funcionários');
      _employees = data.map((map) => Employee.fromMap(map)).toList();

      if (_currentEmployee != null) {
        final updated = _employees.firstWhere(
              (e) => e.id == _currentEmployee!.id,
          orElse: () => _currentEmployee!,
        );
        if (updated != _currentEmployee) {
          _currentEmployee = updated;
          print('EmployeeProvider: _currentEmployee atualizado via stream');
        }
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // ==================== MÉTODO PÚBLICO ====================
  Future<void> loadCurrentEmployee() async {
    await _loadCurrentEmployee();
  }

  Future<void> _loadCurrentEmployee() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('EmployeeProvider: Nenhum usuário autenticado');
      _currentEmployee = null;
      notifyListeners();
      return;
    }

    await loadEmployeeAfterAuth(user.id);
  }

  Future<void> loadEmployeeAfterAuth(String userId) async {
    try {
      print('EmployeeProvider: Carregando funcionário para supabase_user_id: $userId');

      final response = await supabase
          .from('employees')
          .select()
          .eq('supabase_user_id', userId)
          .maybeSingle();

      if (response == null) {
        print('EmployeeProvider: Nenhum funcionário encontrado');
        _currentEmployee = null;
      } else {
        _currentEmployee = Employee.fromMap(response);
        print('EmployeeProvider: Funcionário atual carregado: ${_currentEmployee!.name} (filial: ${_currentEmployee!.branchId})');
      }
    } catch (e) {
      print('EmployeeProvider: Erro ao carregar funcionário: $e');
      _currentEmployee = null;
    }
    notifyListeners();
  }

  // ==================== LOGIN ====================
  Future<void> login(String email, String password, BuildContext context) async {
    print('Tentativa de login: email = $email');
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) throw Exception('Login falhou');

      await loadEmployeeAfterAuth(response.user!.id);
      print('Login realizado com sucesso: ${_currentEmployee?.name}');
    } catch (e) {
      print('ERRO NO LOGIN: $e');
      rethrow;
    }
  }

  // ==================== LOGOUT (COM PROTEÇÃO ANTI-LOOP) ====================
  Future<void> logout() async {
    if (_isLoggingOut) {
      print('[AUTH] Logout já em andamento - ignorando chamada repetida');
      return;
    }

    _isLoggingOut = true;
    print('[AUTH] Iniciando logout manual...');

    try {
      await supabase.auth.signOut();
      _currentEmployee = null;
      notifyListeners();
      print('[AUTH] Logout realizado com sucesso');
    } catch (e) {
      print('[AUTH] Erro no logout: $e');
    } finally {
      _isLoggingOut = false;
    }
  }

  // ==================== RECUPERAÇÃO DE SENHA ====================
  Future<void> changePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      print('Senha alterada com sucesso');
    } catch (e) {
      print('Erro ao alterar senha: $e');
      _errorMessage = 'Erro ao alterar senha: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ==================== SALVAR FUNCIONÁRIO (COM REGRAS DE FILIAL POR ROLE) ====================
  // ==================== SALVAR FUNCIONÁRIO (COM PROTEÇÃO DE CAMPOS CRÍTICOS) ====================
  Future<void> saveEmployee(Employee employee, {String? password}) async {
    try {
      final map = employee.toMap();
      print('EmployeeProvider: Salvando funcionário: ${employee.name} | Filial enviada: ${employee.branchId}');

      if (employee.id == null) {
        // ==================== NOVO FUNCIONÁRIO ====================
        final current = _currentEmployee;

        if (current == null) {
          throw Exception('Usuário logado não identificado');
        }

        // Se NÃO for super_admin, força a filial do usuário logado
        if (!isSuper) {
          if (current.branchId == null) {
            throw Exception('Usuário logado não possui filial definida');
          }
          map['branch_id'] = current.branchId;
          print('EmployeeProvider: Filial forçada para usuário admin/rh: ${current.branchId}');
        }

        map.remove('id'); // Banco gera o ID

        final response = await supabase.from('employees').insert(map).select('id').single();
        final newId = response['id'] as int;

        print('EmployeeProvider: Funcionário criado com ID $newId (filial: ${map['branch_id']})');

        if (password != null && employee.email != null && employee.email!.isNotEmpty) {
          await registerUser(employee.email!, password, employee.role ?? 'tecnico', newId);
        }
      }
      else {
        // ==================== ATUALIZAÇÃO DE FUNCIONÁRIO EXISTENTE ====================
        // PROTEÇÃO CRÍTICA: nunca sobrescrever esses campos
        map.remove('supabase_user_id');   // NUNCA apagar o vínculo com o auth
        map.remove('id');

        // Só super_admin pode alterar a filial
        if (!isSuper) {
          map.remove('branch_id');
        }

        await supabase.from('employees').update(map).eq('id', employee.id!);
        print('EmployeeProvider: Funcionário ${employee.id} atualizado com sucesso (campos protegidos mantidos)');
      }

      notifyListeners();
    } catch (e) {
      print('EmployeeProvider: ERRO ao salvar funcionário: $e');
      rethrow;
    }
  }

  // ==================== REGISTRAR USUÁRIO NO AUTH ====================
  Future<void> registerUser(String email, String password, String role, int employeeId) async {
    try {
      final response = await supabase.auth.signUp(email: email, password: password);
      if (response.user != null) {
        await supabase.from('employees').update({
          'supabase_user_id': response.user!.id,
          'role': role,
        }).eq('id', employeeId);
        print('EmployeeProvider: Usuário registrado no Auth com sucesso');
      }
    } catch (e) {
      print('EmployeeProvider: Erro ao registrar usuário no Auth: $e');
      rethrow;
    }
  }

  // ==================== MÉTODOS DE AFASTAMENTO E DESLIGAMENTO ====================
  Future<void> setAfastamento(int employeeId, {required String motivo, DateTime? inicio, DateTime? fim, bool isDesligamento = false}) async {
    try {
      final updateMap = {
        'status_afastamento': motivo,
        'data_inicio_afastamento': inicio?.toIso8601String(),
        'data_fim_afastamento': fim?.toIso8601String(),
        if (isDesligamento) 'is_active': false,
      };
      await supabase.from('employees').update(updateMap).eq('id', employeeId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> retornarFuncionario(int employeeId) async {
    try {
      await supabase.from('employees').update({
        'status_afastamento': null,
        'data_inicio_afastamento': null,
        'data_fim_afastamento': null,
        'is_active': true,
      }).eq('id', employeeId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await supabase.from('employees').delete().eq('id', id);
      notifyListeners();
    } catch (e) {
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
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}