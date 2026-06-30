// lib/features/fase/providers/fase_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fase.dart';

class FaseProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Fase> _fases = [];
  List<Fase> get fases => _fases;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> carregarFases() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("🔄 [FaseProvider] Carregando fases globais...");

      final response = await _supabase
          .from('fase')
          .select()
          .eq('ativo', true)
          .order('ordem', ascending: true);

      _fases = (response as List<dynamic>)
          .map((json) => Fase.fromMap(json as Map<String, dynamic>))
          .toList();

      debugPrint("✅ ${_fases.length} fases carregadas");
    } catch (e) {
      debugPrint("❌ Erro ao carregar fases: $e");
      _fases = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => await carregarFases();

  // Salvar ordem após reordenação
  Future<bool> salvarOrdem(List<Fase> fasesOrdenadas) async {
    try {
      for (int i = 0; i < fasesOrdenadas.length; i++) {
        await _supabase
            .from('fase')
            .update({'ordem': i + 1})
            .eq('id', fasesOrdenadas[i].id);
      }
      debugPrint("✅ Ordem das fases salva com sucesso");
      await carregarFases(); // Atualiza a lista local
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar ordem: $e");
      return false;
    }
  }

  // Método útil para buscar uma fase específica
  Fase? getFaseById(String id) {
    return _fases.cast<Fase?>().firstWhere((f) => f?.id == id, orElse: () => null);
  }
}