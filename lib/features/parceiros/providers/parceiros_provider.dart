import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/arquiteto.dart';
import '../models/construtora.dart';
import '../../obra/models/obra.dart';           // ← Adicionado

class ParceirosProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Arquiteto> arquitetos = [];
  List<Construtora> construtoras = [];

  // ===================== ARQUITETOS =====================
  Future<void> carregarArquitetos() async {
    try {
      final response = await _supabase
          .from('arquitetos')
          .select()
          .order('nome', ascending: true);

      arquitetos = response.map<Arquiteto>((json) => Arquiteto.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao carregar arquitetos: $e");
    }
  }

  Future<bool> adicionarArquiteto(Arquiteto arquiteto) async {
    try {
      await _supabase.from('arquitetos').insert(arquiteto.toJson());
      await carregarArquitetos();
      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar arquiteto: $e");
      return false;
    }
  }

  Future<bool> atualizarArquiteto(Arquiteto arquiteto) async {
    try {
      await _supabase.from('arquitetos').update(arquiteto.toJson()).eq('id', arquiteto.id);
      await carregarArquitetos();
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar arquiteto: $e");
      return false;
    }
  }

  Future<bool> removerArquiteto(String id) async {
    try {
      await _supabase.from('arquitetos').delete().eq('id', id);
      await carregarArquitetos();
      return true;
    } catch (e) {
      debugPrint("Erro ao remover arquiteto: $e");
      return false;
    }
  }

  // ===================== CONSTRUTORAS =====================
  Future<void> carregarConstrutoras() async {
    try {
      final response = await _supabase
          .from('construtoras')
          .select()
          .order('nome', ascending: true);

      construtoras = response.map<Construtora>((json) => Construtora.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao carregar construtoras: $e");
    }
  }

  Future<bool> adicionarConstrutora(Construtora construtora) async {
    try {
      await _supabase.from('construtoras').insert(construtora.toJson());
      await carregarConstrutoras();
      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar construtora: $e");
      return false;
    }
  }

  Future<bool> atualizarConstrutora(Construtora construtora) async {
    try {
      await _supabase.from('construtoras').update(construtora.toJson()).eq('id', construtora.id);
      await carregarConstrutoras();
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar construtora: $e");
      return false;
    }
  }

  Future<bool> removerConstrutora(String id) async {
    try {
      await _supabase.from('construtoras').delete().eq('id', id);
      await carregarConstrutoras();
      return true;
    } catch (e) {
      debugPrint("Erro ao remover construtora: $e");
      return false;
    }
  }

  // ===================== CONTADORES DE OBRAS =====================

  // ------------------- ARQUITETOS -------------------
  int getTotalObrasArquiteto(String arquitetoId, List<Obra> todasObras) {
    return todasObras.where((obra) => obra.arquitetoId == arquitetoId).length;
  }

  int getObrasEmAndamentoArquiteto(String arquitetoId, List<Obra> todasObras) {
    return todasObras.where((obra) =>
    obra.arquitetoId == arquitetoId &&
        obra.status.toUpperCase().contains('ANDAMENTO')).length;
  }

  int getObrasConcluidasArquiteto(String arquitetoId, List<Obra> todasObras) {
    return todasObras.where((obra) =>
    obra.arquitetoId == arquitetoId &&
        (obra.status.toUpperCase().contains('CONCLU') ||
            obra.status.toUpperCase().contains('FINALIZ'))).length;
  }

  // ------------------- CONSTRUTORAS -------------------
  int getTotalObrasConstrutora(String construtoraId, List<Obra> todasObras) {
    return todasObras.where((obra) => obra.construtoraId == construtoraId).length;
  }

  int getObrasEmAndamentoConstrutora(String construtoraId, List<Obra> todasObras) {
    return todasObras.where((obra) =>
    obra.construtoraId == construtoraId &&
        obra.status.toUpperCase().contains('ANDAMENTO')).length;
  }

  int getObrasConcluidasConstrutora(String construtoraId, List<Obra> todasObras) {
    return todasObras.where((obra) =>
    obra.construtoraId == construtoraId &&
        (obra.status.toUpperCase().contains('CONCLU') ||
            obra.status.toUpperCase().contains('FINALIZ'))).length;
  }
}