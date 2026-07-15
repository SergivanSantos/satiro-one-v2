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

  // ==================== SERVIÇOS GLOBAIS ====================
  Future<void> carregarServicos() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("🔄 [ServicoProvider] Iniciando carregamento de serviços...");

      final response = await _supabase
          .from('servico')
          .select('*, categoria(nome)')
          .eq('ativo', true)
          .order('categoria_id', ascending: true)
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

  // ==================== SERVIÇOS POR OBRA ====================
  List<Map<String, dynamic>> _servicosDaObra = [];
  List<Map<String, dynamic>> get servicosDaObra => _servicosDaObra;

  Future<void> carregarServicosDaObra(String obraId) async {
    try {
      debugPrint("🔄 Carregando serviços da obra $obraId (com POP)");

      final res = await _supabase
          .from('obra_servico')
          .select('''
          *,
          servico!inner (
            *,
            pop:pop_id (*)
          )
        ''')
          .eq('obra_id', obraId)
          .order('created_at');

      _servicosDaObra = List.from(res);
      debugPrint("✅ ${_servicosDaObra.length} serviços da obra carregados com POP");

      // Debug detalhado
      for (var item in _servicosDaObra) {
        final servicoMap = item['servico'] as Map? ?? {};
        final pop = servicoMap['pop'] as Map? ?? {};
        debugPrint("   → Serviço: ${servicoMap['nome']} | popUrl: ${pop['arquivo_url']}");
      }
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços da obra: $e");
      _servicosDaObra = [];
    }
  }

  // ==================== SERVIÇOS POR FASE ====================
  List<Map<String, dynamic>> _servicosDaFase = [];
  List<Map<String, dynamic>> get servicosDaFase => _servicosDaFase;

  Future<void> carregarServicosDaFase(String obraId, String faseId) async {
    try {
      debugPrint("🔄 Carregando serviços da obra $obraId | fase $faseId");

      final res = await _supabase
          .from('obra_servico')
          .select('*, servico(*, categoria(nome))')
          .eq('obra_id', obraId)
          .eq('fase_id', faseId)
          .order('created_at');

      _servicosDaFase = List.from(res);
      debugPrint("✅ ${_servicosDaFase.length} serviços carregados para esta fase");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços da fase: $e");
      _servicosDaFase = [];
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