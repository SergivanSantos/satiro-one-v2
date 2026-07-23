// lib/features/obra/providers/obra_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';

class ObraProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Obra> _obras = [];
  List<Obra> get obras => _obras;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Cache de nomes
  final Map<String, String> _clienteNomes = {};
  final Map<String, String> _arquitetoNomes = {};
  final Map<String, String> _construtoraNomes = {};
  final Map<String, String> _filialNomes = {};


  String getClienteNome(String? id) => _clienteNomes[id] ?? id ?? 'Não informado';
  String getArquitetoNome(String? id) => _arquitetoNomes[id] ?? id ?? 'Não informado';
  String getConstrutoraNome(String? id) => _construtoraNomes[id] ?? id ?? 'Não informado';
  String getFilialNome(String? id) => _filialNomes[id] ?? id ?? 'Não informado';

  Future<void> loadObras() async {
    debugPrint("🔄 [ObraProvider] Carregando obras com cronograma da fase atual...");
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('obra')
          .select('''
            *,
            fase_atual:fase_atual_id (nome),
            obra_fase!left (
              fase_id,
              data_inicio_prevista,
              data_fim_prevista,
              data_inicio_real,
              data_fim_real,
              status
            )
          ''')
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      _obras = res.map<Obra>((json) => Obra.fromMap(json)).toList();

      await _carregarNomesClientesEParceiros();

      debugPrint("✅ ${_obras.length} obras carregadas com dados de fase");
    } catch (e) {
      debugPrint("❌ [ObraProvider] Erro ao carregar obras: $e");
      _obras = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _carregarNomesClientesEParceiros() async {
    try {
      // Clientes
      final clientes = await _supabase.from('clientes').select('id, nome');
      _clienteNomes.clear();
      for (var c in clientes) {
        _clienteNomes[c['id']] = c['nome'] ?? 'Sem nome';
      }

      // Arquitetos com telefone
      final arquitetos = await _supabase.from('arquitetos').select('id, nome, telefone');
      _arquitetoNomes.clear();
      _arquitetoTelefones.clear();
      for (var a in arquitetos) {
        _arquitetoNomes[a['id']] = a['nome'] ?? 'Sem nome';
        _arquitetoTelefones[a['id']] = a['telefone'] ?? '';
      }

      // Construtoras com telefone
      final construtoras = await _supabase.from('construtoras').select('id, nome, telefone');
      _construtoraNomes.clear();
      _construtoraTelefones.clear();
      for (var c in construtoras) {
        _construtoraNomes[c['id']] = c['nome'] ?? 'Sem nome';
        _construtoraTelefones[c['id']] = c['telefone'] ?? '';
      }

      // Filiais (importante!)
      final filiais = await _supabase.from('filiais').select('id, nome');
      _filialNomes.clear();
      for (var f in filiais) {
        _filialNomes[f['id']] = f['nome'] ?? 'Sem nome';
      }

      debugPrint("✅ Parceiros carregados: ${_arquitetoNomes.length} arquitetos, "
          "${_construtoraNomes.length} construtoras, ${_filialNomes.length} filiais");

      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ Erro ao carregar nomes e telefones: $e");
    }
  }

  Future<bool> excluirObra(String obraId) async {
    try {
      await _supabase
          .from('obra')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', obraId);

      await loadObras();
      debugPrint("🗑️ Obra movida para lixeira: $obraId");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao excluir obra: $e");
      return false;
    }
  }

  // ==================== GETTERS PARA FILTROS ====================
  List<Map<String, dynamic>> get clientesUnicos {
    final Set<String> ids = {};
    return _obras
        .map((obra) => {
      'id': obra.clienteId,
      'nome': getClienteNome(obra.clienteId),
    })
        .where((c) => c['id'] != null && ids.add(c['id']!))
        .toList();
  }

  List<Map<String, dynamic>> get filiaisUnicas {
    final Set<String> ids = {};
    final list = _filialNomes.entries
        .map((entry) => {
      'id': entry.key,
      'nome': entry.value,
    })
        .where((f) => ids.add(f['id']!))
        .toList();

    debugPrint("📊 filiaisUnicas geradas: ${list.length} filiais");
    return list;
  }

  List<Map<String, dynamic>> get arquitetosUnicos {
    final Set<String> ids = {};
    return _obras
        .map((obra) => {
      'id': obra.arquitetoId,
      'nome': getArquitetoNome(obra.arquitetoId),
    })
        .where((a) => a['id'] != null && ids.add(a['id']!))
        .toList();
  }

  List<Map<String, dynamic>> get construtorasUnicas {
    final Set<String> ids = {};
    return _obras
        .map((obra) => {
      'id': obra.construtoraId,
      'nome': getConstrutoraNome(obra.construtoraId),
    })
        .where((c) => c['id'] != null && ids.add(c['id']!))
        .toList();
  }

  // Cache de telefones
  final Map<String, String> _arquitetoTelefones = {};
  final Map<String, String> _construtoraTelefones = {};

  String getArquitetoTelefone(String? id) {
    if (id == null || id.isEmpty) return 'Não informado';
    return _arquitetoTelefones[id] ?? 'Não informado';
  }

  String getConstrutoraTelefone(String? id) {
    if (id == null || id.isEmpty) return 'Não informado';
    return _construtoraTelefones[id] ?? 'Não informado';
  }

}