// lib/features/client/screens/clientes_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../obra/screens/obras_por_cliente_screen.dart';
import '../models/cliente.dart';
import '../providers/cliente_provider.dart';
import '../../filial/providers/filial_provider.dart';
import '../../obra/providers/obra_provider.dart';
import 'cliente_form_screen.dart';
import 'cliente_detail_screen.dart';

class ClientesListScreen extends StatefulWidget {
  const ClientesListScreen({super.key});

  @override
  State<ClientesListScreen> createState() => _ClientesListScreenState();
}

class _ClientesListScreenState extends State<ClientesListScreen> {
  String _searchQuery = '';
  String? _filialFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().carregarClientes();
      context.read<FilialProvider>().carregarFiliais();
      context.read<ObraProvider>().loadObras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clienteProvider = context.watch<ClienteProvider>();
    final filialProvider = context.watch<FilialProvider>();
    final obraProvider = context.watch<ObraProvider>();

    final filtered = clienteProvider.clientes.where((cliente) {
      final matchesSearch = _searchQuery.isEmpty ||
          cliente.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (cliente.cpfCnpj?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesFilial = _filialFiltro == null || cliente.filiaisIds.contains(_filialFiltro);

      return matchesSearch && matchesFilial;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar cliente...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: InputDecoration(
                      labelText: "Filial",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    value: _filialFiltro,
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todas")),
                      ...filialProvider.filiais.map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.nome ?? 'Sem nome'),
                      )),
                    ],
                    onChanged: (value) => setState(() => _filialFiltro = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Nenhum cliente encontrado", style: TextStyle(fontSize: 16)))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final cliente = filtered[index];
                final totalObras = clienteProvider.getTotalObras?.call(cliente.id, obraProvider.obras) ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.teal[100],
                      child: const Icon(Icons.person, color: Colors.teal, size: 32),
                    ),
                    title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(cliente.cpfCnpj ?? 'Sem CPF/CNPJ'),
                    trailing: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ObrasPorClienteScreen(cliente: cliente),
                          ),
                        );
                      },
                      child: Chip(
                        label: Text("$totalObras obras"),
                        backgroundColor: Colors.orange[100],
                        labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClienteDetailScreen(cliente: cliente),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Novo Cliente"),
      ),
    );
  }
}