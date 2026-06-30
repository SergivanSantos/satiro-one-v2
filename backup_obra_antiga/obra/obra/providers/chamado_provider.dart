// lib/features/obra/providers/chamado_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChamadoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _chamados = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get chamados => _chamados;
  bool get isLoading => _isLoading;

  // Carregar chamados (com filtro opcional por obra)
  Future<void> loadChamados({String? obraId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = Supabase.instance.client
          .from('chamados')
          .select('*, obra:obras(name), tecnico:employees(nome)');

      if (obraId != null) {
        query = query.eq('obra_id', obraId);
      }

      final response = await query.order('data_criacao', ascending: false);

      _chamados = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erro ao carregar chamados: $e');
      _chamados = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Criar novo chamado
  Future<bool> createChamado({
    required String obraId,
    required String titulo,
    required String descricao,
    String? observacoes,
    DateTime? dataAgendada,
    List<String>? servicosIds, // IDs dos serviços selecionados
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Cria o chamado
      final chamadoData = {
        'obra_id': obraId,
        'tecnico_id': supabase.auth.currentUser?.id ?? '',
        'titulo': titulo,
        'descricao': descricao,
        'data_agendada': dataAgendada?.toIso8601String(),
        'status': 'pendente',
      };

      final response = await supabase
          .from('chamados')
          .insert(chamadoData)
          .select()
          .single();

      final chamadoId = response['id'];

      // Insere os itens (serviços)
      if (servicosIds != null && servicosIds.isNotEmpty) {
        final itens = servicosIds.map((id) => {
          'chamado_id': chamadoId,
          'ambiente_servico_id': id,
        }).toList();

        await supabase.from('chamado_itens').insert(itens);
      }

      // Recarrega a lista
      await loadChamados(obraId: obraId);
      return true;
    } catch (e) {
      debugPrint('Erro ao criar chamado: $e');
      return false;
    }
  }

  // Atualizar status do chamado
  Future<void> updateStatus(String chamadoId, String novoStatus) async {
    try {
      await Supabase.instance.client
          .from('chamados')
          .update({'status': novoStatus})
          .eq('id', chamadoId);

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar status: $e');
    }
  }
}