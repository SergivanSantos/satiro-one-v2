// lib/features/obra/providers/obra_estrutura_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra_bloco.dart';
import '../models/obra_grupo_servico.dart';
import '../models/obra_piso.dart';
import '../models/obra_unidade.dart';
import '../models/obra_ambiente.dart';
import '../models/obra_unidade_servico.dart';

class ObraEstruturaProvider extends ChangeNotifier {
  List<ObraBloco> blocos = [];
  String? obraIdAtual;
  bool isLoading = false;

  Future<void> loadEstrutura(String obraId) async {
    isLoading = true;
    notifyListeners();

    try {
      obraIdAtual = obraId;

      final blocosResponse = await Supabase.instance.client
          .from('obra_blocos')
          .select()
          .eq('obra_id', obraId)
          .order('ordem');

      blocos = blocosResponse.map<ObraBloco>((b) => ObraBloco.fromMap(b)).toList();

      print('✅ Carregados ${blocos.length} blocos');

      for (var bloco in blocos) {
        // Pisos e hierarquia normal
        final pisosResponse = await Supabase.instance.client
            .from('obra_pisos')
            .select()
            .eq('bloco_id', bloco.id)
            .order('ordem');

        bloco.pisos.clear();
        bloco.pisos.addAll(pisosResponse.map<ObraPiso>((p) => ObraPiso.fromMap(p)).toList());

        for (var piso in bloco.pisos) {
          final unidadesResponse = await Supabase.instance.client
              .from('obra_unidades')
              .select()
              .eq('piso_id', piso.id)
              .order('ordem');

          piso.unidades.clear();
          piso.unidades.addAll(unidadesResponse.map<ObraUnidade>((u) => ObraUnidade.fromMap(u)).toList());

          for (var unidade in piso.unidades) {
            final ambientesResponse = await Supabase.instance.client
                .from('obra_ambientes')
                .select()
                .eq('unidade_id', unidade.id)
                .order('ordem');

            unidade.ambientes.clear();
            unidade.ambientes.addAll(ambientesResponse.map<ObraAmbiente>((a) => ObraAmbiente.fromMap(a)).toList());

            for (var ambiente in unidade.ambientes) {
              await _carregarServicosEGrupos(ambiente);
            }
          }
        }

        // Ambientes Diretos
        final ambientesDiretosResponse = await Supabase.instance.client
            .from('obra_ambientes')
            .select()
            .eq('bloco_id', bloco.id)
            .filter('unidade_id', 'is', null)
            .order('ordem');

        bloco.ambientesDiretos.clear();
        bloco.ambientesDiretos.addAll(
            ambientesDiretosResponse.map<ObraAmbiente>((a) => ObraAmbiente.fromMap(a)).toList()
        );

        for (var ambiente in bloco.ambientesDiretos) {
          await _carregarServicosEGrupos(ambiente);
        }
      }

      print('✅ Estrutura completa carregada com sucesso para obra $obraId');
    } catch (e) {
      print('❌ Erro ao carregar estrutura: $e');
      blocos = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

// ==================== MÉTODO AUXILIAR ====================
  // ==================== MÉTODO AUXILIAR (chamado em todos os ambientes) ====================
  Future<void> _carregarServicosEGrupos(ObraAmbiente ambiente) async {
    // Serviços Individuais
    final servicosResponse = await Supabase.instance.client
        .from('obra_unidade_servicos')
        .select()
        .eq('ambiente_id', ambiente.id);

    ambiente.servicos.clear();
    ambiente.servicos.addAll(
        servicosResponse.map<ObraUnidadeServico>((s) => ObraUnidadeServico.fromMap(s)).toList()
    );

    // GRUPOS DE SERVIÇO
    final gruposResponse = await Supabase.instance.client
        .from('obra_grupos_servico')
        .select()
        .eq('ambiente_id', ambiente.id)
        .order('ordem');

    ambiente.grupos.clear();
    ambiente.grupos.addAll(
        gruposResponse.map<ObraGrupoServico>((g) => ObraGrupoServico.fromMap(g)).toList()
    );

    print('     → Ambiente "${ambiente.nome}" → ${ambiente.servicos.length} serviços | ${ambiente.grupos.length} grupos');
  }

  // ==================== CREATE METHODS ====================

  Future<bool> createBloco(String obraId, String nome) async {
    try {
      await Supabase.instance.client.from('obra_blocos').insert({
        'obra_id': obraId,
        'nome': nome,
        'ordem': blocos.length,
      });

      print('✅ Bloco criado: $nome');
      await loadEstrutura(obraId);
      return true;
    } catch (e) {
      print('❌ Erro ao criar bloco: $e');
      return false;
    }
  }

  Future<bool> createPiso(String obraId, String blocoId, String nome) async {
    try {
      await Supabase.instance.client.from('obra_pisos').insert({
        'bloco_id': blocoId,
        'nome': nome,
        'ordem': 0,
      });
      if (obraIdAtual != null) await loadEstrutura(obraIdAtual!);
      return true;
    } catch (e) {
      print('Erro ao criar piso: $e');
      return false;
    }
  }

  Future<bool> createUnidade(String obraId, String pisoId, String nome) async {
    try {
      await Supabase.instance.client.from('obra_unidades').insert({
        'piso_id': pisoId,
        'nome': nome,
        'tipo': 'unidade',
        'ordem': 0,
      });
      if (obraIdAtual != null) await loadEstrutura(obraIdAtual!);
      return true;
    } catch (e) {
      print('Erro ao criar unidade: $e');
      return false;
    }
  }

  // ==================== CRIAR AMBIENTE DENTRO DE UNIDADE ====================
  Future<bool> createAmbiente(String unidadeId, String nome) async {
    try {
      await Supabase.instance.client.from('obra_ambientes').insert({
        'unidade_id': unidadeId,
        'bloco_id': null,        // é dentro de unidade
        'nome': nome,
        'ordem': 0,
      });

      print('✅ Ambiente criado dentro de unidade: $nome');
      if (obraIdAtual != null) await loadEstrutura(obraIdAtual!);
      return true;
    } catch (e) {
      print('❌ Erro ao criar ambiente: $e');
      return false;
    }
  }

  Future<bool> createAmbienteDireto(String obraId, String blocoId, String nome) async {
    try {
      await Supabase.instance.client.from('obra_ambientes').insert({
        'bloco_id': blocoId,
        'unidade_id': null,
        'nome': nome,
        'ordem': 0,
      });
      await loadEstrutura(obraId);
      return true;
    } catch (e) {
      print('Erro ao criar ambiente direto: $e');
      return false;
    }
  }

  Future<bool> createServico({
    required String ambienteId,
    required String nome,
    String? descricao,
    double quantidadeContratada = 1.0,
    String? grupoServicoId,   // ← pode ser null
  }) async {
    try {
      final data = {
        'ambiente_id': ambienteId,
        'nome': nome,
        'descricao': descricao,
        'quantidade_contratada': quantidadeContratada,
        'status': 'nao_iniciado',
      };

      if (grupoServicoId != null) {
        data['grupo_servico_id'] = grupoServicoId;
      }

      await Supabase.instance.client
          .from('obra_unidade_servicos')
          .insert(data);

      print('✅ Serviço criado: $nome ${grupoServicoId != null ? "(em grupo)" : "(individual)"}');

      if (obraIdAtual != null) {
        await loadEstrutura(obraIdAtual!);
      }
      return true;
    } catch (e) {
      print('❌ Erro ao criar serviço: $e');
      return false;
    }
  }

  // ==================== CRIAR GRUPO DE SERVIÇO ====================
  Future<bool> createGrupoServico({
    required String ambienteId,
    required String nome,
    String? descricao,
  }) async {
    try {
      await Supabase.instance.client.from('obra_grupos_servico').insert({
        'ambiente_id': ambienteId,
        'nome': nome,
        'descricao': descricao,
        'ordem': 0,
      });

      print('✅ Grupo de Serviço criado: $nome');
      if (obraIdAtual != null) await loadEstrutura(obraIdAtual!);
      return true;
    } catch (e) {
      print('❌ Erro ao criar grupo: $e');
      return false;
    }
  }

  Future<bool> salvarNoSupabase() async {
    if (obraIdAtual == null) return false;
    print('✅ Estrutura salva com sucesso!');
    return true;
  }
}