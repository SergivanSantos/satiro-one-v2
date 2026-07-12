// lib/features/material/providers/material_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/material.dart';
import '../models/marca.dart';
import '../models/modelo.dart';
import '../../obra/models/obra_material.dart';
import '../../fase/models/fase.dart';

class MaterialProvider extends ChangeNotifier {
  List<MaterialItem> materiais = [];
  List<Marca> marcas = [];
  List<Modelo> modelos = [];
  List<Fase> todasFases = [];

  bool isLoading = false;

  final supabase = Supabase.instance.client;

  // ====================== CARREGAMENTO GERAL ======================
  Future<void> carregarTudo() async {
    if (isLoading) return; // evita chamadas simultâneas

    isLoading = true;
    notifyListeners(); // ← Notifica uma única vez no início

    try {
      await Future.wait([
        carregarMarcas(silent: true),
        carregarModelos(silent: true),
        carregarFases(silent: true),
        carregarMateriais(silent: true),
      ]);
    } catch (e) {
      debugPrint("Erro ao carregar tudo: $e");
    } finally {
      isLoading = false;
      notifyListeners(); // ← Notifica uma única vez no final
    }
  }

  // ====================== MARCAS ======================
  Future<void> carregarMarcas({bool silent = false}) async {
    try {
      final res = await supabase
          .from('marca')
          .select()
          .eq('ativo', true)
          .order('nome');

      marcas = res.map<Marca>((m) => Marca.fromMap(m)).toList();

      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint("Erro ao carregar marcas: $e");
    }
  }

  Future<bool> salvarMarca(Marca marca) async {
    try {
      await supabase.from('marca').insert(marca.toMap());
      await carregarMarcas();
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar marca: $e");
      return false;
    }
  }

  Future<bool> atualizarMarca(Marca marca) async {
    try {
      await supabase.from('marca').update(marca.toMap()).eq('id', marca.id);
      await carregarMarcas();
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar marca: $e");
      return false;
    }
  }

  // ====================== MODELOS ======================
  Future<void> carregarModelos({bool silent = false}) async {
    try {
      final res = await supabase
          .from('modelo')
          .select()
          .eq('ativo', true)
          .order('nome');

      modelos = res.map<Modelo>((m) => Modelo.fromMap(m)).toList();

      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint("Erro ao carregar modelos: $e");
    }
  }

  Future<bool> salvarModelo(Modelo modelo) async {
    try {
      await supabase.from('modelo').insert(modelo.toMap());
      await carregarModelos();
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar modelo: $e");
      return false;
    }
  }

  Future<bool> atualizarModelo(Modelo modelo) async {
    try {
      await supabase.from('modelo').update(modelo.toMap()).eq('id', modelo.id);
      await carregarModelos();
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar modelo: $e");
      return false;
    }
  }

  List<Modelo> getModelosByMarca(String? marcaId) {
    if (marcaId == null) return [];
    return modelos.where((m) => m.marcaId == marcaId).toList();
  }

  // ====================== FASES ======================
  Future<void> carregarFases({bool silent = false}) async {
    try {
      final res = await supabase
          .from('fase')
          .select()
          .eq('ativo', true)
          .order('ordem', ascending: true);

      todasFases = res.map<Fase>((f) => Fase.fromMap(f)).toList();

      if (!silent) notifyListeners();
      debugPrint("✅ ${todasFases.length} fases carregadas");
    } catch (e) {
      debugPrint("Erro ao carregar fases: $e");
    }
  }

  // ====================== MATERIAIS ======================
  Future<void> carregarMateriais({bool silent = false}) async {
    try {
      final res = await supabase
          .from('material')
          .select('*, marca(*), modelo(*)')
          .eq('ativo', true)
          .order('nome');

      materiais = res.map<MaterialItem>((m) => MaterialItem.fromMap(m)).toList();

      if (!silent) notifyListeners();
      debugPrint("✅ ${materiais.length} materiais carregados");
    } catch (e) {
      debugPrint("Erro ao carregar materiais: $e");
    }
  }

  Future<bool> salvarMaterial(MaterialItem material) async {
    try {
      debugPrint("🔄 Salvando material: ${material.nome}");
      final data = material.toMap();
      debugPrint("📤 Dados enviados: $data");

      if (material.id.isEmpty || material.id == '') {
        final response = await supabase
            .from('material')
            .insert(data)
            .select()
            .single();

        debugPrint("✅ Material INSERIDO! ID: ${response['id']}");
      } else {
        await supabase
            .from('material')
            .update(data)
            .eq('id', material.id);
        debugPrint("✅ Material atualizado");
      }

      await carregarMateriais();
      return true;
    } catch (e, stack) {
      debugPrint("❌ ERRO ao salvar material: $e");
      debugPrint("Stack: $stack");
      return false;
    }
  }

  // ====================== MATERIAIS POR OBRA ======================
  Future<List<ObraMaterial>> carregarMateriaisDaObra(String obraId) async {
    try {
      final res = await supabase
          .from('obra_material')
          .select('*, material(*)')
          .eq('obra_id', obraId)
          .order('created_at');

      return res.map<ObraMaterial>((m) => ObraMaterial.fromMap(m)).toList();
    } catch (e) {
      debugPrint("Erro ao carregar materiais da obra: $e");
      return [];
    }
  }

  Future<bool> adicionarMaterialNaObra(ObraMaterial item) async {
    try {
      final data = item.toMap();

      // Remova campos que não existem na tabela se necessário
      data.remove('fase_id'); // se estiver enviando e a coluna não existir

      await supabase.from('obra_material').insert(data);
      debugPrint("✅ Material adicionado na obra com sucesso");
      return true;
    } catch (e, stack) {
      debugPrint("Erro ao adicionar material na obra: $e");
      debugPrint("Stack: $stack");
      return false;
    }
  }

  Future<bool> atualizarStatusMaterial(String id, String novoStatus, {String? fotoUrl}) async {
    try {
      final data = {
        'status': novoStatus,
        if (fotoUrl != null) 'foto_url': fotoUrl,
        if (novoStatus == 'entregue') 'data_entrega': DateTime.now().toIso8601String(),
      };

      await supabase.from('obra_material').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar status: $e");
      return false;
    }
  }
}