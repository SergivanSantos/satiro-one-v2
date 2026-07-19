// lib/features/chamado/screens/admin/tabs/pendentes_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../providers/chamado_provider.dart';
import '../../../../obra/providers/obra_provider.dart';
import '../widgets/chamado_card.dart';

class PendentesTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final String? filialId;   // ← Novo parâmetro

  const PendentesTab({
    super.key,
    required this.onRefresh,
    this.filialId,
  });

  @override
  Widget build(BuildContext context) {
    final chamados = context.watch<ChamadoProvider>().chamados.where((c) {
      final pendente = c.status.toLowerCase() != 'concluido';
      if (!pendente) return false;
      if (filialId == null) return true;

      // Filtro por filial
      final obraProvider = context.watch<ObraProvider>();
      final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
      return obra?.filialId == filialId;
    }).toList();

    if (chamados.isEmpty) return const Center(child: Text("Nenhum chamado pendente"));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: chamados.length,
      itemBuilder: (context, index) {
        return ChamadoCard(chamado: chamados[index], onRefresh: onRefresh);
      },
    );
  }
}