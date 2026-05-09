// lib/providers/category_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  CategoryProvider() {
    _loadCategoriesStream();
  }

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _loadCategoriesStream() {
    _isLoading = true;
    notifyListeners();

    supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .listen((List<Map<String, dynamic>> data) {
      _categories = data.map((map) => Category.fromMap(map)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      print('CategoryProvider: Stream atualizou - ${_categories.length} categorias');
    }, onError: (error) {
      _errorMessage = 'Erro no stream: $error';
      _isLoading = false;
      notifyListeners();
      print('CategoryProvider: Erro no stream: $error');
    });
  }

  // MÉTODO NOVO — RECARREGA MANUALMENTE DO SUPABASE
  Future<void> _reloadCategories() async {
    try {
      final response = await supabase.from('categories').select().order('name');
      _categories = response.map((map) => Category.fromMap(map as Map<String, dynamic>)).toList();
      notifyListeners();
      print('CategoryProvider: Reload manual - ${_categories.length} categorias');
    } catch (e) {
      print('CategoryProvider: Erro no reload manual: $e');
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      final map = category.toMap();
      map.remove('id');
      await supabase.from('categories').insert(map);
      await _reloadCategories(); // FORÇA RECARGA IMEDIATA
      print('CategoryProvider: Categoria adicionada com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao adicionar: $e';
      notifyListeners();
      print('CategoryProvider: Erro ao adicionar categoria: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    if (category.id == null) return;

    try {
      final map = category.toMap();
      map.remove('id'); // Remove o ID para permitir edição
      await supabase.from('categories').update(map).eq('id', category.id!);
      await _reloadCategories(); // FORÇA RECARGA IMEDIATA
      print('CategoryProvider: Categoria atualizada com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao atualizar: $e';
      notifyListeners();
      print('CategoryProvider: Erro ao atualizar categoria: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await supabase.from('categories').delete().eq('id', id);
      await _reloadCategories(); // FORÇA RECARGA IMEDIATA
      print('CategoryProvider: Categoria excluída com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao excluir: $e';
      notifyListeners();
      print('CategoryProvider: Erro ao excluir categoria: $e');
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}