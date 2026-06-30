// lib/features/auth/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';                    // Novo
import '../../rh/providers/employee_provider.dart';
import '../../obra/screens/tecnico_home_screen.dart';
import '../../home/home_screen.dart';                       // Nova Home

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _login() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hasInternet = await _hasInternet();
      if (!hasInternet) {
        setState(() => _error = 'Sem conexão com a internet.');
        return;
      }

      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final success = await employeeProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!success) {
        setState(() => _error = 'E-mail ou senha incorretos');
        return;
      }

      // Salvar sessão
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final storage = const FlutterSecureStorage();
        await storage.write(key: 'supabase_session_json', value: jsonEncode(session.toJson()));
      }

      // Redirecionamento
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final isAdminOrManager = employeeProvider.isAdmin || employeeProvider.isGerente || employeeProvider.isRh;

          if (isAdminOrManager) {
            Navigator.pushReplacementNamed(context, '/');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TecnicoHomeScreen()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erro ao fazer login. Verifique suas credenciais.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade900, Colors.teal.shade600],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Satiro One',
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 48),

                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}