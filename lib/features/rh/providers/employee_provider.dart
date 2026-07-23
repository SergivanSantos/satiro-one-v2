// lib/features/rh/providers/employee_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  Employee? _currentEmployee;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggingOut = false;

  StreamSubscription? _subscription;
  StreamSubscription? _authSubscription;

  EmployeeProvider() {
    print('EmployeeProvider: Instância criada');
    _setupAuthListener();
    _setupRealtimeStream();
    Future.delayed(const Duration(milliseconds: 300), _loadCurrentEmployeeWithRetry);
  }

  List<Employee> get employees => _employees;
  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _currentEmployee?.isAdmin ?? false;
  bool get isGerente => _currentEmployee?.role?.toLowerCase().contains('gerente') ?? false;
  bool get isRh => _currentEmployee?.role?.toLowerCase().contains('rh') ?? false;
  bool get isTecnico => _currentEmployee?.role?.toLowerCase() == 'tecnico';
  bool get isSuper => _currentEmployee?.role?.toLowerCase().startsWith('super_') ?? false;

  final supabase = Supabase.instance.client;

  // ==================== LISTENERS ====================
  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      print('🔄 Auth state changed: ${data.event}');
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.tokenRefreshed) {
        _loadCurrentEmployeeWithRetry();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentEmployee = null;
        notifyListeners();
      }
    });
  }

  void _setupRealtimeStream() {
    _subscription?.cancel();
    _subscription = supabase
        .from('employees')
        .stream(primaryKey: ['id'])
        .order('name')
        .listen((data) {
      _employees = data.map((map) => Employee.fromMap(map)).toList();
      if (_currentEmployee != null) {
        final updated = _employees.cast<Employee?>().firstWhere(
              (e) => e?.id == _currentEmployee!.id,
          orElse: () => null,
        );
        if (updated != null) _currentEmployee = updated;
      }
      notifyListeners();
    });
  }

  // ==================== LOAD CURRENT EMPLOYEE ====================
  Future<void> _loadCurrentEmployeeWithRetry({int attempts = 0}) async {
    if (attempts > 5) return;
    await _loadCurrentEmployee();

    if (_currentEmployee == null) {
      Future.delayed(Duration(milliseconds: 500 + attempts * 300), () {
        _loadCurrentEmployeeWithRetry(attempts: attempts + 1);
      });
    } else {
      print('✅ currentEmployee carregado: ${_currentEmployee!.name} (ID: ${_currentEmployee!.id})');
      notifyListeners();
    }
  }

  Future<void> _loadCurrentEmployee() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _currentEmployee = null;
      notifyListeners();
      return;
    }

    try {
      final response = await supabase
          .from('employees')
          .select()
          .eq('supabase_user_id', user.id)
          .maybeSingle();

      _currentEmployee = response != null ? Employee.fromMap(response) : null;
    } catch (e) {
      print('Erro ao carregar currentEmployee: $e');
      _currentEmployee = null;
    }
    notifyListeners();
  }

  Future<void> loadAllEmployees() async {
    try {
      final res = await supabase.from('employees').select().order('name');
      _employees = res.map((map) => Employee.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar lista de funcionários: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== SALVAR FUNCIONÁRIO ====================
  Future<String?> saveEmployee(Employee employee, {String? password}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final map = employee.toMap();

      if (employee.id == null) {
        // === CADASTRO NOVO ===
        print('🆕 Criando novo funcionário: ${employee.name}');

        // Verifica CPF duplicado
        final existingCpf = await supabase
            .from('employees')
            .select('id')
            .eq('cpf', employee.cpf ?? '')
            .maybeSingle();

        if (existingCpf != null) return "CPF já cadastrado no sistema.";

        // Verifica E-mail duplicado
        final existingEmail = await supabase
            .from('employees')
            .select('id')
            .eq('email', employee.email ?? '')
            .maybeSingle();

        if (existingEmail != null) return "E-mail já cadastrado no sistema.";

        map.remove('id');
        final res = await supabase.from('employees').insert(map).select('id').single();
        final newId = res['id'] as int;

        print('✅ Funcionário criado com ID: $newId');

        if (password != null && employee.email != null && employee.email!.isNotEmpty) {
          await _registerAuthUser(employee.email!, password, employee.role ?? 'tecnico', newId);
        }
      } else {
        // === ATUALIZAÇÃO ===
        print('✏️ Atualizando funcionário ID: ${employee.id}');
        map.remove('id');
        await supabase.from('employees').update(map).eq('id', employee.id!);
      }

      notifyListeners();
      return null; // Sucesso

    } catch (e) {
      print('❌ Erro ao salvar funcionário: $e');

      String errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('cpf') && errorMsg.contains('duplicate')) {
        _errorMessage = "CPF já cadastrado no sistema.";
      } else if (errorMsg.contains('email') && errorMsg.contains('duplicate')) {
        _errorMessage = "E-mail já cadastrado no sistema.";
      } else if (errorMsg.contains('invalid email')) {
        _errorMessage = "E-mail inválido.";
      } else {
        _errorMessage = "Erro inesperado: ${e.toString().length > 120 ? e.toString().substring(0, 120) + '...' : e}";
      }

      notifyListeners();
      return _errorMessage;
    }
  }

  Future<void> _registerAuthUser(String email, String password, String role, int employeeId) async {
    try {
      print('🔑 Criando usuário no Auth (Admin): $email');

      final response = await supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,        // Confirma automaticamente
        ),
      );

      if (response.user != null) {
        print('✅ Usuário criado no Auth com ID: ${response.user!.id}');

        await supabase.from('employees').update({
          'supabase_user_id': response.user!.id,
          'role': role,
        }).eq('id', employeeId);
      }
    } catch (e) {
      print('❌ Erro ao registrar usuário no Auth: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // ==================== MÉTODOS PÚBLICOS ====================

  Future<void> loadCurrentEmployee() async {
    await _loadCurrentEmployeeWithRetry();
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    notifyListeners();

    try {
      await supabase.auth.signOut();
      _currentEmployee = null;
      _employees.clear();
      notifyListeners();
    } catch (e) {
      print('Erro no logout: $e');
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  // ==================== LOGIN ====================
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🔑 Tentando login com: $email');

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Login realizado com sucesso');
        await _loadCurrentEmployeeWithRetry();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erro no login: $e');
      _errorMessage = "E-mail ou senha inválidos. Verifique os dados.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}