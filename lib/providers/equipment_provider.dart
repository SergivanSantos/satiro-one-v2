// lib/providers/equipment_provider.dart
import 'package:flutter/foundation.dart'; // ← ADICIONE ESSE IMPORT
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/equipment.dart';

class EquipmentProvider with ChangeNotifier {
  List<Equipment> _equipments = [];
  bool _isLoading = true;
  String? _errorMessage;

  EquipmentProvider() {
    _loadEquipmentsStream();
  }

  List<Equipment> get equipments => _equipments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _loadEquipmentsStream() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    supabase
        .from('equipments')
        .stream(primaryKey: ['id'])
        .order('name')
        .listen(
          (List<Map<String, dynamic>> data) {
        _equipments = data.map((map) => Equipment.fromMap(map)).toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        debugPrint('EquipmentProvider: Equipamentos atualizados: ${_equipments.length}');
      },
      onError: (error) {
        _errorMessage = 'Erro no stream de equipamentos: $error';
        _isLoading = false;
        notifyListeners();
        debugPrint('EquipmentProvider: Erro no stream: $error');
      },
      onDone: () {
        debugPrint('EquipmentProvider: Stream de equipamentos finalizado');
      },
    );
  }

  // Método para forçar refresh manual
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
  }

  Future<Equipment?> getEquipmentById(int id) async {
    try {
      final response = await supabase
          .from('equipments')
          .select()
          .eq('id', id)
          .single();

      return Equipment.fromMap(response);
    } catch (e) {
      debugPrint('Erro ao buscar equipamento por ID: $e');
      return null;
    }
  }

  Future<void> addEquipment(Equipment equipment) async {
    try {
      final map = equipment.toMap();
      map.remove('id');

      await supabase.from('equipments').insert(map);
      notifyListeners();
      debugPrint('EquipmentProvider: Equipamento adicionado com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao adicionar equipamento: $e';
      notifyListeners();
      debugPrint('EquipmentProvider: Erro ao adicionar: $e');
      rethrow;
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    if (equipment.id == null) {
      throw Exception('ID do equipamento é obrigatório para atualização');
    }

    try {
      final map = equipment.toMap();
      map.remove('id');

      await supabase.from('equipments').update(map).eq('id', equipment.id!);
      notifyListeners();
      debugPrint('EquipmentProvider: Equipamento atualizado com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao atualizar equipamento: $e';
      notifyListeners();
      debugPrint('EquipmentProvider: Erro ao atualizar: $e');
      rethrow;
    }
  }

  Future<void> deleteEquipment(int id) async {
    try {
      await supabase.from('equipments').delete().eq('id', id);
      notifyListeners();
      debugPrint('EquipmentProvider: Equipamento excluído com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao excluir equipamento: $e';
      notifyListeners();
      debugPrint('EquipmentProvider: Erro ao excluir: $e');
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}