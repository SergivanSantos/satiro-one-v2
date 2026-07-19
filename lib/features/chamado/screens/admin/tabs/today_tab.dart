// lib/features/chamado/screens/admin/tabs/today_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../obra/providers/obra_provider.dart';
import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../providers/chamado_provider.dart';
import '../../../../servicos/providers/servico_provider.dart';
import '../widgets/chamado_card.dart';

class TodayTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final String? filialId;

  const TodayTab({super.key, required this.onRefresh, this.filialId});

  @override
  Widget build(BuildContext context) {
    final chamadoProvider = context.watch<ChamadoProvider>();
    final servicoProvider = context.watch<ServicoProvider>();

    // Chamados do dia
    var chamadosHoje = chamadoProvider.chamados.where((c) =>
    DateFormat('yyyy-MM-dd').format(c.dataAgendada) == DateFormat('yyyy-MM-dd').format(DateTime.now())).toList();

    // Filtro por filial
    if (filialId != null) {
      final obraProvider = context.watch<ObraProvider>();
      chamadosHoje = chamadosHoje.where((c) {
        final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
        return obra?.filialId == filialId;
      }).toList();
    }

    // Contagem total de serviços (de todos os chamados de hoje)
    int totalConcluido = 0;
    int totalPendente = 0;
    int totalNaoIniciado = 0;

    for (var chamado in chamadosHoje) {
      final servicosObra = servicoProvider.getServicosDaObra(chamado.obraId);
      for (var servicoId in chamado.servicosIds) {
        final servicoObra = servicosObra.firstWhereOrNull(
              (s) => s['servico_id']?.toString() == servicoId.toString(),
        );
        final status = (servicoObra?['status'] ?? 'nao_iniciado').toString().toLowerCase();

        if (status == 'concluido') totalConcluido++;
        else if (status == 'pendente') totalPendente++;
        else totalNaoIniciado++;
      }
    }

    if (chamadosHoje.isEmpty) {
      return const Center(child: Text("Nenhum chamado para hoje"));
    }

    return Column(
      children: [
        // Contadores no topo da aba Hoje
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCounter("Chamados", chamadosHoje.length, Colors.blue),
              _buildCounter("Concluídos", totalConcluido, Colors.green),
              _buildCounter("Pendentes", totalPendente, Colors.orange),
              _buildCounter("Não Iniciados", totalNaoIniciado, Colors.blueGrey),
            ],
          ),
        ),

        // Lista de chamados
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chamadosHoje.length,
            itemBuilder: (context, index) {
              return ChamadoCard(
                chamado: chamadosHoje[index],
                onRefresh: onRefresh,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}