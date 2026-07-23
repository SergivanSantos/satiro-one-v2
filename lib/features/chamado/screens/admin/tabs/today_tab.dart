// lib/features/chamado/screens/admin/tabs/today_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../../../obra/models/obra.dart';
import '../../../../obra/providers/obra_provider.dart';
import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../models/chamado.dart';
import '../../../providers/chamado_provider.dart';
import '../../../../servicos/providers/servico_provider.dart';
import '../widgets/chamado_card.dart';
import '../widgets/servico_popup.dart';

class TodayTab extends StatefulWidget {
  final VoidCallback onRefresh;
  final String? filialId;

  const TodayTab({
    super.key,
    required this.onRefresh,
    this.filialId,
  });

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Atualização automática suave após 700ms
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _loadTodayData(showLoading: false);
      });
    });
  }

  Future<void> _loadTodayData({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) setState(() => _isLoading = true);

    try {
      final chamadoProvider = context.read<ChamadoProvider>();
      final servicoProvider = context.read<ServicoProvider>();
      final obraProvider = context.read<ObraProvider>();

      await chamadoProvider.carregarTodosChamados();

      final hojeStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var chamadosHoje = chamadoProvider.chamados.where((c) =>
      DateFormat('yyyy-MM-dd').format(c.dataAgendada) == hojeStr).toList();

      if (widget.filialId != null) {
        chamadosHoje = chamadosHoje.where((c) {
          final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
          return obra?.filialId == widget.filialId;
        }).toList();
      }

      final Set<String> obrasIds = chamadosHoje.map((c) => c.obraId)
          .where((id) => id.isNotEmpty)
          .toSet();

      for (var obraId in obrasIds) {
        await servicoProvider.carregarServicosDaObra(obraId, null);
      }
    } catch (e) {
      debugPrint("❌ Erro ao carregar dados de hoje: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _atualizarManual() async {
    await _loadTodayData();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {   // ← Corrigido aqui
    final chamadoProvider = context.watch<ChamadoProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final obraProvider = context.watch<ObraProvider>();

    final hojeStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var chamadosHoje = chamadoProvider.chamados.where((c) =>
    DateFormat('yyyy-MM-dd').format(c.dataAgendada) == hojeStr).toList();

    if (widget.filialId != null) {
      chamadosHoje = chamadosHoje.where((c) {
        final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
        return obra?.filialId == widget.filialId;
      }).toList();
    }

    int totalConcluido = 0, totalPendente = 0, totalNaoIniciado = 0;

    for (var chamado in chamadosHoje) {
      final servicosDaObra = servicoProvider.getServicosDaObra(chamado.obraId);
      final servicosDoChamado = servicosDaObra.where((s) {
        final servicoId = s['servico_id']?.toString() ?? '';
        return chamado.servicosIds.contains(servicoId);
      }).toList();

      for (var s in servicosDoChamado) {
        final statusRaw = (s['status'] ?? 'nao_iniciado').toString().toLowerCase().trim();
        if (statusRaw.contains('conclu')) totalConcluido++;
        else if (statusRaw.contains('pendente')) totalPendente++;
        else totalNaoIniciado++;
      }
    }

    return RefreshIndicator(
      onRefresh: _atualizarManual,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Chamados de Hoje",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  _buildMiniCounter("Total", chamadosHoje.length, Colors.blue),
                  const SizedBox(width: 6),
                  _buildMiniCounter("Concluídos", totalConcluido, Colors.green),
                  const SizedBox(width: 6),
                  _buildMiniCounter("Pendentes", totalPendente, Colors.orange),
                  const SizedBox(width: 6),
                  _buildMiniCounter("Não Iniciados", totalNaoIniciado, Colors.blueGrey),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: _atualizarManual,
                icon: const Icon(Icons.refresh, size: 26),
                tooltip: "Atualizar",
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (chamadosHoje.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Text(
                  "Nenhum chamado agendado para hoje",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ...chamadosHoje.map((chamado) {
              final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
              return InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => ServicoPopup(chamado: chamado, obra: obra),
                ),
                borderRadius: BorderRadius.circular(12),
                child: ChamadoCard(
                  chamado: chamado,
                  onRefresh: widget.onRefresh,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniCounter(String label, int count, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center,
          ),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}