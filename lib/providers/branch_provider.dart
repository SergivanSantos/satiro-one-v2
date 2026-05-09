// lib/providers/branch_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';

import '../models/branch.dart';

class BranchProvider with ChangeNotifier {
  List<Branch> _branches = [];
  Branch? _currentBranch;
  bool _isMaster = false; // true = vê todas as filiais
  bool _isLoading = true;
  String? _errorMessage;

  final supabase = Supabase.instance.client;

  List<Branch> get branches => _branches;
  Branch? get currentBranch => _currentBranch;
  bool get isMaster => _isMaster;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BranchProvider() {
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await supabase.from('branches').select().order('name');
      _branches = response.map((map) => Branch.fromMap(map)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('BranchProvider: Erro ao carregar filiais: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Chamado após login, define filial atual do usuário logado

  void setUserBranch(String? branchId, bool isMaster) {
    _isMaster = isMaster;
    if (isMaster) {
      _currentBranch = null; // Master vê tudo
    } else {
      _currentBranch = _branches.firstWhereOrNull((b) => b.id == branchId);

      // Se não encontrar, pega a primeira (ou null se lista vazia)
      if (_currentBranch == null && _branches.isNotEmpty) {
        _currentBranch = _branches.first;
      }
    }
    notifyListeners();
  }

  // Troca temporária (ex: supervisor atende outra filial)
  void setTemporaryBranch(String? branchId) {
    if (branchId == null) {
      _currentBranch = _branches.firstWhere((b) => b.id == _currentBranch?.id);
    } else {
      _currentBranch = _branches.firstWhere((b) => b.id == branchId);
    }
    notifyListeners();
  }

  Future<void> addBranch(Branch branch) async {
    try {
      final map = branch.toMap();
      map.remove('id');
      map.remove('created_at');
      map.remove('updated_at');
      await supabase.from('branches').insert(map);
      await _loadBranches();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBranch(Branch branch) async {
    try {
      final map = branch.toMap();
      map.remove('id');
      map.remove('created_at');
      map.remove('updated_at');
      await supabase.from('branches').update(map).eq('id', branch.id);
      await _loadBranches();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      await supabase.from('branches').delete().eq('id', id);
      await _loadBranches();
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