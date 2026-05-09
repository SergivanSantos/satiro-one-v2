// lib/screens/auth/login_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Novo: para testar rede
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/employee_provider.dart';
import '../tecnico/tecnico_home_screen.dart';

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
      // 1. Verifica se há conexão com internet
      final hasInternet = await _hasInternet();
      if (!hasInternet) {
        setState(() {
          _error =
          'Sem conexão com a internet.\nVerifique Wi-Fi ou dados móveis e tente novamente.';
        });
        return;
      }

      // 2. Tenta o login – CORREÇÃO: passando context como 3º parâmetro
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        context, // ← Adicionado aqui! Obrigatório pelo método atualizado
      );

      // Após await provider.login(...) e setar _currentEmployee

      // Dentro do _login(), após o provider.login() e verificar session != null
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final storage = const FlutterSecureStorage();

        // Salva o JSON completo da sessão (recomendado)
        await storage.write(key: 'supabase_session_json', value: jsonEncode(session.toJson()));

        // (opcional - você já salva tokens separados, pode manter)
        await storage.write(key: 'access_token', value: session.accessToken);
        await storage.write(key: 'refresh_token', value: session.refreshToken);
        await storage.write(key: 'user_role', value: provider.isAdmin ? 'admin' : 'tecnico');
        await storage.write(key: 'user_id', value: session.user.id);

        print('Sessão completa salva como JSON');
      }

      // Redirecionamento imediato após salvar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('LoginScreen: Redirecionando para ${provider.isAdmin ? '/' : '/tecnico_home'}');
          if (provider.isAdmin) {
            Navigator.pushReplacementNamed(context, '/');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TecnicoHomeScreen()),
            );
          }
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          // Mensagem amigável para erros comuns
          if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
            _error = 'Não foi possível conectar ao servidor.\nVerifique sua internet ou tente novamente mais tarde.';
          } else if (e.toString().contains('Invalid login credentials')) {
            _error = 'E-mail ou senha incorretos';
          } else {
            _error = 'Erro ao fazer login. Tente novamente.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    // Título "Satiro One"
                    Text(
                      'Satiro One',
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Campo E-mail
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 24),

                    // Campo Senha com toggle
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 16),

                    // Link "Esqueci minha senha"
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Recuperação de senha em breve'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        child: Text(
                          'Esqueci minha senha',
                          style: GoogleFonts.poppins(
                            color: Colors.teal.shade300,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botão de login
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : Text(
                          'Entrar',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Erro destacado
                    if (_error != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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