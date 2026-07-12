// lib/features/obra/screens/ordem_servico_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ordem_servico_provider.dart';
import '../providers/obra_provider.dart';
import '../models/ordem_servico.dart';
import '../models/obra.dart';
import 'ordem_servico_form_screen.dart';
import 'ordem_servico_atendimento_screen.dart';

class OrdemServicoListScreen extends StatefulWidget {
  final String obraId;
  final String obraNome;

  const OrdemServicoListScreen({
    super.key,
    required this.obraId,
    required this.obraNome,
  });

  @override
  State<OrdemServicoListScreen> createState() => _OrdemServicoListScreenState();
}

class _OrdemServicoListScreenState extends State<OrdemServicoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("🔄 Iniciando carregamento de ordens para obra: ${widget.obraId}");
      context.read<OrdemServicoProvider>().carregarOrdensDaObra(widget.obraId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdemServicoProvider>();
    final obraProvider = context.watch<ObraProvider>();

    debugPrint("📊 Construindo lista - Total de ordens: ${provider.ordens.length}");

    // Agrupar ordens por fase
    final Map<String, List<OrdemServico>> ordensPorFase = {};
    for (var ordem in provider.ordens) {
      final obra = obraProvider.obras.firstWhere(
            (o) => o.id == widget.obraId,
        orElse: () => null as Obra,
      );
      final faseNome = obra?.faseAtualNome ?? 'Fase Desconhecida';

      ordensPorFase.putIfAbsent(faseNome, () => []).add(ordem);
      debugPrint("   → Ordem '${ordem.titulo}' adicionada à fase '$faseNome' | Serviços: ${ordem.servicosIds.length}");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Ordens de Serviço - ${widget.obraNome}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: "Gerar Ordens de Serviço Automáticas",
            onPressed: () => _gerarOrdensAutomaticas(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.ordens.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("Nenhuma ordem de serviço cadastrada nesta obra."),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(12),
        children: ordensPorFase.entries.map((entry) {
          final faseNome = entry.key;
          final ordensDaFase = entry.value;

          debugPrint("📋 Renderizando fase: $faseNome | ${ordensDaFase.length} ordens");

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  faseNome,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
              ...ordensDaFase.map((ordem) {
                debugPrint("   → Renderizando ordem: ${ordem.titulo} | Serviços: ${ordem.servicosIds.length} | Responsáveis: ${ordem.responsaveisIds.length}");
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      ordem.status == 'concluida' ? Icons.check_circle : Icons.assignment,
                      color: ordem.status == 'concluida' ? Colors.green : Colors.orange,
                    ),
                    title: Text(ordem.titulo ?? 'Sem título'),
                    subtitle: Text(
                      "${ordem.servicosIds.length} serviço(s) • ${ordem.responsaveisIds.length} responsável(is)",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(ordem.status.toUpperCase()),
                          backgroundColor: _getStatusColor(ordem.status),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.teal),
                          tooltip: "Atender Ordem",
                          onPressed: () => _abrirAtendimento(ordem),
                        ),
                      ],
                    ),
                    onTap: () => _abrirAtendimento(ordem),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrdemServicoFormScreen(obraId: widget.obraId),
            ),
          );
          if (result == true) {
            context.read<OrdemServicoProvider>().carregarOrdensDaObra(widget.obraId);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrirAtendimento(OrdemServico ordem) {
    debugPrint("👁️ Abrindo atendimento da ordem: ${ordem.titulo} (ID: ${ordem.id})");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemServicoAtendimentoScreen(ordem: ordem),
      ),
    ).then((result) {
      if (result == true) {
        context.read<OrdemServicoProvider>().carregarOrdensDaObra(widget.obraId);
      }
    });
  }

  Future<void> _gerarOrdensAutomaticas(BuildContext context) async {
    final provider = context.read<OrdemServicoProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gerar Ordens Automáticas"),
        content: const Text(
          "Deseja gerar ordens de serviço automaticamente para as fases que exigem?\n\n"
              "Só serão criadas para fases que ainda não possuem ordem.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Gerar"),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gerando ordens automáticas...")),
    );

    await provider.criarOrdensAutomaticasParaObra(widget.obraId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ordens geradas com sucesso!")),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'concluida':
        return Colors.green[100]!;
      case 'em_andamento':
        return Colors.blue[100]!;
      default:
        return Colors.orange[100]!;
    }
  }
}