// lib/checklist/brands/brand_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/brand_provider.dart';
import '../models/brand.dart';

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({Key? key}) : super(key: key);

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  @override
  void initState() {
    super.initState();
    // Não precisa fetch — o provider carrega automático com Supabase stream
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar marca',
            onPressed: () => Navigator.pushNamed(context, '/add_brand'),
          ),
        ],
      ),
      body: Consumer<BrandProvider>(
        builder: (context, brandProvider, _) {
          if (brandProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (brandProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${brandProvider.errorMessage}'),
                  ElevatedButton(
                    onPressed: brandProvider.clearError,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (brandProvider.brands.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma marca cadastrada',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: brandProvider.brands.length,
            itemBuilder: (context, index) {
              final brand = brandProvider.brands[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(
                    brand.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        tooltip: 'Editar',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/add_brand',
                            arguments: brand,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Excluir',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Excluir Marca'),
                              content: Text('Tem certeza que deseja excluir a marca "${brand.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            try {
                              await brandProvider.deleteBrand(brand.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marca excluída com sucesso'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao excluir: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}