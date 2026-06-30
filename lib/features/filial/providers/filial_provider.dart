import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/filial.dart';
import '../models/filial_fiscal.dart';

class FilialProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Filial> filiais = [];
  Map<String, FilialFiscal> fiscaisPorFilial = {};

  // ===================== FILIAIS =====================
  Future<void> carregarFiliais() async {
    try {
      debugPrint("🔄 Carregando filiais...");
      final response = await _supabase
          .from('filiais')
          .select()
          .order('nome', ascending: true);

      filiais = response.map<Filial>((json) => Filial.fromJson(json)).toList();
      debugPrint("✅ ${filiais.length} filiais carregadas");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar filiais: $e");
    }
  }

  // ===================== DADOS FISCAIS =====================
  Future<void> carregarFiscal(String filialId) async {
    try {
      debugPrint("🔄 Carregando dados fiscais da filial: $filialId");

      final response = await _supabase
          .from('filial_fiscal')                    // ← Tabela corrigida
          .select()
          .eq('filial_id', filialId)
          .maybeSingle();                           // Usa maybeSingle para não dar erro

      if (response != null) {
        fiscaisPorFilial[filialId] = FilialFiscal.fromJson(response);
        debugPrint("✅ Dados fiscais carregados com sucesso");
      } else {
        fiscaisPorFilial.remove(filialId);
        debugPrint("ℹ️ Nenhum dado fiscal encontrado para esta filial");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar fiscal: $e");
      fiscaisPorFilial.remove(filialId);
    }
  }

  Future<bool> salvarFiscal(FilialFiscal fiscal) async {
    debugPrint("🔄 === INICIANDO SALVAMENTO DE DADOS FISCAIS ===");
    debugPrint("   Filial ID : ${fiscal.filialId}");
    debugPrint("   CNPJ      : ${fiscal.cnpj}");
    debugPrint("   Razão     : ${fiscal.razaoSocial}");

    try {
      final data = fiscal.toJson();
      debugPrint("📤 Dados sendo enviados: $data");

      final response = await _supabase
          .from('filial_fiscal')                    // ← Tabela corrigida
          .upsert(data)
          .select();

      debugPrint("✅ Resposta do Supabase: $response");

      if (response != null && response.isNotEmpty) {
        debugPrint("🎉 SALVAMENTO REALIZADO COM SUCESSO!");
        await carregarFiscal(fiscal.filialId);
        return true;
      } else {
        debugPrint("⚠️ Resposta vazia do Supabase");
        return false;
      }
    } catch (e) {
      debugPrint("❌ ERRO AO SALVAR NO SUPABASE: $e");

      if (e is PostgrestException) {
        debugPrint("   Código do erro: ${e.code}");
        debugPrint("   Mensagem: ${e.message}");
      }

      return false;
    }
  }

  FilialFiscal? getFiscal(String filialId) => fiscaisPorFilial[filialId];

  // ===================== MÉTODOS DE FILIAIS (mantidos) =====================
  Future<bool> adicionarFilial(Filial filial) async {
    try {
      await _supabase.from('filiais').insert(filial.toJson());
      await carregarFiliais();
      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar filial: $e");
      return false;
    }
  }

  Future<bool> atualizarFilial(Filial filial) async {
    try {
      await _supabase.from('filiais').update(filial.toJson()).eq('id', filial.id);
      await carregarFiliais();
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar filial: $e");
      return false;
    }
  }

  Future<bool> removerFilial(String id) async {
    try {
      await _supabase.from('filiais').delete().eq('id', id);
      await carregarFiliais();
      fiscaisPorFilial.remove(id);
      return true;
    } catch (e) {
      debugPrint("Erro ao remover filial: $e");
      return false;
    }
  }
}