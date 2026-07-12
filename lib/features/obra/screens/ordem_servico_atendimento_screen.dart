// lib/features/obra/screens/ordem_servico_atendimento_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ordem_servico_provider.dart';
import '../models/ordem_servico.dart';
import '../../servicos/providers/servico_provider.dart';
import '../../rh/providers/employee_provider.dart';
import '../providers/obra_provider.dart';

class OrdemServicoAtendimentoScreen extends StatefulWidget {
  final OrdemServico ordem;

  const OrdemServicoAtendimentoScreen({super.key, required this.ordem});

  @override
  State<OrdemServicoAtendimentoScreen> createState() => _OrdemServicoAtendimentoScreenState();
}

class _OrdemServicoAtendimentoScreenState extends State<OrdemServicoAtendimentoScreen> {
  late List<String> _servicosSelecionados;
  late List<String> _responsaveisSelecionados;
  late String _status;

  @override
  @override
  void initState() {
    super.initState();
    _servicosSelecionados = List.from(widget.ordem.servicosIds);
    _responsaveisSelecionados = List.from(widget.ordem.responsaveisIds);
    _status = widget.ordem.status;

    // Carregar serviços da fase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarServicosDaFase();
    });
  }

  Future<void> _carregarServicosDaFase() async {
    debugPrint("🔄 Carregando serviços da fase: ${widget.ordem.faseId}");
    // Implementar lógica para carregar serviços da fase
  }

  @override
  Widget build(BuildContext context) {
    final obraProvider = context.watch<ObraProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();

    final obra = obraProvider.obras.firstWhere(
          (o) => o.id == widget.ordem.obraId,
      orElse: () => null as dynamic,   // ← Correção
    );

    final tecnicos = employeeProvider.employees.where((e) =>
    e.role?.toLowerCase().contains('tecnico') ?? false
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ordem.titulo),
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Obra: ${obra?.nome ?? '—'}", style: const TextStyle(fontSize: 16)),
                    Text("Fase ID: ${widget.ordem.faseId}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Status: "),
                        Chip(
                          label: Text(_status.toUpperCase()),
                          backgroundColor: _getStatusColor(_status).withOpacity(0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Serviços da Obra (vinculados à fase ou obra)
            const Text("Serviços", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildServicosSection(),

            const SizedBox(height: 20),

            // Responsáveis
            const Text("Responsáveis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildResponsaveisSection(tecnicos),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _salvarAtendimento,
                child: const Text("SALVAR ATUALIZAÇÕES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicosSection() {
    // Aqui você pode filtrar serviços da obra pela fase se quiser
    return Card(
      child: Column(
        children: context.watch<ServicoProvider>().servicos.map((servico) {
          final bool selecionado = _servicosSelecionados.contains(servico.id);
          return CheckboxListTile(
            title: Text(servico.nome),
            subtitle: Text(servico.categoria ?? ''),
            value: selecionado,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _servicosSelecionados.add(servico.id);
                } else {
                  _servicosSelecionados.remove(servico.id);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResponsaveisSection(List<dynamic> tecnicos) {
    return Card(
      child: Column(
        children: tecnicos.map((tecnico) {
          final bool selecionado = _responsaveisSelecionados.contains(tecnico.id.toString());
          return CheckboxListTile(
            title: Text(tecnico.name ?? 'Sem nome'),
            subtitle: Text(tecnico.cargo ?? ''),
            value: selecionado,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _responsaveisSelecionados.add(tecnico.id.toString());
                } else {
                  _responsaveisSelecionados.remove(tecnico.id.toString());
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _salvarAtendimento() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Ordem de Serviço atualizada!")),
    );
    Navigator.pop(context, true);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'concluida': return Colors.green;
      case 'em_andamento': return Colors.orange;
      default: return Colors.blue;
    }
  }
}