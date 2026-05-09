// lib/providers/supplier_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/supplier.dart';

class SupplierProvider with ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  String? _errorMessage;

  SupplierProvider() {
    _loadSuppliersStream();
  }

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _loadSuppliersStream() {
    _isLoading = true;
    notifyListeners();

    supabase
        .from('suppliers')
        .stream(primaryKey: ['id'])
        .order('name')
        .listen((List<Map<String, dynamic>> data) {
      _suppliers = data.map((map) => Supplier.fromMap(map)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      print('SupplierProvider: Stream atualizou - ${_suppliers.length} fornecedores');
    }, onError: (error) {
      _errorMessage = 'Erro no stream: $error';
      _isLoading = false;
      notifyListeners();
      print('SupplierProvider: Erro no stream: $error');
    });
  }

  // Recarrega manualmente (útil após insert/delete para sincronia imediata)
  Future<void> _reloadSuppliers() async {
    try {
      final response = await supabase.from('suppliers').select().order('name');
      _suppliers = response.map((map) => Supplier.fromMap(map as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      print('SupplierProvider: Erro no reload manual: $e');
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      final map = supplier.toMap();
      map.remove('id'); // Não envia id no insert
      await supabase.from('suppliers').insert(map);
      await _reloadSuppliers();
      print('SupplierProvider: Fornecedor adicionado com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao adicionar: $e';
      notifyListeners();
      print('SupplierProvider: Erro ao adicionar fornecedor: $e');
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    if (supplier.id == null) return;

    try {
      final map = supplier.toMap();
      map.remove('id'); // ← CORREÇÃO PRINCIPAL: não envia id no update!

      await supabase
          .from('suppliers')
          .update(map)
          .eq('id', supplier.id!);

      await _reloadSuppliers();
      print('SupplierProvider: Fornecedor atualizado com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao atualizar: $e';
      notifyListeners();
      print('SupplierProvider: Erro ao atualizar fornecedor: $e');
      rethrow;
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await supabase.from('suppliers').delete().eq('id', id);
      await _reloadSuppliers();
      print('SupplierProvider: Fornecedor excluído com sucesso');
    } catch (e) {
      _errorMessage = 'Erro ao excluir: $e';
      notifyListeners();
      print('SupplierProvider: Erro ao excluir fornecedor: $e');
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}