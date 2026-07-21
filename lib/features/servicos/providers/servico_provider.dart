// lib/features/servicos/providers/servico_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/servico.dart';

class ServicoProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // ==================== SERVIÇOS GLOBAIS ====================
  List<Servico> _servicos = [];
  List<Servico> get servicos => _servicos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> carregarServicos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('servico')
          .select('*, categoria(nome), pops(arquivo_url, titulo)')
          .eq('ativo', true)
          .order('categoria_id', ascending: true)
          .order('nome', ascending: true);

      _servicos = (response as List)
          .map((json) => Servico.fromMap(json))
          .toList();

      debugPrint("✅ ${_servicos.length} serviços globais carregados");
    } catch (e) {
      debugPrint("❌ ERRO ao carregar serviços globais: $e");
      _servicos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SERVIÇOS POR OBRA (CACHE) ====================
  final Map<String, List<Map<String, dynamic>>> _servicosPorObra = {};

  List<Map<String, dynamic>> getServicosDaObra(String obraId) {
    return _servicosPorObra[obraId] ?? [];
  }

  Future<void> carregarServicosDaObra(String obraId, String? faseId) async {
    try {
      debugPrint("🔄 Carregando serviços da obra $obraId | fase: ${faseId ?? 'todas'}");

      var query = _supabase
          .from('obra_servico')
          .select('*, servico(*, categoria(nome), pops(arquivo_url, titulo))')
          .eq('obra_id', obraId);

      // Filtro de fase (se informado)
      if (faseId != null && faseId.isNotEmpty) {
        query = query.eq('fase_id', faseId);
      }

      final res = await query.order('created_at');

      _servicosPorObra[obraId] = List.from(res);

      debugPrint("✅ ${_servicosPorObra[obraId]!.length} serviços cacheados para obra $obraId");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços da obra $obraId: $e");
      _servicosPorObra[obraId] = [];
    }
  }

  // ==================== SERVIÇOS POR FASE ====================
  List<Map<String, dynamic>> _servicosDaFase = [];
  List<Map<String, dynamic>> get servicosDaFase => _servicosDaFase;

  Future<void> carregarServicosDaFase(String obraId, String faseId) async {
    try {
      final res = await _supabase
          .from('obra_servico')
          .select('*, servico(*, categoria(nome), pops(arquivo_url, titulo))')
          .eq('obra_id', obraId)
          .eq('fase_id', faseId)
          .order('created_at');

      _servicosDaFase = List.from(res);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços da fase: $e");
      _servicosDaFase = [];
    }
  }

  // ==================== OUTROS MÉTODOS ====================
  Future<List<Servico>> buscarPorIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final response = await _supabase
          .from('servico')
          .select('*, categoria(nome), pops(arquivo_url, titulo)')
          .inFilter('id', ids)
          .eq('ativo', true);

      return (response as List)
          .map((json) => Servico.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint("❌ Erro ao buscar por IDs: $e");
      return [];
    }
  }

  Future<void> refresh() async {
    await carregarServicos();
  }

  void limparCacheObra(String obraId) {
    _servicosPorObra.remove(obraId);
    notifyListeners();
  }

  void limparTodoCache() {
    _servicosPorObra.clear();
    notifyListeners();
  }

  // Atualiza status de um serviço específico (chamado da tela de execução)
  Future<bool> atualizarStatusServico(String obraServicoId, String novoStatus) async {
    try {
      await _supabase
          .from('obra_servico')
          .update({'status': novoStatus})
          .eq('id', obraServicoId);

      debugPrint("✅ Status do serviço atualizado para: $novoStatus");

      // Recarrega o cache da obra para refletir a mudança
      // (você pode passar o obraId se tiver)
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status do serviço: $e");
      return false;
    }
  }

}