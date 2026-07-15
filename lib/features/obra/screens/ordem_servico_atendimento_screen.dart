// lib/features/obra/screens/ordem_servico_atendimento_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../servicos/screens/obra_servico_form_screen.dart';
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

  List<Map<String, dynamic>> _servicosDaFase = [];
  bool _carregandoServicos = false;

  @override
  void initState() {
    super.initState();
    _servicosSelecionados = List.from(widget.ordem.servicosIds);
    _responsaveisSelecionados = List.from(widget.ordem.responsaveisIds.map((e) => e.toString()));
    _status = widget.ordem.status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarServicosDaFase();
    });
  }

  Future<void> _carregarServicosDaFase() async {
    setState(() => _carregandoServicos = true);
    debugPrint("🔄 Carregando serviços da fase: ${widget.ordem.faseId} (Obra: ${widget.ordem.obraId})");

    try {
      final res = await Supabase.instance.client
          .from('obra_servico')
          .select('*, servico(*, categoria(nome))')
          .eq('obra_id', widget.ordem.obraId)
          .eq('fase_id', widget.ordem.faseId);

      _servicosDaFase = List.from(res);
      debugPrint("✅ ${_servicosDaFase.length} serviços carregados para esta fase");

      for (var item in _servicosDaFase) {
        final servicoId = item['servico_id']?.toString() ?? '';
        if (servicoId.isNotEmpty && !_servicosSelecionados.contains(servicoId)) {
          _servicosSelecionados.add(servicoId);
        }
      }
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços da fase: $e");
    } finally {
      if (mounted) setState(() => _carregandoServicos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final obraProvider = context.watch<ObraProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();

    // Correção do firstWhere com null safety
    final obra = obraProvider.obras.firstWhereOrNull(
          (o) => o.id == widget.ordem.obraId,
    );

    final tecnicos = employeeProvider.employees.where((e) =>
    e.role?.toLowerCase().contains('tecnico') ?? false).toList();

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
                    Text("Fase: ${widget.ordem.faseNome ?? widget.ordem.faseId}", style: const TextStyle(fontSize: 16)),
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

            const Text("Serviços", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildServicosSection(),

            const SizedBox(height: 20),

            const Text("Responsáveis (Técnicos)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildResponsaveisSection(tecnicos),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _salvarAtendimento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                ),
                child: const Text("SALVAR ATUALIZAÇÕES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicosSection() {
    if (_carregandoServicos) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_servicosDaFase.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text("Nenhum serviço encontrado para esta fase")),
        ),
      );
    }

    return Card(
      child: Column(
        children: _servicosDaFase.map((item) {
          final servico = item['servico'] as Map<String, dynamic>? ?? {};
          final servicoId = item['servico_id']?.toString() ?? '';
          final bool selecionado = _servicosSelecionados.contains(servicoId);

          return CheckboxListTile(
            title: Text(servico['nome'] ?? 'Serviço sem nome'),
            subtitle: Text(servico['categoria']?['nome'] ?? ''),
            value: selecionado,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _servicosSelecionados.add(servicoId);
                } else {
                  _servicosSelecionados.remove(servicoId);
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
          final tecnicoId = tecnico.id?.toString() ?? '';
          final bool selecionado = _responsaveisSelecionados.contains(tecnicoId);

          return CheckboxListTile(
            key: ValueKey('tecnico_$tecnicoId'), // ← Importante para evitar bug de estado
            title: Text(tecnico.name ?? 'Sem nome'),
            subtitle: Text(tecnico.cargo ?? ''),
            value: selecionado,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  if (! _responsaveisSelecionados.contains(tecnicoId)) {
                    _responsaveisSelecionados.add(tecnicoId);
                  }
                } else {
                  _responsaveisSelecionados.remove(tecnicoId);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _salvarAtendimento() async {
    final provider = context.read<OrdemServicoProvider>();

    final ordemAtualizada = OrdemServico(
      id: widget.ordem.id,
      obraId: widget.ordem.obraId,
      faseId: widget.ordem.faseId,
      titulo: widget.ordem.titulo,
      descricao: widget.ordem.descricao,
      status: _status,
      servicosIds: _servicosSelecionados,
      responsaveisIds: _responsaveisSelecionados,
    );

    debugPrint("💾 Salvando ordem - Responsáveis: ${_responsaveisSelecionados}");

    final success = await provider.atualizarOrdem(ordemAtualizada);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Ordem de Serviço atualizada com sucesso!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Erro ao salvar"), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'concluida': return Colors.green;
      case 'em_andamento': return Colors.orange;
      default: return Colors.blue;
    }
  }
}