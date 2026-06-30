// lib/features/pop/screens/categorias_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pop_provider.dart';

class CategoriasManagerScreen extends StatefulWidget {
  const CategoriasManagerScreen({super.key});

  @override
  State<CategoriasManagerScreen> createState() => _CategoriasManagerScreenState();
}

class _CategoriasManagerScreenState extends State<CategoriasManagerScreen> {
  final _novaCategoriaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PopProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Categorias'),
      ),
      body: Column(
        children: [
          // Adicionar nova categoria
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _novaCategoriaController,
                    decoration: const InputDecoration(
                      labelText: "Nova Categoria",
                      border: OutlineInputBorder(),
                      hintText: "Ex: Logística",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_novaCategoriaController.text.trim().isNotEmpty) {
                      provider.adicionarCategoria(_novaCategoriaController.text.trim());
                      _novaCategoriaController.clear();
                    }
                  },
                  child: const Text("Adicionar"),
                ),
              ],
            ),
          ),

          const Divider(),

          // Lista de categorias
          Expanded(
            child: ListView.builder(
              itemCount: provider.categorias.length,
              itemBuilder: (context, index) {
                final categoria = provider.categorias[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(categoria, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Excluir Categoria"),
                            content: Text("Deseja realmente excluir '$categoria'?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.removerCategoria(categoria);
                                  Navigator.pop(context);
                                },
                                child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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