// lib/features/obra/providers/obra_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';

class ObraProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Obra> _obras = [];
  List<Obra> get obras => _obras;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ==================== CRUD OBRAS ====================

  Future<void> loadObras() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('obras')
          .select()
          .order('created_at', ascending: false);

      _obras = response.map<Obra>((map) => Obra.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar obras: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createObra(Obra obra) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('obras')
          .insert(obra.toMap())
          .select()
          .single();

      final novaObra = Obra.fromMap(response);
      _obras.insert(0, novaObra);
      notifyListeners();

      debugPrint('✅ Obra criada: ${novaObra.name}');
      return novaObra.id;
    } catch (e) {
      debugPrint('❌ Erro ao criar obra: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateObra(Obra obra) async {
    try {
      await _supabase
          .from('obras')
          .update(obra.toMap())
          .eq('id', obra.id);

      final index = _obras.indexWhere((o) => o.id == obra.id);
      if (index != -1) {
        _obras[index] = obra;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar obra: $e');
      return false;
    }
  }

  Future<bool> deleteObra(String id) async {
    try {
      await _supabase.from('obras').delete().eq('id', id);
      _obras.removeWhere((o) => o.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir obra: $e');
      return false;
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================

  Obra? getObraById(String id) {
    return _obras.cast<Obra?>().firstWhere((o) => o?.id == id, orElse: () => null);
  }

  void clear() {
    _obras.clear();
    notifyListeners();
  }
}