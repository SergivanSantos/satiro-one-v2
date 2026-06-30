// lib/features/obra/providers/obra_wizard_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../models/obra.dart';
import '../../fase/models/fase.dart';
import 'obra_provider.dart';   // ← Import necessário

class ObraWizardProvider extends ChangeNotifier {
  String nomeObra = '';
  String? clienteId;
  String? filialId;
  String? arquitetoId;
  String? construtoraId;
  DateTime? dataInicio;

  List<Fase> todasFases = [];
  List<String> fasesSelecionadasIds = [];
  bool _usaFases = false;
  bool get usaFases => _usaFases;

  List<PisoTemp> pisos = [];

  List<Map<String, dynamic>> _filiaisDisponiveis = [];
  List<Map<String, dynamic>> get filiaisDisponiveis => _filiaisDisponiveis;

  String? obraIdParaEditar;

  // ... (todos os métodos anteriores permanecem iguais)

  void atualizarNomeObra(String nome) {
    nomeObra = nome.trim();
    notifyListeners();
  }

  void setClienteId(String? id) {
    clienteId = id;
    notifyListeners();
  }

  void setFilialId(String? id) {
    filialId = id;
    notifyListeners();
  }

  void setArquiteto(String? id) {
    arquitetoId = id;
    notifyListeners();
  }

  void setConstrutora(String? id) {
    construtoraId = id;
    notifyListeners();
  }

  void setUsaFases(bool value) {
    _usaFases = value;
    if (!value) fasesSelecionadasIds.clear();
    notifyListeners();
  }

  Future<void> carregarFasesDisponiveis() async {
    try {
      final res = await Supabase.instance.client
          .from('fase')
          .select()
          .eq('ativo', true)
          .order('ordem', ascending: true);

      todasFases = res.map<Fase>((f) => Fase.fromMap(f)).toList();
      notifyListeners();
      debugPrint("✅ ${todasFases.length} fases carregadas");
    } catch (e) {
      debugPrint("❌ Erro ao carregar fases: $e");
    }
  }

  Future<void> carregarFiliais() async {
    try {
      final res = await Supabase.instance.client
          .from('filiais')
          .select('id, nome')
          .eq('ativa', true)
          .order('nome');

      _filiaisDisponiveis = List<Map<String, dynamic>>.from(res);
      notifyListeners();
      debugPrint("✅ ${_filiaisDisponiveis.length} filiais carregadas no Wizard");
    } catch (e) {
      debugPrint("❌ Erro ao carregar filiais: $e");
    }
  }

  void carregarObraParaEdicao(Obra obra) {
    obraIdParaEditar = obra.id;
    nomeObra = obra.nome;
    clienteId = obra.clienteId;
    filialId = obra.filialId;
    arquitetoId = obra.arquitetoId;
    construtoraId = obra.construtoraId;
    dataInicio = obra.dataInicio;
    _usaFases = obra.usaFases;

    _carregarFasesDaObra(obra.id);
    notifyListeners();
  }

  Future<void> _carregarFasesDaObra(String obraId) async {
    try {
      final res = await Supabase.instance.client
          .from('obra_fase')
          .select('fase_id')
          .eq('obra_id', obraId);

      fasesSelecionadasIds = res.map((f) => f['fase_id'].toString()).toList();
      debugPrint("✅ ${fasesSelecionadasIds.length} fases carregadas da obra em edição");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar fases da obra: $e");
    }
  }

  void toggleFase(String faseId) {
    if (fasesSelecionadasIds.contains(faseId)) {
      fasesSelecionadasIds.remove(faseId);
    } else {
      fasesSelecionadasIds.add(faseId);
    }
    notifyListeners();
  }

  void selecionarTodasFases() {
    fasesSelecionadasIds = todasFases.map((f) => f.id).toList();
    notifyListeners();
  }

  void limparSelecaoFases() {
    fasesSelecionadasIds.clear();
    notifyListeners();
  }

