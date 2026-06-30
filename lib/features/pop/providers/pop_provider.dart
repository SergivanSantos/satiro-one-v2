// lib/features/pop/providers/pop_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pop.dart';

class PopProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Pop> _pops = [];
  List<Pop> get pops => _pops;

  Future<void> carregarPops() async {
    try {
      final response = await _supabase
          .from('pops')
          .select()
          .order('categoria_pop')   // ← Alterado
          .order('titulo');

      _pops = (response as List).map((json) => Pop.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar POPs: $e");
    }
  }

  // ==================== UPLOAD PARA SUPABASE STORAGE ====================
  Future<bool> uploadPop(PlatformFile file, {
    required String titulo,
    required String categoriaPop,   // ← Alterado
    String? codigo,
    String? descricao,
  }) async {
    try {
      // ==================== SANITIZAÇÃO DO NOME DO ARQUIVO ====================
      String fileName = file.name;

      fileName = fileName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9._-]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = '${timestamp}_$fileName';

      debugPrint("📤 Nome sanitizado: $safeFileName");

      // Upload usando bytes
      await _supabase.storage
          .from('pops')
          .uploadBinary(
        'pops/$safeFileName',
        file.bytes!,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
        ),
      );

      final publicUrl = _supabase.storage
          .from('pops')
          .getPublicUrl('pops/$safeFileName');

      // Salvar no banco
      await _supabase.from('pops').insert({
        'titulo': titulo,
        'codigo': codigo,
        'categoria_pop': categoriaPop,   // ← Alterado
        'descricao': descricao,
        'arquivo_url': publicUrl,
        'versao': '1.0',
        'ativo': true,
      });

      await carregarPops();
      debugPrint("✅ POP salvo com sucesso: $publicUrl");
      return true;

    } catch (e) {
      debugPrint("❌ Erro ao fazer upload do POP: $e");
      return false;
    }
  }

  // Contagem de visualizações por POP
  Future<int> getVisualizacoes(String popId) async {
    try {
      final response = await _supabase
          .from('pop_views')
          .select()
          .eq('pop_id', popId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ==================== LOG DE VISUALIZAÇÕES ====================
  Future<void> registrarVisualizacao(String popId) async {
    try {
      await _supabase.from('pop_views').insert({
        'pop_id': popId,
        'viewed_at': DateTime.now().toIso8601String(),
      });
      debugPrint("👁️ Visualização registrada para POP: $popId");
    } catch (e) {
      debugPrint("⚠️ Erro ao registrar visualização: $e");
    }
  }

  // ==================== GERENCIAMENTO DE CATEGORIAS ====================
  List<String> _categorias = [
    'Administrativos',
    'Técnicos',
    'Vendas',
    'Compras',
    'Financeiro',
    'Engenharia',
    'RH',
    'Qualidade',
    'Outros'
  ];

  List<String> get categorias => _categorias;

  void adicionarCategoria(String novaCategoria) {
    final cat = novaCategoria.trim();
    if (cat.isNotEmpty && !_categorias.contains(cat)) {
      _categorias.add(cat);
      notifyListeners();
    }
  }

  void removerCategoria(String categoria) {
    if (_categorias.length > 1) {
      _categorias.remove(categoria);
      notifyListeners();
    }
  }

  Future<bool> atualizarPop(Pop pop) async {
    try {
      await _supabase.from('pops').update(pop.toJson()).eq('id', pop.id);
      await carregarPops();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar POP: $e");
      return false;
    }
  }

  Future<bool> removerPop(String id) async {
    try {
      await _supabase.from('pops').delete().eq('id', id);
      await carregarPops();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao remover POP: $e");
      return false;
    }
  }
}