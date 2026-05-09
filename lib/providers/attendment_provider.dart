// lib/providers/attendment_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendment.dart';

class AttendmentProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Attendment> _attendments = [];
  bool _isLoading = true;
  String? _error;

  List<Attendment> get attendments => _attendments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAttendments(int clientId) async {
    try {
      final response = await _supabase
          .from('attendments')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      _attendments = response.map((json) => Attendment.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar atendimentos: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAttendment(Attendment attendment) async {
    try {
      await _supabase.from('attendments').insert(attendment.toJson());
      await loadAttendments(attendment.clientId);
      _error = null;
    } catch (e) {
      _error = 'Erro ao adicionar atendimento: $e';
      notifyListeners();
    }
  }

  Future<void> updateAttendment(Attendment attendment) async {
    try {
      await _supabase.from('attendments').update(attendment.toJson()).eq('id', attendment.id!);
      await loadAttendments(attendment.clientId);
      _error = null;
    } catch (e) {
      _error = 'Erro ao atualizar atendimento: $e';
      notifyListeners();
    }
  }

  Future<void> deleteAttendment(int id, int clientId) async {
    try {
      await _supabase.from('attendments').delete().eq('id', id);
      await loadAttendments(clientId);
      _error = null;
    } catch (e) {
      _error = 'Erro ao excluir atendimento: $e';
      notifyListeners();
    }
  }
}