// lib/features/chamado/screens/chamado_list_tecnico_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../servicos/screens/obra_servico_form_screen.dart';
import '../providers/chamado_provider.dart';
import '../models/chamado.dart';
import '../../rh/providers/employee_provider.dart';
import '../../obra/providers/obra_provider.dart';
import '../../client/providers/cliente_provider.dart';
import '../../servicos/providers/servico_provider.dart';
import 'chamado_execucao_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarChamados());
  }

  Future<void> _carregarChamados() async {
    final employeeProvider = context.read<EmployeeProvider>();
    final chamadoProvider = context.read<ChamadoProvider>();
    final obraProvider = context.read<ObraProvider>();
    final clienteProvider = context.read<ClienteProvider>();
    final servicoProvider = context.read<ServicoProvider>();

    final tecnicoId = employeeProvider.currentEmployee?.id;

    if (tecnicoId != null) {
      await chamadoProvider.carregarChamadosDoTecnico(tecnicoId);
    }

    await obraProvider.loadObras();
    await clienteProvider.carregarClientes();

    // Pré-carrega serviços de todas as obras
    final obrasIds = chamadoProvider.chamados.map((c) => c.obraId).toSet();
    for (var obraId in obrasIds) {
      if (obraId.isNotEmpty) {
        await servicoProvider.carregarServicosDaObra(obraId);
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chamadoProvider = context.watch<ChamadoProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final obraProvider = context.watch<ObraProvider>();
    final clienteProvider = context.watch<ClienteProvider>();
    final servicoProvider = context.watch<ServicoProvider>();

    final tecnicoNome = employeeProvider.currentEmployee?.name?.split(' ').first ?? 'Técnico';
    final chamados = chamadoProvider.chamados;

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
        child: chamados.isEmpty
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
          itemCount: chamados.length,
          itemBuilder: (context, index) {
            final chamado = chamados[index];
            final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
            final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);

            final clienteNome = cliente?.nome ?? chamado.clienteNome ?? '—';

            // Contagem real de serviços
            int qtdConcluido = 0;
            int qtdPendente = 0;
            int qtdSemAtendimento = 0;

            final servicosObra = servicoProvider.getServicosDaObra(chamado.obraId);

            for (var servicoId in chamado.servicosIds) {
              final servicoObra = servicosObra.firstWhereOrNull(
                    (s) => s['servico_id']?.toString() == servicoId,
              );

              final status = (servicoObra?['status'] ?? 'nao_iniciado').toString().toLowerCase();

              if (status == 'concluido') qtdConcluido++;
              else if (status == 'pendente') qtdPendente++;
              else qtdSemAtendimento++;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.assignment, color: Colors.white),
                ),
                title: Text(
                  obra?.nome ?? chamado.obraNome ?? 'Obra sem nome',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Cliente: $clienteNome"),
                    Text("Data: ${_dateFormat.format(chamado.dataAgendada)}"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(Icons.check_circle, Colors.green, qtdConcluido),
                        const SizedBox(width: 8),
                        _buildStatusChip(Icons.warning_amber, Colors.orange, qtdPendente),
                        const SizedBox(width: 8),
                        _buildStatusChip(Icons.access_time, Colors.blueGrey, qtdSemAtendimento),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChamadoExecucaoScreen(chamado: chamado),
                    ),
                  ).then((_) => _carregarChamados());
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}