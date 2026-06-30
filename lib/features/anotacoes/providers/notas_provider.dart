// lib/features/anotacoes/providers/notas_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nota.dart';

class NotasProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Nota> _notas = [];
  List<Nota> get notas => _notas;

  Future<void> carregarNotas() async {
    try {
      final response = await _supabase
          .from('notas')
          .select()
          .order('updated_at', ascending: false);

      _notas = (response as List).map((json) => Nota.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao carregar notas: $e");
    }
  }

  Future<bool> salvarNota(Nota nota) async {
    try {
      if (nota.id.isEmpty) {
        await _supabase.from('notas').insert(nota.toJson());
      } else {
        await _supabase.from('notas').update(nota.toJson()).eq('id', nota.id);
      }
      await carregarNotas();
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar nota: $e");
      return false;
    }
  }

  Future<bool> excluirNota(String id) async {
    try {
      await _supabase.from('notas').delete().eq('id', id);
      await carregarNotas();
      return true;
    } catch (e) {
      return false;
    }
  }
}
