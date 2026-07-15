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
      debugPrint("🔄 [ServicoProvider] Iniciando carregamento de serviços globais...");

      final response = await _supabase
          .from('servico')
          .select('*, categoria(nome)')
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

  // ==================== SERVIÇOS POR OBRA (MAPA - EVITA SOBRESCREVER) ====================
  final Map<String, List<Map<String, dynamic>>> _servicosPorObra = {};

  List<Map<String, dynamic>> getServicosDaObra(String obraId) {
    return _servicosPorObra[obraId] ?? [];
  }

  Future<void> carregarServicosDaObra(String obraId, {String? faseId}) async {
    try {
      debugPrint("🔄 Carregando serviços da obra $obraId | fase: ${faseId ?? 'todas'}");

      var query = _supabase
          .from('obra_servico')
          .select('*, servico(*, categoria(nome))')
          .eq('obra_id', obraId);

      if (faseId != null && faseId.isNotEmpty) {
        query = query.eq('fase_id', faseId);
      }

      final res = await query.order('created_at');

      _servicosPorObra[obraId] = List.from(res);
      debugPrint("✅ ${_servicosPorObra[obraId]!.length} serviços carregados para obra $obraId");
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços da obra $obraId: $e");
      _servicosPorObra[obraId] = [];
    }
    notifyListeners();
  }

  // ==================== SERVIÇOS POR FASE (mantido para compatibilidade) ====================
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

  // ==================== OUTROS MÉTODOS (mantidos) ====================
  Future<List<Servico>> buscarPorIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final response = await _supabase
          .from('servico')
          .select('*, categoria(nome)')
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
}