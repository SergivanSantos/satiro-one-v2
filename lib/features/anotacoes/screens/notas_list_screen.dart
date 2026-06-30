// lib/features/anotacoes/screens/notas_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/nota.dart';
import '../providers/notas_provider.dart';
import '../screens/nota_form_screen.dart';

class NotasListScreen extends StatefulWidget {
  const NotasListScreen({super.key});

  @override
  State<NotasListScreen> createState() => _NotasListScreenState();
}

class _NotasListScreenState extends State<NotasListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<NotasProvider>().carregarNotas();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();

    final filtered = provider.notas.where((nota) {
      if (_searchQuery.isEmpty) return true;
      return nota.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          nota.conteudo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Notas"),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar notas...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
              child: Text(
                "Nenhuma nota encontrada\nToque no + para criar",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final nota = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      nota.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nota.conteudo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(nota.updatedAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotaFormScreen(nota: nota)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotaFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}