  void adicionarPiso(String nome) {
    if (nome.trim().isEmpty) return;
    if (pisos.any((p) => p.nome.toLowerCase() == nome.trim().toLowerCase())) return;

    pisos.add(PisoTemp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome.trim(),
      ambientes: [],
    ));
    notifyListeners();
  }

  void removerPiso(String pisoId) {
    pisos.removeWhere((p) => p.id == pisoId);
    notifyListeners();
  }

  void adicionarAmbiente(String pisoId, String nomeAmbiente) {
    if (nomeAmbiente.trim().isEmpty) return;
    final piso = pisos.firstWhere((p) => p.id == pisoId, orElse: () => PisoTemp(id: '', nome: '', ambientes: []));
    if (!piso.ambientes.contains(nomeAmbiente.trim())) {
      piso.ambientes.add(nomeAmbiente.trim());
      notifyListeners();
    }
  }

  void removerAmbiente(String pisoId, String nomeAmbiente) {
    final piso = pisos.firstWhere((p) => p.id == pisoId, orElse: () => PisoTemp(id: '', nome: '', ambientes: []));
    piso.ambientes.remove(nomeAmbiente.trim());
    notifyListeners();
  }

  // ==================== MÉTODO PRINCIPAL ====================
  Future<bool> salvarObra(BuildContext context) async {
    if (nomeObra.trim().isEmpty) {
      debugPrint("❌ Nome da obra é obrigatório");
      return false;
    }

    debugPrint("💾 Iniciando salvamento da obra: $nomeObra");

    try {
      final data = {
        'nome': nomeObra,
        'cliente_id': clienteId,
        'filial_id': filialId,
        'arquiteto_id': arquitetoId,
        'construtora_id': construtoraId,
        'data_inicio': dataInicio?.toIso8601String().split('T')[0],
        'status': 'em_andamento',
        'usa_fases': _usaFases,
      };

      String obraId;

      if (obraIdParaEditar != null) {
        await Supabase.instance.client
            .from('obra')
            .update(data)
            .eq('id', obraIdParaEditar!);

        obraId = obraIdParaEditar!;
        debugPrint("✅ Obra atualizada com ID: $obraId");

        await Supabase.instance.client.from('obra_fase').delete().eq('obra_id', obraId);
        await Supabase.instance.client.from('pavimento').delete().eq('obra_id_original', obraId);
        await Supabase.instance.client.from('obra_ambiente').delete().eq('obra_id', obraId);

      } else {
        final response = await Supabase.instance.client
            .from('obra')
            .insert(data)
            .select()
            .single();

        obraId = response['id'] as String;
        debugPrint("✅ Obra criada com ID: $obraId");
      }

      if (_usaFases && fasesSelecionadasIds.isNotEmpty) {
        await _salvarFasesDaObra(obraId);
      }

      if (pisos.isNotEmpty) {
        await _salvarEstrutura(obraId);
      }

      // Atualiza automaticamente o provider principal
      if (context.mounted) {
        context.read<ObraProvider>().loadObras();
      }

      limparDados();
      debugPrint("🎉 Obra salva com sucesso!");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar obra: $e");
      return false;
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================
  Future<void> _salvarFasesDaObra(String obraId) async {
    try {
      final inserts = fasesSelecionadasIds.map((faseId) => {
        'obra_id': obraId,
        'fase_id': faseId,
        'status': 'pendente',
      }).toList();

      await Supabase.instance.client.from('obra_fase').insert(inserts);
      debugPrint("✅ ${fasesSelecionadasIds.length} fases vinculadas");
    } catch (e) {
      debugPrint("❌ Erro ao vincular fases: $e");
    }
  }

  Future<void> _salvarEstrutura(String obraId) async {
    if (pisos.isEmpty) return;

    debugPrint("🏗️ Salvando estrutura...");

    try {
      for (int i = 0; i < pisos.length; i++) {
        final pisoTemp = pisos[i];

        final pisoResponse = await Supabase.instance.client
            .from('pavimento')
            .insert({
          'obra_id_original': obraId,
          'nome': pisoTemp.nome,
          'ordem': i + 1,
          'ativo': true,
        })
            .select()
            .single();

        final String pisoId = pisoResponse['id'];

        for (int j = 0; j < pisoTemp.ambientes.length; j++) {
          final nomeAmb = pisoTemp.ambientes[j];

          await Supabase.instance.client.from('obra_ambiente').insert({
            'obra_id': obraId,
            'obra_piso_id': pisoId,
            'nome': nomeAmb,
            'ordem': j + 1,
            'ativo': true,
          });
        }
      }
      debugPrint("✅ Estrutura salva com sucesso! (${pisos.length} pavimentos)");
    } catch (e) {
      debugPrint("❌ Erro ao salvar estrutura: $e");
    }
  }

  void limparDados() {
    nomeObra = '';
    clienteId = null;
    filialId = null;
    arquitetoId = null;
    construtoraId = null;
    dataInicio = null;
    _usaFases = false;
    fasesSelecionadasIds.clear();
    pisos.clear();
    obraIdParaEditar = null;
    notifyListeners();
  }
}

class PisoTemp {
  final String id;
  final String nome;
  final List<String> ambientes;

  PisoTemp({
    required this.id,
    required this.nome,
    required this.ambientes,
  });
}