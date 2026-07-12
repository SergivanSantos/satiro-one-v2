// lib/features/material/screens/material_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/material_provider.dart';
import '../models/material.dart';
import 'material_form_screen.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final provider = context.read<MaterialProvider>();
    await provider.carregarTudo();
  }

  List<MaterialItem> get _materiaisFiltrados {
    final provider = context.read<MaterialProvider>();
    if (_searchTerm.isEmpty) return provider.materiais;

    final term = _searchTerm.toLowerCase();
    return provider.materiais.where((material) {
      final marca = provider.marcas.firstWhere((m) => m.id == material.marcaId, orElse: () => null as dynamic);
      final modelo = provider.modelos.firstWhere((m) => m.id == material.modeloId, orElse: () => null as dynamic);

      return (material.nome.toLowerCase().contains(term)) ||
          (material.codigo?.toLowerCase().contains(term) ?? false) ||
          (marca?.nome.toLowerCase().contains(term) ?? false) ||
          (modelo?.nome.toLowerCase().contains(term) ?? false);
    }).toList();
  }

  String _getFasesNomes(MaterialItem material, MaterialProvider provider) {
    if (material.fasesUsoIds.isEmpty) return "Sem fases definidas";

    final nomes = material.fasesUsoIds.map((id) {
      final fase = provider.todasFases.firstWhere((f) => f.id == id, orElse: () => null as dynamic);
      return fase?.nome ?? "Fase desconhecida";
    }).join(", ");

    return nomes.length > 65 ? "${nomes.substring(0, 62)}..." : nomes;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaterialProvider>();
    final materiais = _materiaisFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Materiais - Catálogo Global"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarDados),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Pesquisar por nome, código, marca ou modelo...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchTerm = '');
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : materiais.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhum material encontrado."),
                ],
              ),
            )
                : ListView.builder(
              itemCount: materiais.length,
              itemBuilder: (context, index) {
                final material = materiais[index];

                final marca = provider.marcas.firstWhere((m) => m.id == material.marcaId, orElse: () => null as dynamic);
                final modelo = provider.modelos.firstWhere((m) => m.id == material.modeloId, orElse: () => null as dynamic);

                final marcaNome = marca?.nome ?? 'Sem marca';
                final modeloNome = modelo?.nome ?? 'Sem modelo';
                final fasesTexto = _getFasesNomes(material, provider);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.inventory, color: Colors.teal),
                    title: Row(
                      children: [
                        if (material.codigo != null && material.codigo!.isNotEmpty)
                          Text("${material.codigo} ", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                        Expanded(
                          child: Text(material.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$marcaNome - $modeloNome"),
                        Text(fasesTexto, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (material.observacoes != null && material.observacoes!.isNotEmpty)
                          Tooltip(  // ← Abre próximo ao ícone
                            message: material.observacoes!,
                            preferBelow: false,
                            child: IconButton(
                              icon: const Icon(Icons.message, color: Colors.blueAccent, size: 22),
                              onPressed: () {}, // Tooltip já mostra ao passar o mouse
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MaterialFormScreen(material: material)),
                            );
                            if (resultado == true) await _carregarDados();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaterialFormScreen()),
          );
          if (resultado == true) await _carregarDados();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}