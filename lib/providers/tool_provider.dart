// lib/providers/tool_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tool.dart';

class ToolProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = true;

  ToolProvider() {
    _loadToolsStream();
  }

  List<Tool> get tools => _tools;
  bool get isLoading => _isLoading;

  final supabase = Supabase.instance.client;

  void _loadToolsStream() {
    _isLoading = true;
    notifyListeners();

    supabase
        .from('personal_tools')
        .stream(primaryKey: ['id'])
        .listen((data) {
      _tools = data.map((map) => Tool.fromMap(map)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _reloadTools() async {
    final response = await supabase.from('personal_tools').select();
    _tools = response.map((map) => Tool.fromMap(map as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> addTool(Tool tool) async {
    try {
      final map = tool.toMap();
      map.remove('id');
      await supabase.from('personal_tools').insert(map);
      await _reloadTools();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTool(Tool tool) async {
    if (tool.id == null) return;
    final map = tool.toMap();
    await supabase.from('personal_tools').update(map).eq('id', tool.id!);
    await _reloadTools();
  }

  Future<void> deleteTool(int id) async {
    await supabase.from('personal_tools').delete().eq('id', id);
    await _reloadTools();
  }

  // Métodos auxiliares pra kit do funcionário
  Future<List<Map<String, dynamic>>> getPersonalTools(int employeeId) async {
    final response = await supabase
        .from('personal_tools')
        .select()
        .eq('idTecnico', employeeId);
    return response;
  }

  Future<void> assignToolToEmployee(int catalogId, int employeeId, int qty) async {
    for (int i = 0; i < qty; i++) {
      await supabase.from('personal_tools').insert({
        'catalog_id': catalogId,
        'idTecnico': employeeId,
        'dataRetirada': DateTime.now().toIso8601String(),
      });
    }
    await _reloadTools();
  }

  Future<void> removeOneToolFromEmployee(int catalogId, int employeeId) async {
    final response = await supabase
        .from('personal_tools')
        .select('id')
        .eq('catalog_id', catalogId)
        .eq('idTecnico', employeeId)
        .limit(1);

    if (response.isNotEmpty) {
      final id = response.first['id'];
      await supabase.from('personal_tools').delete().eq('id', id);
      await _reloadTools();
    }
  }
}