// lib/features/atendimento/providers/atendimento_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AtendimentoProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  // ==================== MÉTODO ANTIGO (mantido para compatibilidade) ====================
  Future<bool> atualizarAtendimento({
    required String obraServicoId,
    required String status,
    String? solucaoPendencia,
    String? fotoPendenciaUrl,
  }) async {
    try {
      final data = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (solucaoPendencia != null && solucaoPendencia.isNotEmpty) {
        data['solucao_descricao'] = solucaoPendencia;
      }
      if (fotoPendenciaUrl != null && fotoPendenciaUrl.isNotEmpty) {
        data['foto_pendencia'] = [fotoPendenciaUrl] as String; // array para compatibilidade
      }

      await supabase.from('obra_servico').update(data).eq('id', obraServicoId);

      debugPrint("✅ Atendimento atualizado (método antigo) → $status");
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Erro no atualizarAtendimento: $e");
      return false;
    }
  }

  // ==================== NOVA: SALVAR PENDÊNCIA (texto + múltiplas fotos) ====================
  Future<bool> salvarPendencia({
    required String obraServicoId,
    required String pendenciaDescricao,
    required List<String> fotosUrls, // múltiplas fotos
  }) async {
    try {
      await supabase.from('obra_servico').update({
        'status': 'pendente',
        'pendencia_descricao': pendenciaDescricao,
        'foto_pendencia': fotosUrls.isNotEmpty ? fotosUrls : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', obraServicoId);

      debugPrint("✅ Pendência salva com ${fotosUrls.length} fotos");
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar pendência: $e");
      return false;
    }
  }

  // ==================== NOVA: SALVAR SOLUÇÃO ====================
  Future<bool> salvarSolucao({
    required String obraServicoId,
    required String solucaoDescricao,
    required List<String> fotosUrls, // opcional
  }) async {
    try {
      await supabase.from('obra_servico').update({
        'status': 'concluido',
        'solucao_descricao': solucaoDescricao,
        'foto_solucao': fotosUrls.isNotEmpty ? fotosUrls : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', obraServicoId);

      debugPrint("✅ Solução salva com ${fotosUrls.length} fotos");
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar solução: $e");
      return false;
    }
  }

  // ==================== MÉTODO AUXILIAR (opcional) ====================
  Future<bool> atualizarStatusSimples(String obraServicoId, String novoStatus) async {
    try {
      await supabase.from('obra_servico').update({
        'status': novoStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', obraServicoId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status simples: $e");
      return false;
    }
  }
}