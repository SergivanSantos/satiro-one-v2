// lib/providers/architect_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/architect.dart';

class ArchitectProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Architect> _architects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Architect> get architects => _architects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ArchitectProvider() {
    fetchArchitects();
  }

  Future<void> fetchArchitects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('architects')
          .select()
          .order('name', ascending: true);

      _architects = response.map((json) => Architect.fromJson(json)).toList();
      print('ArchitectProvider: ${_architects.length} arquitetos carregados do Supabase');
      _errorMessage = null;
    } catch (e, stack) {
      print('ArchitectProvider: Erro ao carregar arquitetos: $e');
      print('Stack: $stack');
      _errorMessage = 'Erro ao carregar arquitetos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addArchitect(Architect architect) async {
    try {
      final response = await _supabase
          .from('architects')
          .insert(architect.toJson())  // sem excludeId, pois o banco gera o ID
          .select()
          .single();

      final newArchitect = Architect.fromJson(response);
      _architects.add(newArchitect);
      print('ArchitectProvider: Novo arquiteto criado no Supabase - ID: ${newArchitect.id}');
      _errorMessage = null;
    } catch (e, stack) {
      print('ArchitectProvider: Erro ao adicionar arquiteto: $e');
      print('Stack: $stack');
      _errorMessage = 'Erro ao adicionar arquiteto: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateArchitect(Architect architect) async {
    if (architect.id == null) {
      print('ArchitectProvider: Tentativa de atualizar arquiteto sem ID');
      return;
    }

    try {
      await _supabase
          .from('architects')
          .update(architect.toJson())
          .eq('id', architect.id!);

      final index = _architects.indexWhere((a) => a.id == architect.id);
      if (index != -1) {
        _architects[index] = architect;
      }
      print('ArchitectProvider: Arquiteto atualizado no Supabase - ID: ${architect.id}');
      _errorMessage = null;
    } catch (e, stack) {
      print('ArchitectProvider: Erro ao atualizar arquiteto: $e');
      print('Stack: $stack');
      _errorMessage = 'Erro ao atualizar arquiteto: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteArchitect(int id) async {
    try {
      await _supabase.from('architects').delete().eq('id', id);
      _architects.removeWhere((a) => a.id == id);
      print('ArchitectProvider: Arquiteto excluído do Supabase - ID: $id');
      _errorMessage = null;
    } catch (e, stack) {
      print('ArchitectProvider: Erro ao excluir arquiteto: $e');
      print('Stack: $stack');
      _errorMessage = 'Erro ao excluir arquiteto: $e';
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}