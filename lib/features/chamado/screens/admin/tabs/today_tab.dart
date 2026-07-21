// lib/features/chamado/screens/admin/tabs/today_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../obra/providers/obra_provider.dart';
import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../providers/chamado_provider.dart';
import '../../../../servicos/providers/servico_provider.dart';
import '../widgets/chamado_card.dart';

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
  bool _servicosCarregados = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarServicosDosChamadosHoje());
  }

  // Só carrega serviços quando necessário (evita loop)
  Future<void> _carregarServicosDosChamadosHoje() async {
    if (!mounted || _servicosCarregados) return;

    setState(() => _servicosCarregados = true);

    final chamadoProvider = context.read<ChamadoProvider>();
    final servicoProvider = context.read<ServicoProvider>();
    final obraProvider = context.read<ObraProvider>();

    var chamadosHoje = chamadoProvider.chamados.where((c) =>
    DateFormat('yyyy-MM-dd').format(c.dataAgendada) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now())).toList();

    if (widget.filialId != null) {
      chamadosHoje = chamadosHoje.where((c) {
        final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
        return obra?.filialId == widget.filialId;
      }).toList();
    }

    // Carrega apenas uma vez por obra
    final Set<String> obrasProcessadas = {};
    for (var chamado in chamadosHoje) {
      if (chamado.obraId.isNotEmpty && !obrasProcessadas.contains(chamado.obraId)) {
        obrasProcessadas.add(chamado.obraId);
        await servicoProvider.carregarServicosDaObra(chamado.obraId, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chamadoProvider = context.watch<ChamadoProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final obraProvider = context.watch<ObraProvider>();

    // Recalcula chamados (reage ao realtime)
    var chamadosHoje = chamadoProvider.chamados.where((c) =>
    DateFormat('yyyy-MM-dd').format(c.dataAgendada) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now())).toList();

    if (widget.filialId != null) {
      chamadosHoje = chamadosHoje.where((c) {
        final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
        return obra?.filialId == widget.filialId;
      }).toList();
    }

    // ==================== CONTAGEM REAL POR CHAMADO ====================
    int totalConcluido = 0;
    int totalPendente = 0;
    int totalNaoIniciado = 0;

    for (var chamado in chamadosHoje) {
      final servicosDaObra = servicoProvider.getServicosDaObra(chamado.obraId);

      final servicosDoChamado = servicosDaObra.where((s) {
        final servicoId = s['servico_id']?.toString() ?? '';
        return chamado.servicosIds.contains(servicoId);
      }).toList();

      for (var s in servicosDoChamado) {
        final status = (s['status'] ?? 'nao_iniciado').toString().toLowerCase().trim();

        if (status == 'concluido' || status == 'concluído') {
          totalConcluido++;
        } else if (status.contains('pendente')) {
          totalPendente++;
        } else {
          totalNaoIniciado++;
        }
      }
    }

    if (chamadosHoje.isEmpty) {
      return const Center(child: Text("Nenhum chamado para hoje"));
    }

    return Column(
      children: [
        // Contadores
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCounterCard(Icons.today, "Chamados de Hoje", chamadosHoje.length, Colors.blue),
              _buildCounterCard(Icons.check_circle, "Concluídos", totalConcluido, Colors.green),
              _buildCounterCard(Icons.access_time, "Pendentes", totalPendente, Colors.orange),
              _buildCounterCard(Icons.hourglass_empty, "Não Iniciados", totalNaoIniciado, Colors.blueGrey),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chamadosHoje.length,
            itemBuilder: (context, index) {
              return ChamadoCard(
                chamado: chamadosHoje[index],
                onRefresh: widget.onRefresh,
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Excluir chamado?"),
                      content: const Text("Esta ação não pode ser desfeita."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await context.read<ChamadoProvider>().excluirChamado(chamadosHoje[index].id);
                    widget.onRefresh();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCounterCard(IconData icon, String label, int count, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}