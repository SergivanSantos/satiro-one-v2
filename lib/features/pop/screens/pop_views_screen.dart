// lib/features/pop/screens/pop_views_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/pop_provider.dart';
import '../models/pop.dart';

class PopViewsScreen extends StatefulWidget {
  const PopViewsScreen({super.key});

  @override
  State<PopViewsScreen> createState() => _PopViewsScreenState();
}

class _PopViewsScreenState extends State<PopViewsScreen> {
  String _searchQuery = '';
  String? _filtroCategoria;

  @override
  void initState() {
    super.initState();
    context.read<PopProvider>().carregarPops();
  }

  @override
  Widget build(BuildContext context) {
    final popProvider = context.watch<PopProvider>();

    // Simulando visualizações (futuramente virá do banco)
    // Por enquanto vamos mostrar os POPs ordenados por relevância

    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Visualizações"),
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar por POP...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: popProvider.pops.isEmpty
                ? const Center(child: Text("Nenhum POP cadastrado ainda"))
                : ListView.builder(
              itemCount: popProvider.pops.length,
              itemBuilder: (context, index) {
                final pop = popProvider.pops[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    leading: const Icon(Icons.remove_red_eye, color: Colors.blue),
                    title: Text(pop.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("${pop.codigo} • ${pop.categoriaPop}"),
                    children: [
                      FutureBuilder<int>(
                        future: popProvider.getVisualizacoes(pop.id),
                        builder: (context, snapshot) {
                          final views = snapshot.data ?? 0;
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Total de Visualizações:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      "$views vezes",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (views == 0)
                                  const Text("Ainda não foi visualizado", style: TextStyle(color: Colors.grey)),
                                // Futuramente aqui virá a lista de quem visualizou e quando
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}