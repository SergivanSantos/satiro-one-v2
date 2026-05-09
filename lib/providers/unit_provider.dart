// lib/providers/unit_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/unit.dart';

class UnitProvider with ChangeNotifier {
  List<Unit> _units = [];
  bool _isLoading = true;
  String? _errorMessage;

  UnitProvider() {
    _loadUnitsStream();
  }

  List<Unit> get units => _units;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _loadUnitsStream() {
    _isLoading = true;
    notifyListeners();

    supabase
        .from('units')
        .stream(primaryKey: ['id'])
        .order('name')
        .listen((List<Map<String, dynamic>> data) {
      _units = data.map((map) => Unit.fromMap(map)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      print('UnitProvider: Stream atualizou - ${_units.length} unidades');
    }, onError: (error) {
      _errorMessage = 'Erro no stream: $error';
      _isLoading = false;
      notifyListeners();
      print('UnitProvider: Erro no stream: $error');
    });
  }

  // MÉTODO NOVO — RECARREGA MANUALMENTE DO SUPABASE
  Future<void> _reloadUnits() async {
    try {
      final response = await supabase.from('units').select().order('name');
      _units = response.map((map) => Unit.fromMap(map as Map<String, dynamic>)).toList();
      notifyListeners();
      print('UnitProvider: Reload manual - ${_units.length} unidades');
    } catch (e) {
      print('UnitProvider: Erro no reload manual: $e');
    }
  }

  Future<void> addUnit(Unit unit) async {
    try {
      final map = unit.toMap();
      map.remove('id');
      await supabase.from('units').insert(map);
      await _reloadUnits(); // FORÇA RECARGA IMEDIATA
      print('UnitProvider: Unidade adicionada com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao adicionar: $e';
      notifyListeners();
      print('UnitProvider: Erro ao adicionar unidade: $e');
      rethrow;
    }
  }

  Future<void> updateUnit(Unit unit) async {
    if (unit.id == null) return;

    try {
      final map = unit.toMap();
      map.remove('id'); // Remove o ID para permitir edição
      await supabase.from('units').update(map).eq('id', unit.id!);
      await _reloadUnits(); // FORÇA RECARGA IMEDIATA
      print('UnitProvider: Unidade atualizada com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao atualizar: $e';
      notifyListeners();
      print('UnitProvider: Erro ao atualizar unidade: $e');
      rethrow;
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      await supabase.from('units').delete().eq('id', id);
      await _reloadUnits(); // FORÇA RECARGA IMEDIATA
      print('UnitProvider: Unidade excluída com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao excluir: $e';
      notifyListeners();
      print('UnitProvider: Erro ao excluir unidade: $e');
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}