// lib/features/chamado/providers/chamado_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../models/chamado.dart';

class ChamadoProvider extends ChangeNotifier {
  List<Chamado> chamados = [];
  bool isLoading = false;

  final supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;

  // ==================== TÉCNICO ====================
  Future<void> carregarChamadosDoTecnico(int tecnicoId, {DateTime? data}) async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint("🔄 Carregando chamados do técnico ID: $tecnicoId | Data: ${data != null ? DateFormat('yyyy-MM-dd').format(data) : 'Todas'}");

      final res = await supabase
          .from('chamado')
          .select('*, obra:obra_id(nome), tecnico:tecnico_id(name)')
          .eq('tecnico_id', tecnicoId)
          .order('data_agendada', ascending: true);

      List<dynamic> lista = res;

      if (data != null) {
        final dataStr = DateFormat('yyyy-MM-dd').format(data);
        lista = lista.where((item) {
          final itemDate = item['data_agendada']?.toString().split('T')[0];
          return itemDate == dataStr;
        }).toList();
      }

      chamados = lista.map<Chamado>((c) => Chamado.fromMap(c)).toList();
      debugPrint("✅ ${chamados.length} chamados carregados para o técnico $tecnicoId");
    } catch (e) {
      debugPrint("❌ Erro ao carregar chamados do técnico: $e");
      chamados = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==================== REALTIME PARA TÉCNICO ====================
  void setupRealtimeParaTecnico(int tecnicoId, {required VoidCallback onNovoChamado}) {
    _realtimeSubscription?.cancel();

    debugPrint("📡 Configurando Realtime para técnico ID: $tecnicoId");

    _realtimeSubscription = supabase
        .from('chamado')
        .stream(primaryKey: ['id'])
        .eq('tecnico_id', tecnicoId)
        .order('created_at', ascending: false)
        .listen((data) {
      debugPrint("🔔 Realtime: Mudança detectada na tabela chamado! (${data.length} registros)");

      // Recarrega os chamados e notifica a tela
      carregarChamadosDoTecnico(tecnicoId, data: DateTime.now()).then((_) {
        onNovoChamado();
      });
    });

    debugPrint("✅ Realtime configurado com sucesso para técnico $tecnicoId");
  }

  void disposeRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    debugPrint("🛑 Realtime do ChamadoProvider finalizado");
  }

  // ==================== ADMIN ====================
  Future<void> carregarTodosChamados() async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await supabase
          .from('chamado')
          .select('*, obra:obra_id(nome), tecnico:tecnico_id(name)')
          .order('data_agendada', ascending: true);

      chamados = (res as List<dynamic>).map<Chamado>((c) => Chamado.fromMap(c)).toList();
      debugPrint("✅ ${chamados.length} chamados totais carregados (Admin)");
    } catch (e) {
      debugPrint("❌ Erro ao carregar todos chamados: $e");
      chamados = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==================== MUTAÇÕES ====================
  Future<bool> criarChamado(Chamado chamado) async {
    try {
      debugPrint("📝 Criando novo chamado para técnico: ${chamado.tecnicoId}");
      await supabase.from('chamado').insert(chamado.toMap());
      debugPrint("✅ Chamado criado com sucesso!");
      await carregarTodosChamados();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao criar chamado: $e");
      return false;
    }
  }

  Future<bool> atualizarChamado(Chamado chamado) async {
    try {
      await supabase.from('chamado').update(chamado.toMap()).eq('id', chamado.id);
      await carregarTodosChamados();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar chamado: $e");
      return false;
    }
  }

  // ... (outros métodos de update/excluir mantidos iguais)

  Future<bool> atualizarStatusChamado(String chamadoId, String novoStatus) async {
    try {
      await supabase.from('chamado').update({'status': novoStatus}).eq('id', chamadoId);
      await carregarTodosChamados();
      debugPrint("✅ Status atualizado para $novoStatus");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status: $e");
      return false;
    }
  }

  Future<bool> atualizarTecnicoChamado(String chamadoId, int? novoTecnicoId) async {
    try {
      await supabase.from('chamado').update({'tecnico_id': novoTecnicoId}).eq('id', chamadoId);
      await carregarTodosChamados();
      debugPrint("✅ Técnico atualizado para ID: $novoTecnicoId");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar técnico: $e");
      return false;
    }
  }

  Future<bool> excluirChamado(String chamadoId) async {
    try {
      await supabase.from('chamado').delete().eq('id', chamadoId);
      await carregarTodosChamados();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao excluir: $e");
      return false;
    }
  }

  @override
  void dispose() {
    disposeRealtime();
    super.dispose();
  }
}