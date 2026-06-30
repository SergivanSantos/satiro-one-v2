// lib/features/auth/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
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

        // Garante que o EmployeeProvider está disponível
        return Consumer<EmployeeProvider>(
          builder: (context, employeeProvider, child) {
            if (employeeProvider.currentEmployee == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                employeeProvider.loadCurrentEmployee();
              });
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}