// lib/features/servicos/providers/servico_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/servico.dart';

class ServicoProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Servico> _servicos = [];
  List<Servico> get servicos => _servicos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> carregarServicos() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("🔄 [ServicoProvider] Iniciando carregamento de serviços...");

      // ← SEM JOIN para evitar erro de coluna
      final response = await _supabase
          .from('servico')
          .select()
          .eq('ativo', true)
          .order('categoria', ascending: true)
          .order('nome', ascending: true);

      _servicos = (response as List)
          .map((json) => Servico.fromMap(json))
          .toList();

      debugPrint("✅ [ServicoProvider] ${_servicos.length} serviços carregados com sucesso");
    } catch (e) {
      debugPrint("❌ [ServicoProvider] ERRO ao carregar serviços: $e");
      _servicos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Servico>> buscarPorIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final response = await _supabase
          .from('servico')
          .select()
          .inFilter('id', ids)
          .eq('ativo', true);

      return (response as List)
          .map((json) => Servico.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint("❌ [ServicoProvider] Erro ao buscar serviços por IDs: $e");
      return [];
    }
  }

  Future<void> refresh() async {
    await carregarServicos();
  }
}