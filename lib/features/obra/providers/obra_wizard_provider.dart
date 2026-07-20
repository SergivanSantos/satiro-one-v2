// lib/features/obra/providers/obra_wizard_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../../fase/models/fase.dart';
import 'obra_provider.dart';

class ObraWizardProvider extends ChangeNotifier {
  String nomeObra = '';
  String? clienteId;
  String? filialId;
  String? arquitetoId;
  String? construtoraId;
  DateTime? dataInicio;

  // Novos campos
  String? responsavelNome;
  String? responsavelContato;
  String? rua;
  String? numero;
  String? bairro;
  String? cidade;
  String? estado;
  String? complemento;

  List<Fase> todasFases = [];
  List<String> fasesSelecionadasIds = [];
  bool _usaFases = false;
  bool get usaFases => _usaFases;

  List<PisoTemp> pisos = [];

  List<Map<String, dynamic>> _filiaisDisponiveis = [];
  List<Map<String, dynamic>> get filiaisDisponiveis => _filiaisDisponiveis;

  String? obraIdParaEditar;

  // ==================== SETTERS ====================
  void atualizarNomeObra(String nome) {
    nomeObra = nome.trim();
    notifyListeners();
  }

  void setClienteId(String? id) { clienteId = id; notifyListeners(); }
  void setFilialId(String? id) { filialId = id; notifyListeners(); }
  void setArquiteto(String? id) { arquitetoId = id; notifyListeners(); }
  void setConstrutora(String? id) { construtoraId = id; notifyListeners(); }

  void setResponsavelNome(String? valor) { responsavelNome = valor?.trim(); notifyListeners(); }
  void setResponsavelContato(String? valor) { responsavelContato = valor?.trim(); notifyListeners(); }
  void setRua(String? valor) { rua = valor?.trim(); notifyListeners(); }
  void setNumero(String? valor) { numero = valor?.trim(); notifyListeners(); }
  void setBairro(String? valor) { bairro = valor?.trim(); notifyListeners(); }
  void setCidade(String? valor) { cidade = valor?.trim(); notifyListeners(); }
  void setEstado(String? valor) { estado = valor?.trim().toUpperCase(); notifyListeners(); }
  void setComplemento(String? valor) { complemento = valor?.trim(); notifyListeners(); }

  void setUsaFases(bool value) {
    _usaFases = value;
    if (!value) fasesSelecionadasIds.clear();
    notifyListeners();
  }

