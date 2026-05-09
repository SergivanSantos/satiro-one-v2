// lib/providers/birthday_message_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BirthdayMessageProvider with ChangeNotifier {
  String _birthdayMessage =
      'Parabéns pelo seu aniversário, {nome}! \nDesejamos saúde, sucesso e muitas realizações!\nEquipe Satiro One';
  bool _isLoading = true;

  String get birthdayMessage => _birthdayMessage;
  bool get isLoading => _isLoading;

  final supabase = Supabase.instance.client;

  BirthdayMessageProvider() {
    _loadMessage();
  }

  Future<void> _loadMessage() async {
    try {
      final response = await supabase
          .from('app_settings')
          .select('birthday_message')
          .eq('id', 'global')
          .single();

      if (response['birthday_message'] != null) {
        _birthdayMessage = response['birthday_message'] as String;
      }
    } catch (e) {
      debugPrint('Erro ao carregar mensagem de aniversário: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBirthdayMessage(String newMessage) async {
    try {
      await supabase.from('app_settings').update({
        'birthday_message': newMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', 'global');

      _birthdayMessage = newMessage;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}