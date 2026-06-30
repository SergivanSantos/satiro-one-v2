// lib/features/parceiros/screens/construtoras_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/construtora.dart';
import '../providers/parceiros_provider.dart';
import '../../obra/providers/obra_provider.dart';
import '../../obra/models/obra.dart';
import 'construtora_form_screen.dart';

class ConstrutorasListScreen extends StatefulWidget {
  const ConstrutorasListScreen({super.key});

  @override
  State<ConstrutorasListScreen> createState() => _ConstrutorasListScreenState();
}

class _ConstrutorasListScreenState extends State<ConstrutorasListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParceirosProvider>().carregarConstrutoras();
      context.read<ObraProvider>().loadObras();        // ← Corrigido
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParceirosProvider>();
    final obraProvider = context.watch<ObraProvider>();

    final filtered = provider.construtoras.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.cidade?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    final totalConstrutoras = provider.construtoras.length;
    final totalObras = provider.construtoras.fold<int>(0, (sum, c) =>
    sum + provider.getTotalObrasConstrutora(c.id, obraProvider.obras));

    return Scaffold(
      body: Column(
        children: [
          // Topo compacto
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 300,
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar construtora...",
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
                _buildTinyStat("Construtoras", totalConstrutoras, Icons.business),
                const SizedBox(width: 8),
                _buildTinyStat("Obras", totalObras, Icons.home_work),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Nenhuma construtora encontrada"))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final cons = filtered[index];
                final total = provider.getTotalObrasConstrutora(cons.id, obraProvider.obras);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.teal[100],
                      child: const Icon(Icons.business, size: 22, color: Colors.teal),
                    ),
                    title: Text(cons.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
                    subtitle: Text(
                      cons.cidade ?? cons.email ?? cons.cnpj ?? '',
                      style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$total obras",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 19, color: Colors.blueGrey),
                          onPressed: () => _editar(context, cons),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 19, color: Colors.red),
                          onPressed: () => _confirmarExclusao(context, cons),
                        ),
                      ],
                    ),
                    onTap: () => _showConstrutoraDetail(context, cons),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConstrutoraFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTinyStat(String title, int count, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: Colors.teal),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(fontSize: 11.5)),
            const SizedBox(width: 5),
            Text(count.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ==================== POPUP COM LISTA DE OBRAS ====================
  void _showConstrutoraDetail(BuildContext context, Construtora cons) {
    final obraProvider = context.read<ObraProvider>();

    final obrasDaConstrutora = obraProvider.obras
        .where((obra) => obra.construtoraId == cons.id)
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal[100],
                      child: const Icon(Icons.business, size: 34, color: Colors.teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        cons.nome,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Estatísticas
                Row(
                  children: [
                    _statCard("Total", obrasDaConstrutora.length, Colors.blue),
                    const SizedBox(width: 8),
                    _statCard("Andamento", obrasDaConstrutora.where((o) => o.status.toUpperCase().contains('ANDAMENTO')).length, Colors.orange),
                    const SizedBox(width: 8),
                    _statCard("Concluídas", obrasDaConstrutora.where((o) =>
                    o.status.toUpperCase().contains('CONCLU') ||
                        o.status.toUpperCase().contains('FINALIZ')).length, Colors.green),
                  ],
                ),

                const SizedBox(height: 20),

                // Lista de Obras
                const Text("Obras Associadas", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Expanded(
                  child: obrasDaConstrutora.isEmpty
                      ? const Center(child: Text("Nenhuma obra encontrada para esta construtora"))
                      : ListView.builder(
                    controller: scrollController,
                    itemCount: obrasDaConstrutora.length,
                    itemBuilder: (context, index) {
                      final obra = obrasDaConstrutora[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.home_work, color: Colors.teal, size: 26),
                          title: Text(obra.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text("Cliente: ${obraProvider.getClienteNome(obra.clienteId)}"),
                          trailing: Chip(
                            label: Text(obra.status.toUpperCase(), style: const TextStyle(fontSize: 12)),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color[700])),
            Text(label, style: TextStyle(fontSize: 12, color: color[600])),
          ],
        ),
      ),
    );
  }

  void _editar(BuildContext context, Construtora construtora) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConstrutoraFormScreen(construtora: construtora)));
  }

  void _confirmarExclusao(BuildContext context, Construtora construtora) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Construtora"),
        content: Text("Deseja excluir ${construtora.nome}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              context.read<ParceirosProvider>().removerConstrutora(construtora.id);
              Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}