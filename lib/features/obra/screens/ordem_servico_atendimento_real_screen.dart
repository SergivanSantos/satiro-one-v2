// lib/features/obra/screens/ordem_servico_atendimento_real_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/ordem_atendimento_provider.dart';
import '../providers/ordem_servico_provider.dart';
import '../models/ordem_servico.dart';
import '../../rh/providers/employee_provider.dart';
import '../../servicos/providers/servico_provider.dart';

class OrdemServicoAtendimentoRealScreen extends StatefulWidget {
  final OrdemServico ordem;

  const OrdemServicoAtendimentoRealScreen({super.key, required this.ordem});

  @override
  State<OrdemServicoAtendimentoRealScreen> createState() => _OrdemServicoAtendimentoRealScreenState();
}

class _OrdemServicoAtendimentoRealScreenState extends State<OrdemServicoAtendimentoRealScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdemAtendimentoProvider>().carregarAtendimentosDaOrdem(widget.ordem.id);
      context.read<ServicoProvider>().carregarServicosDaFase(widget.ordem.obraId, widget.ordem.faseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final atendimentoProvider = context.watch<OrdemAtendimentoProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();

    final tecnicoId = employeeProvider.currentEmployee?.id;
    final servicos = servicoProvider.servicosDaFase;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ordem.titulo),
        backgroundColor: Colors.orange[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info da Obra
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Obra: ${widget.ordem.obraNome ?? '—'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Fase: ${widget.ordem.faseNome ?? '—'}"),
                  Text("Status OS: ${widget.ordem.status.toUpperCase()}"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Check-in
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text("CHECK-IN - Iniciar Atendimento"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 56),
            ),
            onPressed: tecnicoId == null ? null : () async {
              final success = await context.read<OrdemAtendimentoProvider>().registrarCheckin(
                ordemServicoId: widget.ordem.id,
                servicoId: null,
                tecnicoId: tecnicoId,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Check-in realizado!"), backgroundColor: Colors.green),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          const Text("Serviços a Executar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (servicos.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text("Nenhum serviço encontrado"))))
          else
            ...servicos.map((item) {
              final servico = item['servico'] as Map<String, dynamic>? ?? {};
              return Card(
                child: ListTile(
                  title: Text(servico['nome'] ?? 'Serviço'),
                  subtitle: Text(servico['categoria']?['nome'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _concluirServico(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.warning_amber, color: Colors.orange),
                        onPressed: () => _registrarPendencia(item),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          const Text("Histórico de Atendimentos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...atendimentoProvider.atendimentos.map((a) => ListTile(
            title: Text("Check-in: ${_dateFormat.format(a.dataCheckin!)}"),
            subtitle: Text(a.solucao ?? a.pendencias ?? a.observacoes ?? 'Sem observação'),
            trailing: Text(a.status.toUpperCase()),
          )),
        ],
      ),
    );
  }

  void _concluirServico(dynamic item) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Serviço marcado como concluído")));
    // Implementar salvamento real depois
  }

  void _registrarPendencia(dynamic item) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pendência registrada")));
  }
}