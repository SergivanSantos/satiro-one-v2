// lib/features/material/providers/material_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/material.dart';
import '../models/marca.dart';
import '../models/modelo.dart';
import '../../obra/models/obra_material.dart'; // ajuste o caminho se necessário
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
    if (isLoading) return;

    isLoading = true;
    // NÃO notifica aqui → evita o erro "setState during build"

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
      notifyListeners(); // só notifica uma vez no final
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
      final data = material.toMap();

      if (material.id.isEmpty) {
        await supabase.from('material').insert(data).select().single();
      } else {
        await supabase.from('material').update(data).eq('id', material.id);
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
      // Remove campos que não existem na tabela
      data.remove('materialNome');
      data.remove('unidade');

      await supabase.from('obra_material').insert(data);
      debugPrint("✅ Material adicionado na obra com sucesso");
      return true;
    } catch (e, stack) {
      debugPrint("Erro ao adicionar material na obra: $e");
      debugPrint("Stack: $stack");
      return false;
    }
  }

  // Método antigo (mantido por compatibilidade)
  Future<bool> atualizarStatusMaterial(String id, String novoStatus, {List<String>? fotos}) async {
    try {
      final data = {
        'status': novoStatus,
        if (fotos != null) 'fotos': fotos,
        if (novoStatus == 'entregue') 'data_entrega': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('obra_material').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar status: $e");
      return false;
    }
  }

  // =====================================================
// CONTROLE DE MATERIAIS (Compras / Estoque)
// =====================================================
  // =====================================================
// CONTROLE DE MATERIAIS (Compras / Estoque)
// =====================================================
  Future<List<Map<String, dynamic>>> carregarMateriaisParaControle({
    bool somenteFaseAtual = true,
    List<String>? statusFiltro,
  }) async {
    try {
      // 1. Busca obras ativas
      final resObras = await supabase
          .from('obra')
          .select('id, nome, cliente_id, fase_atual_id, fase_atual:fase_atual_id(nome), status')
          .eq('status', 'em_andamento')
          .not('fase_atual_id', 'is', null);

      if (resObras.isEmpty) return [];

      // 2. Busca nomes dos clientes (tabela correta: clientes)
      final clienteIds = resObras
          .map((o) => o['cliente_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, String> clientesMap = {};
      if (clienteIds.isNotEmpty) {
        final resClientes = await supabase
            .from('clientes')
            .select('id, nome')
            .inFilter('id', clienteIds);

        clientesMap = {
          for (var c in resClientes)
            c['id'] as String: c['nome'] as String? ?? 'Sem nome'
        };
      }

      final obrasMap = {
        for (var o in resObras)
          o['id'] as String: {
            'nome': o['nome'],
            'fase_atual_id': o['fase_atual_id'],
            'fase_atual_nome': o['fase_atual']?['nome'],
            'cliente_id': o['cliente_id'],
            'cliente_nome': clientesMap[o['cliente_id']] ?? 'Cliente não informado',
          }
      };

      final obrasIds = obrasMap.keys.toList();

      // 3. Query dos materiais
      var queryBuilder = supabase
          .from('obra_material')
          .select('''
          *,
          material:material_id (
            id, nome, unidade, codigo, fases_uso_ids,
            marca:marca_id (id, nome),
            modelo:modelo_id (id, nome)
          )
        ''')
          .inFilter('obra_id', obrasIds);

      if (statusFiltro != null && statusFiltro.isNotEmpty) {
        queryBuilder = queryBuilder.inFilter('status', statusFiltro);
      } else {
        queryBuilder = queryBuilder.not('status', 'in', '("entregue","cancelado","devolvido")');
      }

      final resMateriais = await queryBuilder.order('created_at', ascending: false);

      // 4. Monta o resultado final
      final List<Map<String, dynamic>> resultado = [];

      for (final row in resMateriais) {
        final obraId = row['obra_id'] as String;
        final obraInfo = obrasMap[obraId];
        if (obraInfo == null) continue;

        final materialData = row['material'] as Map<String, dynamic>?;
        if (materialData == null) continue;

        final fasesUso = List<String>.from(materialData['fases_uso_ids'] ?? []);

        if (somenteFaseAtual) {
          final faseAtualId = obraInfo['fase_atual_id'] as String?;
          if (faseAtualId == null || !fasesUso.contains(faseAtualId)) {
            continue;
          }
        }

        final item = ObraMaterial.fromMap(row);

        resultado.add({
          'item': item,
          'obraId': obraId,
          'obraNome': obraInfo['nome'] ?? 'Obra sem nome',
          'faseNome': obraInfo['fase_atual_nome'],
          'clienteNome': obraInfo['cliente_nome'],
          'codigo': materialData['codigo']?.toString(),
          'marcaNome': materialData['marca']?['nome']?.toString(),
          'modeloNome': materialData['modelo']?['nome']?.toString(),
        });
      }

      return resultado;
    } catch (e, s) {
      debugPrint('Erro ao carregar materiais para controle: $e');
      debugPrint('$s');
      rethrow;
    }
  }

  /// Altera o status e grava no histórico
  Future<bool> atualizarStatusMaterialComHistorico({
    required ObraMaterial material,
    required String novoStatus,
    String? observacao,
    String? numeroNf,
    DateTime? dataCompra,
    DateTime? dataPrevisaoEntrega,
    String? fornecedor,
    double? valorUnitario,
    double? valorTotal,
    String? usuarioId,
  }) async {
    try {
      final statusAnterior = material.status;

      final dadosUpdate = <String, dynamic>{
        'status': novoStatus,
        'updated_at': DateTime.now().toIso8601String(),
        if (numeroNf != null) 'numero_nf': numeroNf,
        if (dataCompra != null) 'data_compra': dataCompra.toIso8601String(),
        if (dataPrevisaoEntrega != null) 'data_previsao_entrega': dataPrevisaoEntrega.toIso8601String(),
        if (fornecedor != null) 'fornecedor': fornecedor,
        if (valorUnitario != null) 'valor_unitario': valorUnitario,
        if (valorTotal != null) 'valor_total': valorTotal,
        if (observacao != null) 'observacao_compras': observacao,
        if (usuarioId != null) 'usuario_compras_id': usuarioId,
      };

      await supabase
          .from('obra_material')
          .update(dadosUpdate)
          .eq('id', material.id);

      // Histórico
      await supabase.from('obra_material_historico').insert({
        'obra_material_id': material.id,
        'status_anterior': statusAnterior,
        'status_novo': novoStatus,
        'usuario_id': usuarioId,
        'observacao': observacao,
        'dados_extras': {
          if (numeroNf != null) 'numero_nf': numeroNf,
          if (dataCompra != null) 'data_compra': dataCompra.toIso8601String(),
          if (dataPrevisaoEntrega != null) 'data_previsao_entrega': dataPrevisaoEntrega.toIso8601String(),
          if (fornecedor != null) 'fornecedor': fornecedor,
          if (valorUnitario != null) 'valor_unitario': valorUnitario,
          if (valorTotal != null) 'valor_total': valorTotal,
        },
      });

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar status do material: $e');
      return false;
    }
  }
}