// lib/features/chamado/screens/chamado_list_tecnico_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/chamado_provider.dart';
import '../models/chamado.dart';
import '../../rh/providers/employee_provider.dart';
import 'chamado_execucao_screen.dart'; // vamos criar no próximo lote

class ChamadoListTecnicoScreen extends StatefulWidget {
  const ChamadoListTecnicoScreen({super.key});

  @override
  State<ChamadoListTecnicoScreen> createState() => _ChamadoListTecnicoScreenState();
}

class _ChamadoListTecnicoScreenState extends State<ChamadoListTecnicoScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarChamados();
    });
  }

  Future<void> _carregarChamados() async {
    final employeeProvider = context.read<EmployeeProvider>();
    final tecnicoId = employeeProvider.currentEmployee?.id;
    if (tecnicoId != null) {
      await context.read<ChamadoProvider>().carregarChamadosDoTecnico(tecnicoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chamadoProvider = context.watch<ChamadoProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final tecnicoNome = employeeProvider.currentEmployee?.name?.split(' ').first ?? 'Técnico';

    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Chamados - $tecnicoNome'),
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarChamados),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarChamados,
        child: chamadoProvider.chamados.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhum chamado agendado', style: TextStyle(fontSize: 18)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: chamadoProvider.chamados.length,
          itemBuilder: (context, index) {
            final chamado = chamadoProvider.chamados[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(chamado.status),
                  child: const Icon(Icons.assignment, color: Colors.white),
                ),
                title: Text("Chamado ${chamado.id.substring(0, 8)}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Data: ${_dateFormat.format(chamado.dataAgendada)}"),
                    Text("Status: ${chamado.status.toUpperCase()}"),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChamadoExecucaoScreen(chamado: chamado),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'concluido': return Colors.green;
      case 'em_andamento': return Colors.orange;
      case 'cancelado': return Colors.red;
      default: return Colors.blue;
    }
  }
}