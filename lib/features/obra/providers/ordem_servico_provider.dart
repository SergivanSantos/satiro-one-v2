// lib/features/obra/providers/ordem_servico_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../rh/providers/employee_provider.dart';
import '../models/ordem_servico.dart';

class OrdemServicoProvider extends ChangeNotifier {
  List<OrdemServico> ordens = [];
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> carregarOrdensDaObra(String obraId) async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint("🔄 [OrdemServicoProvider] Carregando ordens da obra: $obraId");
      final res = await supabase
          .from('ordem_servico')
          .select()
          .eq('obra_id', obraId)
          .order('created_at', ascending: false);

      ordens = res.map<OrdemServico>((o) => OrdemServico.fromMap(o)).toList();
      debugPrint("✅ ${ordens.length} ordens carregadas para a obra $obraId");

      // Log dos serviços para debug
      for (var ordem in ordens) {
        debugPrint("   → Ordem '${ordem.titulo}' | Serviços: ${ordem.servicosIds.length} | IDs: ${ordem.servicosIds}");
      }
    } catch (e) {
      debugPrint("❌ Erro ao carregar ordens de serviço: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> salvarOrdem(OrdemServico ordem) async {
    try {
      debugPrint("📤 Salvando ordem: ${ordem.titulo} (fase: ${ordem.faseId})");
      await supabase.from('ordem_servico').insert(ordem.toMap());
      await carregarOrdensDaObra(ordem.obraId);
      debugPrint("✅ Ordem salva com sucesso");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar ordem de serviço: $e");
      return false;
    }
  }

  Future<bool> atualizarStatus(String id, String novoStatus, String obraId) async {
    try {
      debugPrint("🔄 Atualizando status da ordem $id para: $novoStatus");
      await supabase
          .from('ordem_servico')
          .update({'status': novoStatus})
          .eq('id', id);
      await carregarOrdensDaObra(obraId);
      debugPrint("✅ Status atualizado");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status: $e");
      return false;
    }
  }

  // Carrega apenas as ordens atribuídas ao técnico logado
  Future<void> carregarOrdensDoTecnico() async {
    try {
      final currentEmployee = EmployeeProvider().currentEmployee; // Ajuste se for singleton ou use context
      final tecnicoId = currentEmployee?.id?.toString();

      if (tecnicoId == null) {
        debugPrint("⚠️ Nenhum técnico logado");
        ordens = [];
        notifyListeners();
        return;
      }

      isLoading = true;
      notifyListeners();

      debugPrint("🔄 Carregando ordens do técnico: $tecnicoId");

      final res = await supabase
          .from('ordem_servico')
          .select()
          .contains('responsaveis_ids', [tecnicoId])
          .order('created_at', ascending: false);

      ordens = res.map<OrdemServico>((o) => OrdemServico.fromMap(o)).toList();
      debugPrint("✅ ${ordens.length} ordens encontradas para o técnico $tecnicoId");
    } catch (e) {
      debugPrint("❌ Erro ao carregar ordens do técnico: $e");
      ordens = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==================== CRIAÇÃO AUTOMÁTICA ====================
  Future<void> criarOrdensAutomaticasParaObra(String obraId) async {
    debugPrint("🤖 Iniciando geração automática de ordens para obra: $obraId");

    try {
      final fasesDaObra = await supabase
          .from('obra_fase')
          .select('''
            fase_id,
            fase:fase!inner (
              nome,
              exige_ordem_servico
            )
          ''')
          .eq('obra_id', obraId);

      debugPrint("📋 Encontradas ${fasesDaObra.length} fases na obra");

      int criadas = 0;

      for (var item in fasesDaObra) {
        final faseId = item['fase_id'] as String;
        final faseData = item['fase'] as Map<String, dynamic>?;

        final exigeOrdem = faseData?['exige_ordem_servico'] as bool? ?? false;
        final faseNome = faseData?['nome'] as String? ?? 'Fase Desconhecida';

        if (!exigeOrdem) {
          debugPrint("⏭️ Fase '$faseNome' não exige ordem de serviço. Ignorando.");
          continue;
        }

        final existe = await supabase
            .from('ordem_servico')
            .select('id')
            .eq('obra_id', obraId)
            .eq('fase_id', faseId)
            .limit(1);

        if (existe.isNotEmpty) {
          debugPrint("⚠️ Já existe ordem para fase: $faseNome");
          continue;
        }

        // Busca serviços da fase
        final servicosRes = await supabase
            .from('obra_servico')
            .select('servico_id')
            .eq('obra_id', obraId)
            .eq('fase_id', faseId);

        final servicosIds = servicosRes.map((s) => s['servico_id'] as String).toList();

        debugPrint("📌 Fase '$faseNome' tem ${servicosIds.length} serviços vinculados");

        final ordem = OrdemServico(
          obraId: obraId,
          faseId: faseId,
          titulo: "OS - $faseNome",
          descricao: "Ordem de Serviço gerada automaticamente para a fase $faseNome",
          status: 'pendente',
          servicosIds: servicosIds,
        );

        await supabase.from('ordem_servico').insert(ordem.toMap());
        debugPrint("✅ Ordem criada automaticamente: $faseNome (${servicosIds.length} serviços)");
        criadas++;
      }

      debugPrint("🎉 Total de $criadas ordens de serviço geradas automaticamente.");

      await carregarOrdensDaObra(obraId);
    } catch (e, stack) {
      debugPrint("❌ Erro ao gerar ordens automáticas: $e");
      debugPrint("Stack: $stack");
    }
  }
}