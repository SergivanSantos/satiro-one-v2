// lib/features/material/screens/modelo_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/marca.dart';
import '../providers/material_provider.dart';
import '../models/modelo.dart';
import 'modelo_form_screen.dart';

class ModeloListScreen extends StatefulWidget {
  const ModeloListScreen({super.key});

  @override
  State<ModeloListScreen> createState() => _ModeloListScreenState();
}

class _ModeloListScreenState extends State<ModeloListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarTudo(); // Carrega marcas + modelos
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaterialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modelos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ModeloFormScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: provider.modelos.length,
        itemBuilder: (context, index) {
          final modelo = provider.modelos[index];

          // Busca o nome da marca
          final marca = provider.marcas.firstWhere(
                (m) => m.id == modelo.marcaId,
            orElse: () => Marca(id: '', nome: 'Marca não encontrada'),
          );

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.model_training, color: Colors.deepOrange),
              title: Text(modelo.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Marca: ${marca.nome}"),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ModeloFormScreen(modelo: modelo)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}