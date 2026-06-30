// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _role;

  User? get currentUser => _currentUser;
  String get role => _role ?? 'tecnico';

  bool get isAdmin => role.toLowerCase().contains('admin');
  bool get isGerente => role.toLowerCase().contains('gerente');
  bool get isRh => role.toLowerCase().contains('rh');
  bool get isTecnico => role.toLowerCase() == 'tecnico';

  Future<void> loadUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    _currentUser = user;

    if (user != null) {
      // Busca role do perfil (ajuste conforme sua tabela)
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _role = profile['role'] ?? 'tecnico';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    _role = null;
    notifyListeners();
  }
}