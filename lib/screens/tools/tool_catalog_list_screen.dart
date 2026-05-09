// lib/checklist/tools/tool_catalog_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/tool_catalog.dart';
import '../../providers/tool_catalog_provider.dart';
import 'tool_catalog_form_screen.dart';

class ToolCatalogListScreen extends StatelessWidget {
  const ToolCatalogListScreen({super.key});

  void _showDetails(BuildContext context, ToolCatalog tool) {
    final realFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorTotal = (tool.valorUnitario ?? 0) * tool.quantidadeTotal;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.build_circle, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tool.nome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tool.photoPath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      tool.photoPath!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Quantidade total: ${tool.quantidadeTotal}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Marca: ${tool.marca ?? 'Não informada'}'),
              Text('Modelo: ${tool.modelo ?? 'Não informado'}'),
              Text('Categoria: ${tool.categoria}'),
              const SizedBox(height: 8),
              Text('Valor unitário: ${tool.valorUnitario != null ? realFormat.format(tool.valorUnitario) : 'Não informado'}'),
              Text('Valor total: ${realFormat.format(valorTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 16),
              const Text('Distribuição atual:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Em desenvolvimento...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final realFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Ferramentas'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ToolCatalogFormScreen()),
        ),
      ),
      body: Builder(
        builder: (context) {
          final provider = Provider.of<ToolCatalogProvider>(context, listen: true);

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.catalog.isEmpty) {
            return const Center(
              child: Text('Nenhuma ferramenta no catálogo', style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.catalog.length,
            itemBuilder: (context, index) {
              final tool = provider.catalog[index];
              final valorTotal = (tool.valorUnitario ?? 0) * tool.quantidadeTotal;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => _showDetails(context, tool),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: tool.photoPath != null
                        ? Image.network(
                      tool.photoPath!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 30),
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.build, color: Colors.grey, size: 30),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tool.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Qtd: ${tool.quantidadeTotal}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${tool.marca ?? ''} ${tool.modelo ?? ''}'.trim().isEmpty
                        ? 'Sem marca/modelo • ${tool.valorUnitario != null ? realFormat.format(tool.valorUnitario) : 'Sem valor'}'
                        : '${tool.marca ?? ''} ${tool.modelo ?? ''} • ${tool.valorUnitario != null ? realFormat.format(tool.valorUnitario) : 'Sem valor'}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ToolCatalogFormScreen(tool: tool)),
                    ),
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