  // ==================== CARREGAMENTO ====================
  Future<void> carregarFasesDisponiveis() async {
    try {
      final res = await Supabase.instance.client
          .from('fase')
          .select()
          .eq('ativo', true)
          .order('ordem');
      todasFases = res.map<Fase>((f) => Fase.fromMap(f)).toList();
      notifyListeners();
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
    _usaFases = obra.usaFases ?? false;

    responsavelNome = obra.responsavelNome;
    responsavelContato = obra.responsavelContato;
    rua = obra.rua;
    numero = obra.numero;
    bairro = obra.bairro;
    cidade = obra.cidade;
    estado = obra.estado;
    complemento = obra.complemento;

    _carregarFasesDaObra(obra.id);
    _carregarEstruturaDaObra(obra.id);   // ← Carrega pavimentos + ambientes
    notifyListeners();
  }

  Future<void> _carregarFasesDaObra(String obraId) async {
    try {
      final res = await Supabase.instance.client
          .from('obra_fase')
          .select('fase_id')
          .eq('obra_id', obraId);
      fasesSelecionadasIds = res.map((f) => f['fase_id'].toString()).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erro ao carregar fases: $e");
    }
  }

  Future<void> _carregarEstruturaDaObra(String obraId) async {
    try {
      final pavimentosRes = await Supabase.instance.client
          .from('pavimento')
          .select()
          .eq('obra_id_original', obraId)
          .order('ordem');

      pisos.clear();

      for (final p in pavimentosRes) {
        final pisoId = p['id'] as String;
        final ambientesRes = await Supabase.instance.client
            .from('obra_ambiente')
            .select('nome')
            .eq('obra_piso_id', pisoId)
            .order('ordem');

        final ambientes = (ambientesRes as List)
            .map((a) => a['nome'] as String)
            .toList();

        pisos.add(PisoTemp(
          id: pisoId,
          nome: p['nome'] ?? 'Pavimento',
          ambientes: ambientes,
        ));
      }
      notifyListeners();
      debugPrint("✅ Estrutura carregada: ${pisos.length} pavimentos");
    } catch (e) {
      debugPrint("❌ Erro ao carregar estrutura: $e");
    }
  }

  // ==================== FASES ====================
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

  // ==================== PISOS E AMBIENTES ====================
  void adicionarPiso(String nome) {
    if (nome.trim().isEmpty) return;

    final nomeLimpo = nome.trim();

    // Evita duplicados na lista local
    if (pisos.any((p) => p.nome.toLowerCase() == nomeLimpo.toLowerCase())) return;

    pisos.add(PisoTemp(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // ID temporário
      nome: nomeLimpo,
      ambientes: [],
    ));

    notifyListeners();
    debugPrint("➕ Piso temporário adicionado: $nomeLimpo");
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

  // ==================== SALVAMENTO ====================
  Future<bool> salvarObra(BuildContext context) async {
    if (nomeObra.trim().isEmpty) return false;

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
        'responsavel_nome': responsavelNome,
        'responsavel_contato': responsavelContato,
        'rua': rua,
        'numero': numero,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'complemento': complemento,
      };

      String obraId;

      if (obraIdParaEditar != null) {
        await Supabase.instance.client.from('obra').update(data).eq('id', obraIdParaEditar!);
        obraId = obraIdParaEditar!;
      } else {
        final response = await Supabase.instance.client.from('obra').insert(data).select().single();
        obraId = response['id'] as String;
      }

      // Salva fases e estrutura (agora com deleção prévia)
      if (_usaFases) {
        await _salvarFasesDaObra(obraId);
      }

      if (pisos.isNotEmpty) {
        await _salvarEstrutura(obraId);
      }

      if (context.mounted) {
        Provider.of<ObraProvider>(context, listen: false).loadObras();
      }

      limparDados();
      debugPrint("🎉 Obra salva com sucesso!");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar obra: $e");
      return false;
    }
  }

  // ==================== MÉTODOS AUXILIARES (CORRIGIDOS) ====================
  Future<void> _salvarFasesDaObra(String obraId) async {
    try {
      // Remove fases antigas
      await Supabase.instance.client.from('obra_fase').delete().eq('obra_id', obraId);

      if (fasesSelecionadasIds.isEmpty) return;

      final inserts = fasesSelecionadasIds.map((faseId) => {
        'obra_id': obraId,
        'fase_id': faseId,
        'status': 'pendente',
      }).toList();

      await Supabase.instance.client.from('obra_fase').insert(inserts);
      debugPrint("✅ ${fasesSelecionadasIds.length} fases vinculadas");
    } catch (e) {
      debugPrint("❌ Erro ao salvar fases: $e");
    }
  }

  Future<void> _salvarEstrutura(String obraId) async {
    if (pisos.isEmpty) return;

    try {
      // Remove estrutura antiga
      await Supabase.instance.client.from('pavimento').delete().eq('obra_id_original', obraId);
      await Supabase.instance.client.from('obra_ambiente').delete().eq('obra_id', obraId);

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
          await Supabase.instance.client.from('obra_ambiente').insert({
            'obra_id': obraId,
            'obra_piso_id': pisoId,
            'nome': pisoTemp.ambientes[j],
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

    responsavelNome = null;
    responsavelContato = null;
    rua = null;
    numero = null;
    bairro = null;
    cidade = null;
    estado = null;
    complemento = null;

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