// lib/features/chamado/screens/admin/tabs/by_technician_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../rh/providers/employee_provider.dart';
import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../providers/chamado_provider.dart';
import '../../../../obra/providers/obra_provider.dart';

class ByTechnicianTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final String? filialId;   // ← Novo parâmetro

  const ByTechnicianTab({
    super.key,
    required this.onRefresh,
    this.filialId,
  });

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<EmployeeProvider>().employees;
    final chamados = context.watch<ChamadoProvider>().chamados;
    final obraProvider = context.watch<ObraProvider>();

    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final tecnico = employees[index];

        // Filtra chamados do técnico (com filtro de filial opcional)
        final chamadosDoTecnico = chamados.where((c) {
          if (c.tecnicoId != tecnico.id) return false;
          if (filialId == null) return true;

          final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
          return obra?.filialId == filialId;
        }).toList();

        final count = chamadosDoTecnico.length;

        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(tecnico.name),
          trailing: Chip(label: Text(count.toString())),
          onTap: () {
            // Futuro: abrir lista de chamados desse técnico
          },
        );
      },
    );
  }
}