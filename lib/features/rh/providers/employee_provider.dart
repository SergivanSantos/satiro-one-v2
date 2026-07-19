// lib/features/rh/providers/employee_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../servicos/screens/obra_servico_form_screen.dart';
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
    // Tenta carregar imediatamente e com retry
    Future.delayed(const Duration(milliseconds: 300), _loadCurrentEmployeeWithRetry);
  }

  List<Employee> get employees => _employees;
  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;

  bool get isAdmin => _currentEmployee?.isAdmin ?? false;
  bool get isGerente => _currentEmployee?.role?.toLowerCase().contains('gerente') ?? false;
  bool get isRh => _currentEmployee?.role?.toLowerCase().contains('rh') ?? false;
  bool get isTecnico => _currentEmployee?.role?.toLowerCase() == 'tecnico';
  bool get isSuper => _currentEmployee?.role?.toLowerCase().startsWith('super_') ?? false;

  final supabase = Supabase.instance.client;

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
      // Atualiza currentEmployee se ele estiver na lista
      if (_currentEmployee != null) {
        final updated = _employees.firstWhereOrNull((e) => e.id == _currentEmployee!.id);
        if (updated != null) {
          _currentEmployee = updated;
        }
      }
      notifyListeners();
    });
  }

  Future<void> _loadCurrentEmployeeWithRetry({int attempts = 0}) async {
    if (attempts > 5) {
      print('⚠️ Máximo de tentativas para carregar currentEmployee atingido');
      return;
    }

    await _loadCurrentEmployee();

    if (_currentEmployee == null) {
      print('⚠️ currentEmployee ainda null. Tentando novamente em ${500 + attempts * 300}ms...');
      Future.delayed(Duration(milliseconds: 500 + attempts * 300), () {
        _loadCurrentEmployeeWithRetry(attempts: attempts + 1);
      });
    } else {
      print('✅ currentEmployee carregado com sucesso: ${_currentEmployee!.name} (ID: ${_currentEmployee!.id})');
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
      print('Erro ao carregar funcionário atual: $e');
      _currentEmployee = null;
    }
    notifyListeners();
  }

  Future<void> loadCurrentEmployee() async {
    await _loadCurrentEmployeeWithRetry();
  }

  // ==================== LOGIN / LOGOUT / OUTROS MÉTODOS ====================
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadCurrentEmployeeWithRetry();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      await supabase.auth.signOut();
      _currentEmployee = null;
      notifyListeners();
    } catch (e) {
      print('Erro no logout: $e');
    } finally {
      _isLoggingOut = false;
    }
  }

  // ==================== SALVAR FUNCIONÁRIO ====================
  // ==================== SALVAR FUNCIONÁRIO ====================
  Future<bool> saveEmployee(Employee employee, {String? password}) async {
    try {
      final map = employee.toMap();

      if (employee.id == null) {
        // Novo funcionário
        print('🆕 Criando novo funcionário: ${employee.name}');

        map.remove('id'); // Garante que o banco gere o ID

        final res = await supabase.from('employees').insert(map).select('id').single();
        final newId = res['id'] as int;

        print('✅ Funcionário criado com ID: $newId');

        if (password != null && employee.email != null && employee.email!.isNotEmpty) {
          print('🔑 Criando usuário no Authentication...');
          await _registerAuthUser(employee.email!, password, employee.role, newId);
        }
      } else {
        // Atualização
        print('✏️ Atualizando funcionário ID: ${employee.id}');
        map.remove('id');
        await supabase.from('employees').update(map).eq('id', employee.id!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ ERRO ao salvar funcionário: $e');

      // Tratamento específico para CPF duplicado
      if (e.toString().contains('employees_cpf_key') || e.toString().contains('duplicate key')) {
        _errorMessage = "CPF já cadastrado. Use outro CPF.";
      } else if (e.toString().contains('employees_email_key') || e.toString().contains('duplicate key')) {
        _errorMessage = "E-mail já cadastrado. Use outro e-mail.";
      } else {
        _errorMessage = e.toString();
      }

      notifyListeners();
      return false;
    }
  }

  Future<void> _registerAuthUser(String email, String password, String role, int employeeId) async {
    try {
      print('🔑 Tentando criar usuário no Auth: $email');
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
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

  // Adicione este método no EmployeeProvider
  Future<void> loadAllEmployees() async {
    try {
      final res = await supabase
          .from('employees')
          .select()
          .order('name');

      _employees = res.map((map) => Employee.fromMap(map)).toList();
      notifyListeners();
      print('✅ ${_employees.length} funcionários carregados na lista');
    } catch (e) {
      print('❌ Erro ao carregar lista de funcionários: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}