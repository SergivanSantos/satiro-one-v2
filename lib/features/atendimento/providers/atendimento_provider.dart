// lib/features/atendimento/providers/atendimento_provider.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AtendimentoProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  Future<List<String>> uploadFotos(List<XFile> files, String tipo) async {
    List<String> urls = [];
    for (var file in files) {
      try {
        final bytes = await file.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${tipo}_${file.name}';

        debugPrint("📤 Enviando foto: $fileName");

        final String uploadedPath = await supabase.storage
            .from('atendimentos')
            .uploadBinary(fileName, bytes);

        final String publicUrl = supabase.storage
            .from('atendimentos')
            .getPublicUrl(uploadedPath);

        urls.add(publicUrl);
        debugPrint("✅ Foto enviada com sucesso: $publicUrl");
      } catch (e, stack) {
        debugPrint("❌ Erro ao subir foto ${file.name}: $e");
        debugPrint("Stack: $stack");
      }
    }
    return urls;
  }

  // ==================== SALVAR PENDÊNCIA ====================
  Future<bool> salvarPendencia({
    required String obraServicoId,
    required String pendenciaDescricao,
    required String tecnicoNome,
    List<XFile> files = const [],
  }) async {
    try {
      List<String> urls = await uploadFotos(files, 'pendencia');

      await supabase.from('obra_servico').update({
        'status': 'pendente',
        'pendencia_descricao': pendenciaDescricao,
        'tecnico_nome': tecnicoNome,
        'data_atendimento': DateTime.now().toIso8601String(),
        'foto_pendencia': urls.isNotEmpty ? urls : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', obraServicoId);

      debugPrint("✅ Pendência salva com ${urls.length} fotos");
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint("❌ Erro ao salvar pendência: $e");
      debugPrint("Stack: $stack");
      return false;
    }
  }

  // ==================== SALVAR SOLUÇÃO ====================
  Future<bool> salvarSolucao({
    required String obraServicoId,
    required String solucaoDescricao,
    required String tecnicoNome,
    List<XFile> files = const [],
  }) async {
    try {
      List<String> urls = await uploadFotos(files, 'solucao');

      await supabase.from('obra_servico').update({
        'status': 'concluido',
        'solucao_descricao': solucaoDescricao,
        'tecnico_nome': tecnicoNome,
        'data_atendimento': DateTime.now().toIso8601String(),
        'foto_solucao': urls.isNotEmpty ? urls : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', obraServicoId);

      debugPrint("✅ Solução salva com ${urls.length} fotos");
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint("❌ Erro ao salvar solução: $e");
      debugPrint("Stack: $stack");
      return false;
    }
  }

  Future<bool> atualizarStatusSimples(String obraServicoId, String novoStatus) async {
    try {
      await supabase.from('obra_servico').update({
        'status': novoStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', obraServicoId);

      debugPrint("✅ Status simples atualizado para: $novoStatus");
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status simples: $e");
      return false;
    }
  }
}