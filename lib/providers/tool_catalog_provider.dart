// lib/providers/tool_catalog_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tool_catalog.dart';

class ToolCatalogProvider with ChangeNotifier {
  List<ToolCatalog> _catalog = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  ToolCatalogProvider() {
    _loadCatalogStream();
  }

  List<ToolCatalog> get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _loadCatalogStream() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = supabase
        .from('tool_catalog')
        .stream(primaryKey: ['id'])
        .order('nome')
        .listen(
          (List<Map<String, dynamic>> data) {
        _catalog = data.map((map) => ToolCatalog.fromMap(map)).toList();
        _isLoading = false; // Sempre força false quando chega qualquer resposta
        _errorMessage = null;
        notifyListeners();
        print('ToolCatalogProvider: Catálogo atualizado via stream: ${_catalog.length} itens, isLoading: $_isLoading');
      },
      onError: (error) {
        _errorMessage = 'Erro no stream: $error';
        _isLoading = false;
        notifyListeners();
        print('ToolCatalogProvider: Erro no stream: $error');
      },
    );

    // Fallback de segurança: se não receber nada em 8 segundos, força reload e isLoading false
    Future.delayed(const Duration(seconds: 8), () {
      if (_isLoading) {
        print('ToolCatalogProvider: Timeout - forçando reload manual');
        refreshCatalog();
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> refreshCatalog() async {
    // Força reload manual (útil para pull-to-refresh ou erro)
    try {
      final response = await supabase.from('tool_catalog').select().order('nome');
      _catalog = response.map((map) => ToolCatalog.fromMap(map as Map<String, dynamic>)).toList();
      _errorMessage = null;
      notifyListeners();
      print('ToolCatalogProvider: Reload manual - ${_catalog.length} itens');
    } catch (e) {
      _errorMessage = 'Erro ao recarregar catálogo: $e';
      notifyListeners();
      print('ToolCatalogProvider: Erro no reload manual: $e');
    }
  }

  Future<void> addToolCatalog(ToolCatalog tool) async {
    try {
      print('ToolCatalogProvider: Adicionando ao catálogo: ${tool.nome}');
      final map = tool.toMap();
      map.remove('id'); // Remove ID para insert
      await supabase.from('tool_catalog').insert(map);
      // Não precisa reload manual: o stream vai atualizar sozinho
      print('ToolCatalogProvider: Item adicionado ao catálogo');
    } catch (e) {
      _errorMessage = 'Erro ao adicionar: $e';
      notifyListeners();
      print('ToolCatalogProvider: Erro ao adicionar item: $e');
      rethrow;
    }
  }

  Future<void> updateToolCatalog(ToolCatalog tool) async {
    if (tool.id == null) return;

    try {
      print('ToolCatalogProvider: Atualizando catálogo ID ${tool.id}');
      final map = tool.toMap();
      map.remove('id'); // Remove ID do update
      await supabase.from('tool_catalog').update(map).eq('id', tool.id!);
      // Stream atualiza sozinho
      print('ToolCatalogProvider: Item atualizado no catálogo');
    } catch (e) {
      _errorMessage = 'Erro ao atualizar: $e';
      notifyListeners();
      print('ToolCatalogProvider: Erro ao atualizar item: $e');
      rethrow;
    }
  }

  Future<void> deleteToolCatalog(int id) async {
    try {
      print('ToolCatalogProvider: Excluindo catálogo ID $id');
      await supabase.from('tool_catalog').delete().eq('id', id);
      // Stream atualiza sozinho
      print('ToolCatalogProvider: Item excluído do catálogo');
    } catch (e) {
      _errorMessage = 'Erro ao excluir: $e';
      notifyListeners();
      print('ToolCatalogProvider: Erro ao excluir item: $e');
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}