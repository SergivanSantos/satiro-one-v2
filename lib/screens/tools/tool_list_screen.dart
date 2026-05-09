// lib/checklist/tools/tool_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool.dart';
import '../../providers/tool_provider.dart';
import 'tool_form_screen.dart';

class ToolListScreen extends StatelessWidget {
  const ToolListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferramentas'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ToolFormScreen(tool: null)),
          );
        },
      ),
      body: Consumer<ToolProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.tools.isEmpty) {
            return const Center(child: Text('Nenhuma ferramenta cadastrada'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tools.length,
            itemBuilder: (context, index) {
              final tool = provider.tools[index];
              final isPessoal = tool.tipo == 'pessoal';
              final statusColor = tool.estado == 'novo' ? Colors.green : tool.estado == 'danificado' ? Colors.orange : Colors.red;

              return Card(
                child: ListTile(
                  leading: Icon(isPessoal ? Icons.person : Icons.business_center, color: Colors.teal),
                  title: Text(tool.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${tool.marca ?? ''} ${tool.modelo ?? ''}'.trim()),
                      Text('Categoria: ${tool.categoria}'),
                      Row(
                        children: [
                          Text('Estado: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(tool.estado, style: TextStyle(color: statusColor)),
                          const SizedBox(width: 16),
                          if (isPessoal && tool.idTecnico != null)
                            const Text('Pessoal', style: TextStyle(color: Colors.blue)),
                          if (!isPessoal && tool.idTecnico != null)
                            const Text('Em uso', style: TextStyle(color: Colors.orange)),
                          if (!isPessoal && tool.idTecnico == null)
                            const Text('Disponível', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ToolFormScreen(tool: tool)),
                      );
                    },
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