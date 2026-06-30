// lib/features/client/providers/cliente_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cliente.dart';
import '../../obra/models/obra.dart';

class ClienteProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Cliente> _clientes = [];
  List<Cliente> get clientes => _clientes;

  Future<void> carregarClientes() async {
    try {
      debugPrint("🔄 Carregando clientes com filiais...");

      final response = await _supabase
          .from('clientes')
          .select('*, cliente_filial(filial_id)');

      _clientes = (response as List).map((json) {
        try {
          final filiaisIds = (json['cliente_filial'] as List?)
              ?.map((v) => v['filial_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList() ?? [];

          json['filiais_ids'] = filiaisIds;

          final cliente = Cliente.fromJson(json);
          return cliente;
        } catch (e) {
          debugPrint("❌ Erro ao converter cliente: $e - JSON: $json");
          return null;
        }
      }).whereType<Cliente>().toList();

      debugPrint("✅ ${_clientes.length} clientes carregados com sucesso");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ ERRO GRAVE ao carregar clientes: $e");
    }
  }

  int getTotalObras(String? clienteId, List<Obra> todasObras) {
    if (clienteId == null) return 0;
    try {
      return todasObras.where((obra) => obra.clienteId == clienteId).length;
    } catch (e) {
      debugPrint("⚠️ Erro em getTotalObras: $e");
      return 0;
    }
  }

  int getObrasEmAndamento(String? clienteId, List<Obra> todasObras) {
    if (clienteId == null) return 0;
    try {
      return todasObras.where((obra) =>
      obra.clienteId == clienteId &&
          obra.status.toLowerCase().contains('andamento')).length;
    } catch (e) {
      return 0;
    }
  }

  int getObrasConcluidas(String? clienteId, List<Obra> todasObras) {
    if (clienteId == null) return 0;
    try {
      return todasObras.where((obra) =>
      obra.clienteId == clienteId &&
          (obra.status.toLowerCase().contains('conclu') ||
              obra.status.toLowerCase().contains('finaliz'))).length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> salvarCliente(Cliente cliente, List<String> filiaisIds) async {
    try {
      debugPrint("🔄 Salvando cliente: ${cliente.nome}");
      await _supabase.from('clientes').upsert(cliente.toJson());

      if (filiaisIds.isNotEmpty) {
        await _supabase.from('cliente_filial').delete().eq('cliente_id', cliente.id);
        final vinculos = filiaisIds.map((filialId) => {
          'cliente_id': cliente.id,
          'filial_id': filialId,
        }).toList();
        await _supabase.from('cliente_filial').insert(vinculos);
      }

      await carregarClientes();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao salvar cliente: $e");
      return false;
    }
  }
}