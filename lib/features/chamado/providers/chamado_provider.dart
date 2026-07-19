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
  int? _tecnicoIdAtual;
  bool _realtimeAtivo = false;

  DateTime? _ultimaDataCarregada;

  // ==================== TÉCNICO ====================
  Future<void> carregarChamadosDoTecnico(int tecnicoId, {DateTime? data}) async {
    isLoading = true;
    notifyListeners();

    final dataParaCarregar = data ?? DateTime.now();
    _ultimaDataCarregada = dataParaCarregar;

    try {
      debugPrint("🔄 Carregando chamados do técnico ID: $tecnicoId | Data: ${DateFormat('yyyy-MM-dd').format(dataParaCarregar)}");

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
      debugPrint("✅ ${chamados.length} chamados carregados para o técnico");
    } catch (e) {
      debugPrint("❌ Erro ao carregar chamados: $e");
      chamados = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==================== REALTIME ====================
  void setupRealtimeParaTecnico(int tecnicoId, {required VoidCallback onNovoChamado}) {
    if (_realtimeAtivo && _tecnicoIdAtual == tecnicoId) {
      debugPrint("📡 [REALTIME] Já ativo para técnico $tecnicoId");
      return;
    }

    _cancelarRealtime();

    _tecnicoIdAtual = tecnicoId;
    _realtimeAtivo = true;

    debugPrint("📡 [REALTIME] Iniciando subscription para técnico ID: $tecnicoId");

    _realtimeSubscription = supabase
        .from('chamado')
        .stream(primaryKey: ['id'])
        .eq('tecnico_id', tecnicoId)
        .listen(
          (payload) async {
        debugPrint("🔔 [REALTIME] Mudança detectada! (${payload.length} registros) - Recarregando lista...");
        try {
          if (_ultimaDataCarregada != null) {
            await carregarChamadosDoTecnico(tecnicoId, data: _ultimaDataCarregada);
          } else {
            await carregarChamadosDoTecnico(tecnicoId);
          }
          onNovoChamado();
        } catch (e) {
          debugPrint("❌ Erro no realtime callback: $e");
        }
      },
      onError: (error) {
        debugPrint("❌ Erro na subscription Realtime: $error");
        _realtimeAtivo = false;
      },
    );

    debugPrint("✅ [REALTIME] Subscription ATIVA");
  }

  void _cancelarRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _realtimeAtivo = false;
  }

  void disposeRealtime() {
    _cancelarRealtime();
    _tecnicoIdAtual = null;
  }

  bool jaTemSubscriptionAtiva(int tecnicoId) {
    return _realtimeAtivo && _tecnicoIdAtual == tecnicoId;
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
      debugPrint("✅ ${chamados.length} chamados totais carregados");
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
      await supabase.from('chamado').insert(chamado.toMap());
      debugPrint("✅ Chamado criado!");
      await carregarTodosChamados();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao criar chamado: $e");
      return false;
    }
  }

  Future<bool> atualizarChamado(Chamado chamado) async {
    try {
      await supabase.from('chamado').update(chamado.toMap()).eq('id', chamado.id!);
      debugPrint("✅ Chamado atualizado!");
      await carregarTodosChamados();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar chamado: $e");
      return false;
    }
  }

  Future<bool> atualizarStatusChamado(String chamadoId, String novoStatus) async {
    try {
      await supabase.from('chamado').update({'status': novoStatus}).eq('id', chamadoId);
      debugPrint("✅ Status atualizado!");
      await carregarTodosChamados();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar status: $e");
      return false;
    }
  }

  Future<bool> atualizarTecnicoChamado(String chamadoId, int? novoTecnicoId) async {
    try {
      await supabase.from('chamado').update({'tecnico_id': novoTecnicoId}).eq('id', chamadoId);
      debugPrint("✅ Técnico atualizado!");
      await carregarTodosChamados();
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao atualizar técnico: $e");
      return false;
    }
  }

  Future<bool> excluirChamado(String chamadoId) async {
    try {
      await supabase.from('chamado').delete().eq('id', chamadoId);
      debugPrint("🗑️ Chamado excluído com sucesso!");
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