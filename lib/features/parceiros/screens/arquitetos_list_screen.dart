// lib/features/parceiros/screens/arquitetos_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/arquiteto.dart';
import '../providers/parceiros_provider.dart';
import '../../obra/providers/obra_provider.dart';
import '../../obra/models/obra.dart';
import 'arquiteto_form_screen.dart';

class ArquitetosListScreen extends StatefulWidget {
  const ArquitetosListScreen({super.key});

  @override
  State<ArquitetosListScreen> createState() => _ArquitetosListScreenState();
}

class _ArquitetosListScreenState extends State<ArquitetosListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParceirosProvider>().carregarArquitetos();
      context.read<ObraProvider>().loadObras(); // ← Atualizado
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParceirosProvider>();
    final obraProvider = context.watch<ObraProvider>();

    final filtered = provider.arquitetos.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (a.cidade?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    final totalArquitetos = provider.arquitetos.length;
    final totalObras = provider.arquitetos.fold<int>(0, (sum, a) =>
    sum + provider.getTotalObrasArquiteto(a.id, obraProvider.obras));

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 300,
                  height: 38,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar arquiteto...",
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      isDense: true,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 8),
                _buildTinyStat("Arquitetos", totalArquitetos, Icons.people),
                const SizedBox(width: 8),
                _buildTinyStat("Obras", totalObras, Icons.home_work),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Nenhum arquiteto encontrado"))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final arq = filtered[index];
                final total = provider.getTotalObrasArquiteto(arq.id, obraProvider.obras);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.teal[100],
                      child: const Icon(Icons.person, size: 24, color: Colors.teal),
                    ),
                    title: Text(arq.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    subtitle: Text(
                      arq.telefone ?? arq.email ?? arq.cidade ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$total obras",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                          onPressed: () => _editar(context, arq),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _confirmarExclusao(context, arq),
                        ),
                      ],
                    ),
                    onTap: () => _showArquitetoDetail(context, arq),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArquitetoFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTinyStat(String title, int count, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.teal),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(count.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ==================== DETALHES DO ARQUITETO ====================
  void _showArquitetoDetail(BuildContext context, Arquiteto arq) {
    final obraProvider = context.read<ObraProvider>();
    final provider = context.read<ParceirosProvider>();

    final obrasDoArquiteto = obraProvider.obras
        .where((obra) => obra.arquitetoId == arq.id)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.teal[100],
                      child: const Icon(Icons.person, size: 36, color: Colors.teal),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        arq.nome,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Row(
                  children: [
                    _statCard("Total", obrasDoArquiteto.length, Colors.blue),
                    const SizedBox(width: 8),
                    _statCard("Andamento", obrasDoArquiteto.where((o) => o.status.toUpperCase().contains('ANDAMENTO')).length, Colors.orange),
                    const SizedBox(width: 8),
                    _statCard("Concluídas", obrasDoArquiteto.where((o) => o.status.toUpperCase().contains('CONCLU') || o.status.toUpperCase().contains('FINALIZ')).length, Colors.green),
                  ],
                ),

                const SizedBox(height: 24),

                const Text("Obras Associadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                Expanded(
                  child: obrasDoArquiteto.isEmpty
                      ? const Center(child: Text("Nenhuma obra encontrada para este arquiteto"))
                      : ListView.builder(
                    controller: scrollController,
                    itemCount: obrasDoArquiteto.length,
                    itemBuilder: (context, index) {
                      final obra = obrasDoArquiteto[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.home_work, color: Colors.teal),
                          title: Text(obra.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text("Cliente: ${obraProvider.getClienteNome(obra.clienteId)}"),
                          trailing: Chip(
                            label: Text(obra.status.toUpperCase()),
                            backgroundColor: obra.status.toUpperCase().contains('ANDAMENTO')
                                ? Colors.orange[100]
                                : Colors.green[100],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, int value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color[700])),
            Text(label, style: TextStyle(fontSize: 12.5, color: color[600])),
          ],
        ),
      ),
    );
  }

  void _editar(BuildContext context, Arquiteto arq) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ArquitetoFormScreen(arquiteto: arq)));
  }

  void _confirmarExclusao(BuildContext context, Arquiteto arq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Arquiteto"),
        content: Text("Deseja excluir ${arq.nome}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              context.read<ParceirosProvider>().removerArquiteto(arq.id);
              Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}