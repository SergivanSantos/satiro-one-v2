// lib/checklist/suppliers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  void _deleteSupplier(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Fornecedor'),
        content: const Text('Tem certeza que deseja excluir este fornecedor?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<SupplierProvider>(context, listen: false).deleteSupplier(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fornecedor excluído com sucesso!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final suppliers = supplierProvider.suppliers;

    final filteredSuppliers = suppliers.where((s) {
      return s.name.toLowerCase().contains(_searchQuery) ||
          (s.cnpj?.contains(_searchQuery) ?? false) ||
          (s.city.toLowerCase().contains(_searchQuery)) ||
          (s.phone.contains(_searchQuery));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () => Navigator.pushNamed(context, '/add_supplier'),
            tooltip: 'Novo Fornecedor',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, CNPJ, cidade ou telefone...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Lista
          Expanded(
            child: supplierProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : filteredSuppliers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    suppliers.isEmpty ? 'Nenhum fornecedor cadastrado' : 'Nenhum fornecedor encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  if (suppliers.isEmpty)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/add_supplier'),
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar Primeiro Fornecedor'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                    ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredSuppliers.length,
              itemBuilder: (ctx, i) {
                final supplier = filteredSuppliers[i];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'F',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ),
                    title: Text(
                      supplier.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (supplier.cnpj?.isNotEmpty == true)
                          Text('CNPJ: ${supplier.cnpj}', style: const TextStyle(fontSize: 13)),
                        if (supplier.phone.isNotEmpty)
                          Text('Telefone: ${supplier.phone}', style: const TextStyle(fontSize: 13)),
                        if (supplier.email.isNotEmpty)
                          Text('E-mail: ${supplier.email}', style: const TextStyle(fontSize: 13)),
                        Text(
                          '${supplier.city.isNotEmpty ? supplier.city : 'Cidade não informada'}${supplier.state.isNotEmpty ? '/${supplier.state}' : ''}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.pushNamed(
                            context,
                            '/add_supplier',
                            arguments: supplier,
                          );
                        } else if (value == 'delete') {
                          _deleteSupplier(supplier.id!);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.teal), SizedBox(width: 8), Text('Editar')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: Colors.red))])),
                      ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}