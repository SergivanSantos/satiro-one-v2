import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({Key? key}) : super(key: key);

  @override
  SupplierListScreenState createState() => SupplierListScreenState();
}

class SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add_supplier'),
            tooltip: 'Adicionar Fornecedor',
          ),
        ],
      ),
      body: supplierProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : supplierProvider.errorMessage != null
          ? Center(child: Text('Erro: ${supplierProvider.errorMessage}'))
          : supplierProvider.suppliers.isEmpty
          ? const Center(child: Text('Nenhum fornecedor encontrado'))
          : ListView.builder(
        itemCount: supplierProvider.suppliers.length,
        itemBuilder: (context, index) {
          final supplier = supplierProvider.suppliers[index];
          return Card(
            child: ListTile(
              title: Text(supplier.name),
              subtitle: Text('CNPJ: ${supplier.cnpj ?? 'Não informado'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/add_supplier',
                        arguments: supplier,
                      );
                    },
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Excluir Fornecedor'),
                          content: Text('Tem certeza que deseja excluir o fornecedor ${supplier.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        try {
                          await supplierProvider.deleteSupplier(supplier.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fornecedor excluído')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao excluir fornecedor: $e')),
                            );
                          }
                        }
                      }
                    },
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}