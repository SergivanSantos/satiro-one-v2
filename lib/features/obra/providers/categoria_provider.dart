import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria.dart';

class CategoriaProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Categoria> _categorias = [];
  List<Categoria> get categorias => _categorias;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadCategorias() async {
    debugPrint("🔄 [CategoriaProvider] Carregando categorias...");
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('categoria')           // Vamos criar essa tabela depois
          .select()
          .eq('ativo', true)
          .order('nome');

      _categorias = res.map<Categoria>((json) => Categoria.fromMap(json)).toList();
      debugPrint("✅ [CategoriaProvider] ${_categorias.length} categorias carregadas");
    } catch (e) {
      debugPrint("❌ [CategoriaProvider] Erro: $e");
      _categorias = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCategoria(Categoria categoria) async {
    try {
      await _supabase.from('categoria').insert(categoria.toMap());
      await loadCategorias();
      return true;
    } catch (e) {
      debugPrint("Erro ao criar categoria: $e");
      return false;
    }
  }

  Future<bool> updateCategoria(Categoria categoria) async {
    try {
      await _supabase.from('categoria').update(categoria.toMap()).eq('id', categoria.id);
      await loadCategorias();
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar categoria: $e");
      return false;
    }
  }

  Future<bool> deleteCategoria(String id) async {
    try {
      await _supabase.from('categoria').delete().eq('id', id);
      await loadCategorias();
      return true;
    } catch (e) {
      debugPrint("Erro ao excluir categoria: $e");
      return false;
    }
  }
}