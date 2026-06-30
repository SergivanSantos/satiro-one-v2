// lib/features/pop/screens/pops_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pop_provider.dart';
import 'pops_list_screen.dart';

class PopsDashboardScreen extends StatefulWidget {
  const PopsDashboardScreen({super.key});

  @override
  State<PopsDashboardScreen> createState() => _PopsDashboardScreenState();
}

class _PopsDashboardScreenState extends State<PopsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PopProvider>().carregarPops();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PopProvider>();

    final totalPops = provider.pops.length;
    final activePops = provider.pops.where((p) => p.ativo).length;

    // Contagem por categoria_pop
    final Map<String, int> porCategoria = {};
    for (var pop in provider.pops) {
      final cat = pop.categoriaPop;   // ← Alterado
      porCategoria[cat] = (porCategoria[cat] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard de POPs")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de Resumo Geral
            Row(
              children: [
                _buildStatCard("Total de POPs", totalPops, Icons.article, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard("Ativos", activePops, Icons.check_circle, Colors.green),
              ],
            ),
            const SizedBox(height: 28),

            const Text("POPs por Categoria", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Cards clicáveis por categoria
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: porCategoria.entries.map((entry) {
                return _buildCategoryCard(
                  categoria: entry.key,
                  quantidade: entry.value,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PopsListScreen(initialCategoryFilter: entry.key),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            const Text("Últimos POPs Cadastrados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...provider.pops.take(6).map((pop) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(pop.titulo),
                subtitle: Text("${pop.codigo ?? '—'} • ${pop.categoriaPop}"),   // ← Alterado
                trailing: Text(pop.versao, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color[700]),
            const SizedBox(height: 12),
            Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color[700])),
            Text(title, style: TextStyle(fontSize: 14, color: color[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String categoria,
    required int quantidade,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(categoria, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 10),
            Text(
              quantidade.toString(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Text("POPs", style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}