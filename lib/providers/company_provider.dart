import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';

class CompanyProvider extends ChangeNotifier {
  List<Company> _companies = [];
  Company? _selectedCompany;
  bool _isLoading = false;
  String? _errorMessage;

  List<Company> get companies => _companies;
  Company? get selectedCompany => _selectedCompany;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CompanyProvider();

  Future<void> loadCompanies() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('companies')
          .select()
          .order('name');

      _companies = response.map((json) => Company.fromMap(json)).toList();

      if (_selectedCompany == null && _companies.isNotEmpty) {
        _selectedCompany = _companies.first;
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar empresas: $e';
      print(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCompany(Company company) {
    _selectedCompany = company;
    notifyListeners();
  }

  Future<void> addCompany(Company company) async {
    try {
      final map = company.toMap();
      await Supabase.instance.client.from('companies').insert(map);
      await loadCompanies();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCompany(Company company) async {
    try {
      final map = company.toMap();
      await Supabase.instance.client
          .from('companies')
          .update(map)
          .eq('id', company.id);
      await loadCompanies();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCompany(int id) async {
    try {
      await Supabase.instance.client.from('companies').delete().eq('id', id);
      await loadCompanies();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}