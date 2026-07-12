// lib/features/material/screens/marca_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/material_provider.dart';
import '../models/marca.dart';
import 'marca_form_screen.dart';

class MarcaListScreen extends StatefulWidget {
  const MarcaListScreen({super.key});

  @override
  State<MarcaListScreen> createState() => _MarcaListScreenState();
}

class _MarcaListScreenState extends State<MarcaListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarMarcas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaterialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Marcas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarcaFormScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: provider.marcas.length,
        itemBuilder: (context, index) {
          final marca = provider.marcas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.branding_watermark, color: Colors.deepPurple),
              title: Text(marca.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MarcaFormScreen(marca: marca)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}