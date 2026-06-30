// lib/features/ambiente/providers/ambiente_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ambiente.dart';

class AmbienteProvider extends ChangeNotifier {
  List<Ambiente> _ambientes = [];
  List<Ambiente> get ambientes => _ambientes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadAmbientes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('ambiente')
          .select()
          .eq('ativo', true)
          .order('ordem', ascending: true);

      _ambientes = res.map<Ambiente>((map) => Ambiente.fromMap(map)).toList();
    } catch (e) {
      debugPrint("❌ Erro ao carregar ambientes globais: $e");
      _ambientes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> adicionarAmbiente(String nome) async {
    try {
      await Supabase.instance.client.from('ambiente').insert({
        'nome': nome.trim(),
        'ordem': _ambientes.length + 1,
      });
      await loadAmbientes();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao adicionar ambiente: $e");
      return false;
    }
  }

  Future<bool> atualizarAmbiente(String id, String novoNome) async {
    try {
      await Supabase.instance.client
          .from('ambiente')
          .update({'nome': novoNome.trim()})
          .eq('id', id);
      await loadAmbientes();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar ambiente: $e");
      return false;
    }
  }

  Future<bool> excluirAmbiente(String id) async {
    try {
      await Supabase.instance.client.from('ambiente').delete().eq('id', id);
      await loadAmbientes();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao excluir ambiente: $e");
      return false;
    }
  }

  Future<void> atualizarOrdem(List<Ambiente> novaOrdem) async {
    try {
      for (int i = 0; i < novaOrdem.length; i++) {
        await Supabase.instance.client
            .from('ambiente')
            .update({'ordem': i + 1})
            .eq('id', novaOrdem[i].id);
      }
      _ambientes = novaOrdem;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao atualizar ordem: $e");
    }
  }
}