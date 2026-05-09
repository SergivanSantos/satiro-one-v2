// lib/providers/brand_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brand.dart';

class BrandProvider with ChangeNotifier {
  List<Brand> _brands = [];
  bool _isLoading = true;
  String? _errorMessage;

  BrandProvider() {
    _loadBrandsStream();
  }

  List<Brand> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final supabase = Supabase.instance.client;

  void _loadBrandsStream() {
    _isLoading = true;
    notifyListeners();

    supabase
        .from('brands')
        .stream(primaryKey: ['id'])
        .order('name')
        .listen((List<Map<String, dynamic>> data) {
      _brands = data.map((map) => Brand.fromMap(map)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      print('BrandProvider: Stream atualizou - ${_brands.length} marcas');
    }, onError: (error) {
      _errorMessage = 'Erro no stream: $error';
      _isLoading = false;
      notifyListeners();
      print('BrandProvider: Erro no stream: $error');
    });
  }

  // MÉTODO NOVO — RECARREGA MANUALMENTE DO SUPABASE
  Future<void> _reloadBrands() async {
    try {
      final response = await supabase.from('brands').select().order('name');
      _brands = response.map((map) => Brand.fromMap(map as Map<String, dynamic>)).toList();
      notifyListeners();
      print('BrandProvider: Reload manual - ${_brands.length} marcas');
    } catch (e) {
      print('BrandProvider: Erro no reload manual: $e');
    }
  }

  Future<void> addBrand(Brand brand) async {
    try {
      final map = brand.toMap();
      map.remove('id');
      await supabase.from('brands').insert(map);
      await _reloadBrands(); // FORÇA RECARGA IMEDIATA
    } catch (e) {
      _errorMessage = 'Erro ao adicionar: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBrand(Brand brand) async {
    if (brand.id == null) return;

    try {
      final map = brand.toMap();
      map.remove('id'); // Remove o ID para permitir edição
      await supabase.from('brands').update(map).eq('id', brand.id!);
      await _reloadBrands(); // FORÇA RECARGA IMEDIATA
    } catch (e) {
      _errorMessage = 'Erro ao atualizar: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBrand(int id) async {
    try {
      await supabase.from('brands').delete().eq('id', id);
      await _reloadBrands(); // FORÇA RECARGA IMEDIATA
    } catch (e) {
      _errorMessage = 'Erro ao excluir: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}