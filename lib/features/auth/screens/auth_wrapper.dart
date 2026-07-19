// lib/features/auth/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../obra/screens/tecnico_home_screen.dart';
import '../screens/login_screen.dart';
import '../../home/home_screen.dart';
import '../../rh/providers/employee_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.data?.session == null) {
          return const LoginScreen();
        }

        return Consumer<EmployeeProvider>(
          builder: (context, employeeProvider, child) {
            // Se ainda não carregou o funcionário, mostra loading
            if (employeeProvider.currentEmployee == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                employeeProvider.loadCurrentEmployee();
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final employee = employeeProvider.currentEmployee!;

            // Redireciona conforme o role
            if (employee.isTecnico) {
              return const TecnicoHomeScreen();   // ← Sua tela principal
            } else if (employee.isAdmin) {
              return const HomeScreen();     // Crie ou ajuste
            //} else if (employee.isGerente) {
              //return const GerenteHomeScreen();   // Crie ou ajuste
            } else {
              return const HomeScreen();          // Fallback
            }
          },
        );
      },
    );
  }
}