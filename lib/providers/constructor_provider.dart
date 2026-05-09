// lib/providers/constructor_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/constructor.dart';

class ConstructorProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Constructor> _constructors = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Constructor> get constructors => _constructors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ConstructorProvider() {
    fetchConstructors();
  }

  Future<void> fetchConstructors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('constructors')
          .select()
          .order('name', ascending: true);

      _constructors = response.map((json) => Constructor.fromJson(json)).toList();
      print('ConstructorProvider: ${_constructors.length} construtoras carregadas do Supabase');
      _errorMessage = null;
    } catch (e) {
      print('ConstructorProvider: Erro ao carregar construtoras: $e');
      _errorMessage = 'Erro ao carregar construtoras: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addConstructor(Constructor constructor) async {
    try {
      final response = await _supabase
          .from('constructors')
          .insert(constructor.toJson())
          .select()
          .single();

      final newConstructor = Constructor.fromJson(response);
      _constructors.add(newConstructor);
      print('ConstructorProvider: Nova construtora criada no Supabase - ID: ${newConstructor.id}');
      _errorMessage = null;
    } catch (e) {
      print('ConstructorProvider: Erro ao adicionar construtora: $e');
      _errorMessage = 'Erro ao adicionar construtora: $e';
    }
    notifyListeners();
  }

  Future<void> updateConstructor(Constructor constructor) async {
    if (constructor.id == null) return;

    try {
      await _supabase
          .from('constructors')
          .update(constructor.toJson())
          .eq('id', constructor.id!);

      final index = _constructors.indexWhere((c) => c.id == constructor.id);
      if (index != -1) {
        _constructors[index] = constructor;
      }
      print('ConstructorProvider: Construtora atualizada no Supabase - ID: ${constructor.id}');
      _errorMessage = null;
    } catch (e) {
      print('ConstructorProvider: Erro ao atualizar construtora: $e');
      _errorMessage = 'Erro ao atualizar construtora: $e';
    }
    notifyListeners();
  }

  Future<void> deleteConstructor(int id) async {
    try {
      await _supabase.from('constructors').delete().eq('id', id);
      _constructors.removeWhere((c) => c.id == id);
      print('ConstructorProvider: Construtora excluída do Supabase - ID: $id');
      _errorMessage = null;
    } catch (e) {
      print('ConstructorProvider: Erro ao excluir construtora: $e');
      _errorMessage = 'Erro ao excluir construtora: $e';
    }
    notifyListeners();
  }
}