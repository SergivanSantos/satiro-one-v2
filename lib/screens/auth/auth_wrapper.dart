// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/employee_provider.dart';
import '../../screens/tecnico/tecnico_home_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Ainda carregando a sessão do Supabase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // Sem sessão → mostra tela de login
        if (session == null) {
          print('AuthWrapper: Sem sessão → LoginScreen');
          return const LoginScreen();
        }

        // Tem sessão → verifica se o funcionário já foi carregado
        final employeeProvider = Provider.of<EmployeeProvider>(context);

        // Se ainda não carregou o funcionário, mostra loading
        if (employeeProvider.currentEmployee == null) {
          print('AuthWrapper: Sessão encontrada, mas funcionário ainda não carregado');

          // Força o carregamento apenas uma vez
          if (!employeeProvider.isLoading) {
            employeeProvider.loadCurrentEmployee();
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Funcionário carregado com sucesso
        final role = employeeProvider.currentEmployee!.role?.toLowerCase() ?? '';
        print('AuthWrapper: Usuário logado como $role');

        if (role.contains('super_admin') ||
            role.contains('admin') ||
            role.contains('rh') ||
            role.contains('super_rh')) {
          return const HomeScreen();
        } else {
          return const TecnicoHomeScreen();
        }
      },
    );
  }
}